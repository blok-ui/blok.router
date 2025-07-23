package blok.router.path;

import blok.router.path.PathSegment;

using Kit;
using StringTools;

@:structInit
class PathParseError {
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

class PathParser {
	public static function ofString(source:String) {
		return new PathParser(source);
	}

	final source:String;

	var position:Int = 0;

	public function new(source) {
		this.source = source;
	}

	public function parse<T:{}>():Result<Array<PathSegment>, PathParseError> {
		position = 0;
		return parseRoot();
	}

	function parseRoot(?until:String):Result<Array<PathSegment>, PathParseError> {
		var segments:Array<PathSegment> = [];

		// Might start with a slash
		match('/');

		while (!isAtEnd()) {
			switch parseSegment() {
				case Ok(segment): segments.push(segment);
				case Error(error): return Error(error);
			}
			if (until != null && check(until)) return Ok(segments);
		}

		return Ok(segments);
	}

	function parseSegment():Result<PathSegment, PathParseError> {
		if (match('*')) return parseWildcardSegment();
		if (match(':')) return parseDynamicSegment();
		if (match('(')) return parseOptionalSegment();
		return parseStaticSegment();
	}

	function parseWildcardSegment():Result<PathSegment, PathParseError> {
		var start = position - 1;

		if (isAtEnd()) return Ok(WildcardSegment());

		var key = readWhile(() -> isIdentifier(peek())).replace('-', '_');
		if (!isAtEnd()) {
			return Error({
				message: 'Only allowed as the last segment of a path',
				pos: {min: start, max: position},
				source: source
			});
		}

		return Ok(WildcardSegment(key));
	}

	function parseStaticSegment():Result<PathSegment, PathParseError> {
		var start = position;
		// @todo: this needs to accept all URL safe characters and handle
		// escape sequences.
		var value = readWhile(() -> isIdentifier(peek()) && !check('/'));

		if (!matchSegmentEnd()) {
			return Error({
				message: 'Expected end of segment',
				pos: {min: position, max: position + 1},
				source: source
			});
		}

		return Ok(StaticSegment(value));
	}

	function parseOptionalSegment():Result<PathSegment, PathParseError> {
		var start = position - 1;
		return parseRoot(')').flatMap(segments -> {
			if (!match(')')) return Error({
				message: 'Expected a ")"',
				pos: {min: position, max: position + 1},
				source: source
			});
			if (!matchSegmentEnd()) {
				return Error({
					message: 'Expected end of segment',
					pos: {min: position, max: position + 1},
					source: source
				});
			}

			Ok(OptionalSegment(segments));
		});
	}

	function parseDynamicSegment():Result<PathSegment, PathParseError> {
		var start = position - 1;
		var key = readWhile(() -> isIdentifier(peek())).replace('-', '_');
		var type:PathParamType = PathString;

		if (match('[')) {
			var innerStart = position;
			var t = readWhile(() -> !check(']'));
			if (!match(']')) return Error({
				message: 'Expected "]"',
				pos: {min: position - 1, max: position},
				source: source
			});
			type = switch t {
				case 'String':
					PathString;
				case 'Int':
					PathInt;
				case other:
					// @todo: Instead of this allow the user to provide a
					// regular expression? Or maybe even a haxe function.
					return Error({
						message: 'Invalid type',
						pos: {min: innerStart, max: position},
						source: source
					});
			}
		}

		if (!matchSegmentEnd()) {
			return Error({
				message: 'Expected end of segment',
				pos: {min: position, max: position + 1},
				source: source
			});
		}

		return Ok(DynamicSegment(key, type));
	}

	function matchAny(...values:String) {
		for (value in values) {
			if (check(value)) {
				position = position + value.length;
				return true;
			}
		}
		return false;
	}

	function matchSegmentEnd() {
		if (match('/')) return true;
		return check(')') || isAtEnd();
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

	function isIdentifier(c:String) {
		return isAlphaNumeric(c) || c == '-' || c == '_';
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
