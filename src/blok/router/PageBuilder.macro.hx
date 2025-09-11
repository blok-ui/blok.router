package blok.router;

import blok.ComponentBuilder;
import blok.macro.LifecycleBuildStep;
import blok.router.path.PathInfo;
import haxe.macro.Context;
import haxe.macro.Expr;
import kit.macro.step.ConstructorBuildStep;

using Lambda;
using blok.macro.Tools;
using haxe.macro.Tools;
using kit.Hash;
using kit.Macro;

function buildGeneric() {
	return switch Context.getLocalType() {
		case TInst(_, [TInst(_.get() => {kind: KExpr(expr)}, _)]):
			buildPage(expr);
		default:
			throw 'assert';
	}
}

function buildPage(expr:Expr) {
	var suffix = expr.extractString().hash();
	var pos = Context.getLocalClass().get().pos;
	var pack = ['blok', 'router'];
	var name = 'Page_${suffix}';
	var path:TypePathBuilder = {pack: pack, name: name, params: []};

	if (path.exists()) return TPath(path);

	var fields = new FieldCollection([]);

	Context.defineType({
		pack: pack,
		name: name,
		pos: pos,
		meta: [
			{
				name: ':autoBuild',
				params: [macro blok.router.PageBuilder.build(${expr})],
				pos: (macro null).pos
			}
		],
		kind: TDClass({
			pack: ['blok', 'router'],
			name: 'Page',
			sub: 'PageState'
		}, [], false, false, true),
		fields: []
	});

	return TPath(path);
}

function build(url:Expr) {
	return BuildFactory
		.ofSteps([
			new ComponentBuilder({
				createFromMarkupMethod: false,
				children: [
					// @todo: This nesting could be simplified by just merging
					// the functionality of the RouteConstructorBuildStep into
					// PageBuilder.
					new RouteConstructorBuildStep({
						expr: url,
						children: [
							new PageBuilder(url)
						]
					})
				]
			})
		])
		.buildFromContext();
}

class PageBuilder extends BuildStep {
	final url:String;
	final info:PathInfo;

	public function new(expr:Expr) {
		this.url = expr.extractString();
		this.info = PathInfo.ofExpr(expr);
	}

	public function steps() return [];

	public function apply(context:BuildContext) {
		var constructor = findAncestorOfType(ConstructorBuildStep).orThrow();
		var lifecycle = findAncestorOfType(LifecycleBuildStep).orThrow();
		var router = findAncestorOfType(RouteConstructorBuildStep).orThrow();

		switch info.params {
			case TAnonymous(fields):
				for (field in fields) {
					var name = field.name;
					var ct = switch field.kind {
						case FVar(t, _): t;
						default: throw 'assert';
					}

					router.init.addProp({
						name: name,
						type: ct,
						optional: false
					});
					context.fields.add(macro class {
						final $name:blok.signal.Signal<$ct>;
					});
					constructor.init
						.addProp({
							name: name,
							type: ct,
							optional: false
						})
						.addExpr(macro this.$name = props.$name);
					lifecycle.onUpdate(macro this.$name.set(props.$name));
				}
			default:
				throw 'assert';
		}
	}
}

class RouteConstructorBuildStep extends BuildStep {
	public final init:ConstructorBuildHook = new ConstructorBuildHook();

	final url:String;
	final info:PathInfo;
	final childSteps:Array<BuildStep>;

	public function new(options:{
		expr:Expr,
		?children:Array<BuildStep>
	}) {
		this.url = options.expr.extractString();
		this.childSteps = options.children ?? [];
		this.info = PathInfo.ofExpr(options.expr);
	}

	public function steps() return childSteps;

	public function apply(context:BuildContext) {
		var constructor = findAncestorOfType(ConstructorBuildStep).orThrow();
		var routeParamsType = info.params;
		var componentPath = context.type.toTypePath();
		var router = init.getProps();
		var init = constructor.init;
		var late = constructor.late;
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
				expr: macro params.$name
			});
		}
		var nodeProps:Expr = {
			expr: EObjectDecl(obj),
			pos: (macro null).pos
		};

		switch routeParamsType {
			case TAnonymous(params) if (params.length == 0):
				context.fields.add(macro class {
					public static function createUrl():String {
						var props = {};
						return ${info.pathBuilder};
					}

					public static function link() {
						return blok.router.Link.to(createUrl());
					}
				});
			default:
				context.fields.add(macro class {
					public static function createUrl(props:$routeParamsType):String {
						return ${info.pathBuilder};
					}

					public static function link(props:$routeParamsType) {
						return blok.router.Link.to(createUrl(props));
					}
				});
		}

		context.fields.add(macro class {
			@:fromMarkup
			@:noUsing
			public static function route(props:$propsType):blok.router.Matchable {
				return new $routerTp(params -> {
					return $p{componentPath.pack.concat([componentPath.name, 'node'])}($nodeProps);
				});
			}
		});
	}
}
