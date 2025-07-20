package blok.router.parse;

import blok.router.parse.RouteSegment;

using Kit;
using StringTools;
using haxe.io.Path;
using Reflect;

typedef RoutePathResult<T:{}> = {
	public final params:T;
	public final remaining:Array<String>;
}

// @todo: Probably would be wise to figure out how to compile this
// into regular expressions? I am uneasy about this class.

@:allow(blok.router)
class RoutePath<T:{} = {}> {
	final segments:Array<RouteSegment>;
	final parent:Null<RoutePath>;

	public function new(segments, ?parent:RoutePath) {
		this.segments = segments;
		this.parent = parent;
	}

	public function match(path:String):Maybe<T> {
		var path = normalizePath(path).split('/');
		return switch recursiveMatch(path) {
			case Some({params: params, remaining: remaining}):
				if (remaining.length > 0) return None;
				Some(params);
			case None:
				None;
		}
	}

	function recursiveMatch(parts:Array<String>):Maybe<RoutePathResult<T>> {
		if (parent != null) return switch parent.recursiveMatch(parts) {
			case Some({params: params, remaining: remaining}):
				doMatch(segments, remaining).map(result -> {
					for (key in params.fields()) {
						result.params.setField(key, params.field(key));
					}
					result;
				});
			case None:
				None;
		}
		return doMatch(segments, parts);
	}

	function doMatch(segments:Array<RouteSegment>, parts:Array<String>):Maybe<RoutePathResult<T>> {
		var params:{} = {};
		var current = parts.shift();

		for (segment in segments) switch segment {
			case StaticSegment(value):
				if (value != current) return None;
				current = parts.shift();
			case DynamicSegment(key, type):
				if (current == null) return None;
				if (!type.test(current)) return None;
				params.setField(key, current);
				current = parts.shift();
			case #if macro SplatSegment(_) #else SplatSegment #end:
				return Some({params: cast params, remaining: []});
			case OptionalSegment(optionalSegments):
				switch doMatch(optionalSegments, [current].concat(parts)) {
					case Some({params: optionalParams, remaining: remaining}):
						for (key in optionalParams.fields()) {
							params.setField(key, optionalParams.field(key));
						}
						parts = remaining;
						current = parts.shift();
					case None:
				}
		}

		var remaining = current != null ? [current].concat(parts) : parts;
		return Some({params: cast params, remaining: remaining});
	}
}

function normalizePath(path:String) {
	path = path.normalize().trim();
	if (path == '*') {
		return path;
	}
	if (path.startsWith('/')) {
		path = path.substr(1);
	}
	return path;
}
