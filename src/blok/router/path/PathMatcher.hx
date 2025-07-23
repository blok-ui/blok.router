package blok.router.path;

using Kit;
using StringTools;
using haxe.io.Path;
using Reflect;

class PathMatcher<Params:{}> {
	final segments:Array<PathSegment>;

	public function new(segments) {
		this.segments = segments;
	}

	public function match(location:String):Maybe<PathMatch<Params>> {
		var path = normalizePath(location);
		if (segments.length == 0) {
			return if (path == '/') Some({
				params: cast {},
				remainder: null,
				path: '/'
			}) else None;
		}

		var parts = path.split('/').filter(part -> part != null && part.length > 0);

		return matchSegments(segments, parts)
			.flatMap(result -> {
				if (result.remaining.length > 0 && !result.hasWildcard) {
					return None;
				}
				return Some(result);
			})
			.map(result -> {
				params: cast result.params,
				path: normalizePath(result.path.join('/')),
				remainder: if (result.remaining.length == 0) null else normalizePath(result.remaining.join('/'))
			});
	}

	function matchSegments(segments:Array<PathSegment>, parts:Array<String>):Maybe<{
		?hasWildcard:Bool,
		params:{},
		path:Array<String>,
		remaining:Array<String>
	}> {
		var params = {};
		var path:Array<String> = [];

		for (segment in segments) switch segment {
			case StaticSegment(value):
				if (value != parts[0]) return None;
				path.push(parts.shift());
			case DynamicSegment(key, type):
				var part = parts[0];
				if (part == null) return None;
				if (!type.test(part)) return None;
				params.setField(key, type.decode(part));
				path.push(parts.shift());
			case WildcardSegment(key):
				if (key != null && parts.length > 0) {
					params.setField(key, '/' + parts.join('/'));
				}
				return Some({
					hasWildcard: true,
					params: params,
					path: path,
					remaining: parts
				});
			case OptionalSegment(segments):
				switch matchSegments(segments, parts) {
					case Some({params: optionalParams, path: optionalPath, remaining: remaining}):
						for (key in optionalParams.fields()) {
							params.setField(key, optionalParams.field(key));
						}
						path = path.concat(optionalPath);
						parts = remaining;
					case None:
				}
		}

		return Some({
			params: params,
			path: path,
			remaining: parts
		});
	}

	function normalizePath(path:String) {
		if (path == null) path = '';
		path = path.normalize().trim();
		if (path == '*') {
			return path;
		}
		if (!path.startsWith('/')) {
			path = '/$path';
		}
		return path;
	}
}
