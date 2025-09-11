package blok.router.path;

import haxe.macro.Context;
import haxe.macro.Expr;

using Kit;
using haxe.macro.Tools;
using kit.Macro;

typedef PathParam = {
	public final name:String;
	public final type:ComplexType;
	public final optional:Bool;
	public final wildcard:Bool;
}

@:forward
abstract PathInfo({
	public final params:ComplexType;
	public final pathBuilder:Expr;
	public final pathMatcher:Expr;
}) {
	@:from public static function ofExpr(expr:Expr) {
		var source = expr.extractString();
		var pos = expr.pos;
		var segments = PathParser.ofString(source)
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
			meta: [
				if (param.optional)
					{name: ':optional', params: [], pos: (macro null).pos}
				else
					null
			].filter(entry -> entry != null),
			pos: (macro null).pos
		} : Field)));
		var pathBuilder = createPathBuilder(segments);
		var pathMatcher = createPathMatcher(segments, paramsType);

		return new PathInfo({
			pathBuilder: pathBuilder,
			pathMatcher: pathMatcher,
			params: paramsType
		});
	}

	public function new(props) {
		this = props;
	}
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
					optional: optional,
					wildcard: false
				});
			case OptionalSegment(segments) if (!skipOptional):
				scan(segments, true);
			case WildcardSegment(key) if (key != null):
				params.push({
					name: key,
					type: macro :String,
					optional: true,
					wildcard: true
				});
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
		case WildcardSegment(key) if (key != null):
			parts.push(macro if (props.$key != null) props.$key else null);
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
		case WildcardSegment(key):
			return macro WildcardSegment($v{key});
		case OptionalSegment(segments):
			return macro OptionalSegment([$a{segments.map(routeSegmentToExpr)}]);
	}
}
