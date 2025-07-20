package blok.router.parse;

enum RouteSegment {
	StaticSegment(value:String #if macro, ?pos:{min:Int, max:Int} #end);
	DynamicSegment(key:String, type:RouteParamType #if macro, ?pos:{min:Int, max:Int} #end);
	SplatSegment(#if macro ?pos:{min: Int, max: Int} #end);
	OptionalSegment(segments:Array<RouteSegment> #if macro, ?pos:{min:Int, max:Int} #end);
}

@:using(RouteSegment.RouteParamTypeTools)
enum abstract RouteParamType(String) {
	final RouteString = 'String';
	final RouteInt = 'Int';
}

class RouteParamTypeTools {
	static final matchString = ~/[a-zA-Z0-9\\-_]/;
	static final matchInt = ~/\d/;

	public static function test(type:RouteParamType, value:String) {
		return switch type {
			case RouteString: matchString.match(value);
			case RouteInt: matchInt.match(value);
		}
	}
}
