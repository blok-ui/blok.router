package blok.router;

import blok.ComponentBuilder;
import haxe.macro.Context;
import haxe.macro.Expr;
import kit.macro.*;

using Lambda;
using blok.macro.Tools;
using blok.router.RouteTools;
using haxe.macro.Tools;
using kit.Hash;
using kit.macro.Tools;

function buildGeneric() {
	return switch Context.getLocalType() {
		case TInst(_, [TInst(_.get() => {kind: KExpr(macro $v{(url : String)})}, _)]):
			buildPage(url.normalizeUrl());
		default:
			throw 'assert';
	}
}

function buildPage(url:String) {
	var suffix = url.hash();
	var pos = Context.getLocalClass().get().pos;
	var pack = ['blok', 'router'];
	var name = 'Page_${suffix}';
	var path:TypePath = {pack: pack, name: name, params: []};

	if (path.typePathExists()) return TPath(path);

	var fields = new ClassFieldCollection([]);

	Context.defineType({
		pack: pack,
		name: name,
		pos: pos,
		meta: [
			{
				name: ':autoBuild',
				params: [macro blok.router.PageBuilder.build($v{url})],
				pos: (macro null).pos
			}
		],
		kind: TDClass({
			pack: ['blok'],
			name: 'ProxyView'
		}, [], false, false, true),
		fields: []
	});

	return TPath(path);
}

function build(url:String) {
	return ClassBuilder.fromContext()
		.addBundle(new ComponentBuilder({
			createFromMarkupMethod: false
		}))
		.addStep(new PageBuilder(url))
		.addStep(new RouteConstructorBuildStep(url))
		.export();
}

final RouterProps = 'router.prop';

class PageBuilder implements BuildStep {
	public final priority:Priority = Normal;

	final url:String;
	final route:RouteMeta;

	public function new(url) {
		this.url = url;
		this.route = url.processRoute();
	}

	public function apply(builder:ClassBuilder) {
		switch route.paramsType {
			case TAnonymous(fields):
				for (field in fields) {
					var name = field.name;
					var ct = switch field.kind {
						case FVar(t, _): t;
						default: throw 'assert';
					}

					builder.add(macro class {
						final $name:blok.signal.Signal<$ct>;
					});
					builder.hook(RouterProps)
						.addProp({
							name: name,
							type: ct,
							optional: false
						});
					builder.hook(Init)
						.addProp({
							name: name,
							type: ct,
							optional: false
						})
						.addExpr(macro this.$name = props.$name);
					builder.updateHook()
						.addExpr(macro this.$name.set(props.$name));
				}
			default:
				throw 'assert';
		}
	}
}

class RouteConstructorBuildStep implements BuildStep {
	public final priority:Priority = Late;

	final url:String;
	final route:RouteMeta;

	public function new(url) {
		this.url = url;
		this.route = url.processRoute();
	}

	public function apply(builder:ClassBuilder) {
		var routeParamsType = route.paramsType;
		var componentPath = builder.getTypePath();
		var router = builder.hook(RouterProps).getProps();
		var init = builder.hook(Init);
		var late = builder.hook(LateInit);
		var props = init.getProps()
			.concat(late.getProps())
			.filter(prop -> !router.exists(p -> p.name == prop.name));
		var propsType:ComplexType = TAnonymous(props);
		var routerTp:TypePath = {
			pack: ['blok', 'router'],
			name: 'Route',
			params: [TPExpr(macro $v{url})]
		};
		var routerType:ComplexType = TPath(routerTp);

		var obj:Array<ObjectField> = [];
		for (field in props) {
			var name = field.name;
			obj.push({
				field: name,
				expr: macro props.$name
			});
		}
		for (field in router) {
			var name = field.name;
			obj.push({
				field: name,
				expr: macro routerProps.$name
			});
		}
		var nodeProps:Expr = {
			expr: EObjectDecl(obj),
			pos: (macro null).pos
		};

		switch routeParamsType {
			case TAnonymous(params) if (params.length == 0):
				builder.add(macro class {
					public static function createUrl():String {
						var props = {};
						return ${route.urlBuilder};
					}

					public static function link() {
						return blok.router.Link.to(createUrl());
					}
				});
			default:
				builder.add(macro class {
					public static function createUrl(props:$routeParamsType):String {
						return ${route.urlBuilder};
					}

					public static function link(props:$routeParamsType) {
						return blok.router.Link.to(createUrl(props));
					}
				});
		}

		builder.add(macro class {
			@:fromMarkup
			@:noUsing
			public static function route(props:$propsType):blok.router.Matchable {
				return new $routerTp(routerProps -> {
					return $p{componentPath.pack.concat([componentPath.name, 'node'])}($nodeProps);
				});
			}
		});
	}
}
