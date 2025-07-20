package blok.router.parse;

import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;
using kit.macro.Tools;

typedef CompilerResult = {
	public final params:ComplexType;
	public final pathBuilder:Expr;
	public final pathMatcher:Expr;
}

typedef RoutePathParam = {
	public final name:String;
	public final type:ComplexType;
	public final optional:Bool;
}

// @todo: Really rethink naming here. I don't like "Compiler".

function compilePath(source:String, ?pos:Position):CompilerResult {
	var path = Parser.of(source)
		.parse()
		.inspectError(error -> {
			var infos = (pos ?? Context.currentPos()).getInfos();
			Context.makePosition({
				min: infos.min + 1 + error.pos.min,
				max: infos.min + 1 + error.pos.max,
				file: infos.file
			}).error(error.message);
		})
		.orThrow();

	var params = getParamInfo(path.segments);
	var paramsType:ComplexType = TAnonymous(params.map(param -> ({
		name: param.name,
		kind: FVar(param.type),
		meta: if (param.optional) [
			{name: ':optional', params: [], pos: (macro null).pos}
		] else [],
		pos: (macro null).pos
	} : Field)));
	var pathBuilder = createPathBuilder(path.segments);
	var pathMatcher = createPathMatcher(path.segments, paramsType);

	return {
		pathBuilder: createPathBuilder(path.segments),
		pathMatcher: createPathMatcher(path.segments, paramsType),
		params: paramsType
	};
}

private function getParamInfo(segments:Array<RouteSegment>, ?skipOptional:Bool = false) {
	var params:Array<RoutePathParam> = [];

	function scan(segments:Array<RouteSegment>, optional:Bool) {
		for (segment in segments) switch segment {
			case DynamicSegment(key, type):
				params.push({
					name: key,
					type: switch type {
						case RouteInt: macro :Int;
						case RouteString: macro :String;
					},
					optional: optional
				});
			case OptionalSegment(segments) if (!skipOptional):
				scan(segments, true);
			default:
		}
	}

	scan(segments, false);

	return params;
}

private function createPathBuilder(segments:Array<RouteSegment>):Expr {
	var parts:Array<Expr> = [];
	for (segment in segments) switch segment {
		case StaticSegment(value):
			parts.push(macro $v{value});
		case DynamicSegment(key, _):
			parts.push(macro Std.string(props.$key));
		case SplatSegment():
			// @todo
		case OptionalSegment(segments):
			var expr = createPathBuilder(segments);
			var infos = getParamInfo(segments, true);
			var test:Null<Expr> = null;

			for (info in infos) {
				var name = info.name;
				if (test == null) {
					test = macro props.$name != null;
				} else {
					var previous = test;
					test = macro ${previous} && props.$name != null;
				}
			}

			if (test != null) {
				parts.push(macro if ($test) $expr else null);
			} else {
				parts.push(expr);
			}
	}

	return macro [$a{parts}].filter(part -> part != null).join('/');
}

private function createPathMatcher(segments:Array<RouteSegment>, paramsType:ComplexType) {
	var segmentExprs:Array<Expr> = segments.map(routeSegmentToExpr);
	return macro new blok.router.parse.RoutePath<$paramsType>([$a{segmentExprs}]);
}

private function routeSegmentToExpr(segment:RouteSegment):Expr {
	return switch segment {
		case StaticSegment(value):
			macro StaticSegment($v{value});
		case DynamicSegment(key, type):
			var typeExpr = switch type {
				case RouteInt: macro RouteInt;
				case RouteString: macro RouteString;
			}
			macro DynamicSegment($v{key}, ${typeExpr});
		case SplatSegment():
			return macro SplatSegment;
		case OptionalSegment(segments):
			return macro OptionalSegment([$a{segments.map(routeSegmentToExpr)}]);
	}
}
