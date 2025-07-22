package blok.router.path;

import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;
using kit.macro.Tools;

typedef PathFactory = {
	public final params:ComplexType;
	public final pathBuilder:Expr;
	public final pathMatcher:Expr;
}

typedef PathParam = {
	public final name:String;
	public final type:ComplexType;
	public final optional:Bool;
}

function buildPath(expr:Expr):PathFactory {
	var source = expr.extractString();
	var pos = expr.pos;
	var segments = PathParser.of(source)
		.parse()
		.inspectError(error -> {
			var infos = pos.getInfos();
			Context.makePosition({
				min: infos.min + 1 + error.pos.min,
				max: infos.min + 1 + error.pos.max,
				file: infos.file
			}).error(error.message);
		})
		.orThrow();

	var params = getParamInfo(segments);
	var paramsType:ComplexType = TAnonymous(params.map(param -> ({
		name: param.name,
		kind: FVar(param.type),
		meta: if (param.optional) [
			{name: ':optional', params: [], pos: (macro null).pos}
		] else [],
		pos: (macro null).pos
	} : Field)));
	var pathBuilder = createPathBuilder(segments);
	var pathMatcher = createPathMatcher(segments, paramsType);

	return {
		pathBuilder: createPathBuilder(segments),
		pathMatcher: createPathMatcher(segments, paramsType),
		params: paramsType
	};
}

private function getParamInfo(segments:Array<PathSegment>, ?skipOptional:Bool = false) {
	var params:Array<PathParam> = [];

	function scan(segments:Array<PathSegment>, optional:Bool) {
		for (segment in segments) switch segment {
			case DynamicSegment(key, type):
				params.push({
					name: key,
					type: switch type {
						case PathInt: macro :Int;
						case PathString: macro :String;
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

private function createPathBuilder(segments:Array<PathSegment>):Expr {
	var parts:Array<Expr> = [];
	for (segment in segments) switch segment {
		case StaticSegment(value):
			parts.push(macro $v{value});
		case DynamicSegment(key, _):
			parts.push(macro Std.string(props.$key));
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
		default:
	}

	return macro '/' + [$a{parts}].filter(part -> part != null).join('/');
}

private function createPathMatcher(segments:Array<PathSegment>, paramsType:ComplexType) {
	var segmentExprs:Array<Expr> = segments.map(routeSegmentToExpr);
	return macro new blok.router.path.PathMatcher<$paramsType>([$a{segmentExprs}]);
}

private function routeSegmentToExpr(segment:PathSegment):Expr {
	return switch segment {
		case StaticSegment(value):
			macro StaticSegment($v{value});
		case DynamicSegment(key, type):
			var typeExpr = switch type {
				case PathInt: macro PathInt;
				case PathString: macro PathString;
			}
			macro DynamicSegment($v{key}, ${typeExpr});
		case SplatSegment(key):
			return macro SplatSegment($v{key});
		case OptionalSegment(segments):
			return macro OptionalSegment([$a{segments.map(routeSegmentToExpr)}]);
	}
}
