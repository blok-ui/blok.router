package blok.router;

import haxe.macro.Context;
import haxe.macro.Expr;
import kit.macro.*;

using blok.router.path.PathFactory;
using kit.Hash;
using kit.macro.Tools;

function buildGeneric() {
	return switch Context.getLocalType() {
		case TInst(_, [TInst(_.get() => {kind: KExpr(expr)}, _)]):
			buildRoute(expr);
		case TInst(_, []) | TInst(_, [TMono(_)]):
			buildBaseRoute();
		default:
			throw 'assert';
	}
}

function buildBaseRoute() {
	var pack = ['blok', 'router'];
	var name = 'Route_Base';
	var pos = Context.getLocalClass().get().pos;
	var path:TypePath = {pack: pack, name: name, params: []};

	if (path.typePathExists()) return TPath(path);

	var fields = new ClassFieldCollection([]);

	fields.add(macro class {
		@:fromMarkup
		@:noUsing
		@:noCompletion
		public macro static function fromMarkup(props, render) {
			return blok.router.RouteBuilder.buildFromMarkup(props, render, props.pos);
		}

		public macro static function to(path) {
			var route = switch blok.router.RouteBuilder.buildRoute(path) {
				case TPath(path):
					return macro new $path();
				default:
					throw 'assert';
			}
		}

		public function dispose() {}
	});

	Context.defineType({
		pack: pack,
		name: name,
		pos: pos,
		meta: [],
		kind: TDClass(null, [], false, true, false),
		fields: fields.export()
	});

	return TPath(path);
}

function buildRoute(expr:Expr) {
	var suffix = expr.extractString().hash();
	var pos = Context.getLocalClass().get().pos;
	var pack = ['blok', 'router'];
	var name = 'Route_${suffix}';
	var path:TypePath = {pack: pack, name: name, params: []};

	if (path.typePathExists()) return TPath(path);

	var fields = new ClassFieldCollection([]);
	var factory = expr.buildPath();
	var routeParamsType = factory.params;
	var renderType = macro :(params:$routeParamsType) -> blok.Child;

	switch routeParamsType {
		case TAnonymous(params) if (params.length == 0):
			fields.add(macro class {
				public static function createUrl():String {
					var props = {};
					return ${factory.pathBuilder};
				}

				public static function link() {
					return blok.router.Link.to(createUrl());
				}
			});
		default:
			fields.add(macro class {
				public static function createUrl(props:$routeParamsType):String {
					return ${factory.pathBuilder};
				}

				public static function link(props:$routeParamsType) {
					return blok.router.Link.to(createUrl(props));
				}
			});
	}

	fields.add(macro class {
		static final matcher = ${factory.pathMatcher};

		public inline static function route(render):blok.router.Matchable {
			return new $path(render);
		}

		var render:kit.Maybe<$renderType>;

		public function new(?render) {
			this.render = render == null ? None : Some(render);
		}

		public function renders(render:$renderType) {
			this.render = Some(render);
			return this;
		}

		public function match(url:String):kit.Maybe<blok.Child> {
			// @todo: This is super inefficient.
			return matcher.match(url).map(match -> {
				render
					.map(render -> (new blok.router.RouteNode(match, match -> render(match.params)) : blok.Child))
					.or(() -> blok.Placeholder.node());
			});
		}

		public function dispose() {}
	});

	Context.defineType({
		pack: pack,
		name: name,
		pos: pos,
		meta: [],
		kind: TDClass(null, [
			{
				pack: ['blok', 'router'],
				name: 'Matchable'
			}
		], false, true, false),
		fields: fields.export()
	});

	return TPath(path);
}

function buildFromMarkup(props:Expr, render:Expr, pos:Position) {
	return switch props.expr {
		case EObjectDecl([
			{field: 'to', expr: {expr: EConst(CString(s, _)), pos: _}}
		]):
			return macro @:pos(pos) blok.router.Route.to($v{s}).renders(${render});
		default:
			Context.error('Invalid properties', props.pos);
	}
}
