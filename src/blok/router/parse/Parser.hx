package blok.router.parse;

import blok.router.parse.RouteSegment;

using Kit;

@:structInit
class ParserError {
	public final message:String;
	public final pos:{min:Int, max:Int};

	final source:String;

	public function toString() {
		var before = source.substring(0, pos.min);
		var unexpected = source.substring(pos.min, pos.max);
		var after = source.substring(pos.max);
		return '$before[ERROR: $message: "$unexpected"]$after';
	}
}

class Parser {
	public static function of(source:String) {
		return new Parser(source);
	}

	final source:String;

	var position:Int = 0;

	public function new(source) {
		this.source = source;
	}

	public function parse<T:{}>():Result<RoutePath<T>, ParserError> {
		position = 0;
		return parseRoot().map(segments -> new RoutePath(segments));
	}

	function parseRoot(?until:String):Result<Array<RouteSegment>, ParserError> {
		var segments:Array<RouteSegment> = [];

		function iter():Result<Array<RouteSegment>, ParserError> {
			if (match('/')) return iter();
			if (until != null && check(until)) return Ok(segments);
			return parseSegment().flatMap(expr -> {
				segments.push(expr);
				return if (!isAtEnd()) {
					iter();
				} else {
					Ok(segments);
				}
			});
		}

		return iter();
	}

	function parseSegment():Result<RouteSegment, ParserError> {
		if (match('*')) return #if macro
			Ok(SplatSegment({min: position - 1, max: position}));
		#else
			Ok(SplatSegment);
		#end
		if (match(':')) return parseDynamicSegment();
		if (match('(')) return parseOptionalSegment();
		return parseStaticSegment();
	}

	function parseStaticSegment():Result<RouteSegment, ParserError> {
		var start = position;
		var value = readWhile(() -> isAlphaNumeric(peek()) && !check('/'));

		if (!check('/') && !isAtEnd()) {
			return Error({
				message: 'Unexpected character',
				pos: {min: position, max: position + 1},
				source: source
			});
		}

		return Ok(StaticSegment(value #if macro, {min: start, max: position} #end));
	}

	function parseOptionalSegment():Result<RouteSegment, ParserError> {
		var start = position - 1;
		return parseRoot(')').flatMap(segments -> {
			if (!match(')')) return Error({
				message: 'Expected a ")"',
				pos: {min: position, max: position + 1},
				source: source
			});

			Ok(OptionalSegment(segments #if macro, {min: start, max: position} #end));
		});
	}

	function parseDynamicSegment():Result<RouteSegment, ParserError> {
		var start = position - 1;
		var key = readWhile(() -> isAlphaNumeric(peek()) && !check(':') && !check('/'));
		var type:RouteParamType = RouteString;

		if (match(':')) {
			var innerStart = position;
			var t = readWhile(() -> isAlphaNumeric(peek()) && !check('/'));
			type = switch t {
				case 'String':
					RouteString;
				case 'Int':
					RouteInt;
				case other:
					return Error({
						message: 'Invalid type',
						pos: {min: innerStart, max: position},
						source: source
					});
			}
		}

		if (!checkAny('/', ')') && !isAtEnd()) {
			return Error({
				message: 'Unexpected character',
				pos: {min: position, max: position + 1},
				source: source
			});
		}

		return Ok(DynamicSegment(key, type #if macro, {min: start, max: position} #end));
	}

	function match(value:String) {
		if (check(value)) {
			position = position + value.length;
			return true;
		}
		return false;
	}

	function isDigit(c:String):Bool {
		return c >= '0' && c <= '9';
	}

	function isAlpha(c:String):Bool {
		return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
	}

	function isAlphaNumeric(c:String) {
		return isAlpha(c) || isDigit(c);
	}

	function checkAny(...values:String) {
		for (value in values) {
			if (check(value)) return true;
		}
		return false;
	}

	function check(value:String) {
		var found = source.substr(position, value.length);
		return found == value;
	}

	function peek() {
		return source.charAt(position);
	}

	function previous() {
		return source.charAt(position - 1);
	}

	function advance() {
		if (!isAtEnd()) position++;
		return previous();
	}

	function isAtEnd() {
		return position >= source.length;
	}

	function readWhile(compare:() -> Bool):String {
		var out = [while (!isAtEnd() && compare()) advance()];
		return out.join('');
	}
}
