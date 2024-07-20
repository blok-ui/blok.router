package blok.router;

import haxe.macro.Context;
import haxe.macro.Expr;
import kit.macro.*;

using blok.router.RouteTools;
using kit.Hash;
using kit.macro.Tools;

function buildGeneric() {
	return switch Context.getLocalType() {
		case TInst(_, [TInst(_.get() => {kind: KExpr(macro $v{(url : String)})}, _)]):
			buildRoute(url.normalizeUrl());
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
			var url = kit.macro.Tools.extractString(path);
			var route = switch blok.router.RouteBuilder.buildRoute(url) {
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

function buildRoute(url:String) {
	var suffix = url.hash();
	var pos = Context.getLocalClass().get().pos;
	var pack = ['blok', 'router'];
	var name = 'Route_${suffix}';
	var path:TypePath = {pack: pack, name: name, params: []};

	if (path.typePathExists()) return TPath(path);

	var fields = new ClassFieldCollection([]);
	var route = url.processRoute();
	var routeParamsType = route.paramsType;
	var renderType = macro :(params:$routeParamsType) -> blok.ui.Child;

	fields.add(macro class {
		static final matcher = ${route.matcher};

		public static function createUrl(props:$routeParamsType):String {
			return ${route.urlBuilder};
		}

		public static function link(props:$routeParamsType) {
			return blok.router.Link.to(createUrl(props));
		}

		var render:kit.Maybe<$renderType>;

		public function new(?render) {
			this.render = render == null ? None : Some(render);
		}

		public function renders(render:$renderType) {
			this.render = Some(render);
			return this;
		}

		public function match(url:String):kit.Maybe<() -> blok.ui.Child> {
			if (matcher.match(url)) {
				return Some(() -> render
					.map(render -> render(${route.paramsBuilder}))
					.or(() -> blok.ui.Placeholder.node())
				);
			}
			return None;
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
