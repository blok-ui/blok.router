package blok.router.path;

enum PathSegment {
	StaticSegment(value:String);
	DynamicSegment(key:String, type:PathParamType);
	SplatSegment(?key:String);
	OptionalSegment(segments:Array<PathSegment>);
}

@:using(PathSegment.PathParamTypeTools)
enum abstract PathParamType(String) {
	final PathString = 'String';
	final PathInt = 'Int';
}

class PathParamTypeTools {
	static final matchString = ~/[a-zA-Z0-9\\-_]/;
	static final matchInt = ~/\d/;

	public static function test(type:PathParamType, value:String) {
		return switch type {
			case PathString: matchString.match(value);
			case PathInt: matchInt.match(value);
		}
	}
}
