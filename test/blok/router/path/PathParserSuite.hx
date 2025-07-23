package blok.router.path;

class PathParserSuite extends Suite {
	@:test(expects = 2)
	function indexRouteShouldOnlyMatchSingleSlash() {
		PathParser.ofString('/')
			.parse()
			.inspect(segments -> {
				var matcher = new PathMatcher<{}>(segments);
				matcher.match('/foo/bar').equals(None);
				matcher.match('/').inspect(match -> {
					match.path.equals('/');
				});
			})
			.inspectError(error -> Assert.fail('Parsing failed: ${error}'));
	}

	@:test(expects = 8)
	function pathsAreParsed() {
		PathParser.ofString('/one/:two/:three[String]/(optional/:optional)/end')
			.parse()
			.inspect(segments -> {
				var matcher = new PathMatcher<{two:String, three:String, ?optional:String}>(segments);
				matcher.match('/one/two/3/end').inspect(match -> {
					match.params.two.equals('two');
					match.params.three.equals('3');
					match.params.optional.equals(null);
				});
				matcher.match('/one/two/3/optional/bar/end').inspect(match -> {
					match.params.two.equals('two');
					match.params.three.equals('3');
					match.params.optional.equals('bar');
				});
				matcher.match('/one/two/3').equals(None);
				matcher.match('/one/two/3/optional/bar').equals(None);
			})
			.inspectError(error -> Assert.fail('Parsing failed: ${error}'));
	}

	@:test(expects = 4)
	function typesAreParsedCorrectly() {
		PathParser.ofString('/str/:str[String]/int/:int[Int]')
			.parse()
			.inspect(segments -> {
				var matcher = new PathMatcher<{str:String, int:String}>(segments);
				matcher.match('/str/str/int/1').inspect(match -> {
					match.params.str.equals('str');
					match.params.int.equals('1');
					match.remainder.equals(null);
				});
				matcher.match('/str/str/int/int').equals(None);
			})
			.inspectError(error -> Assert.fail('Parsing failed: ${error}'));
	}

	@:test(expects = 3)
	function remainingSegmentsArePassedToTheMatcherOnWildcards() {
		PathParser.ofString('/str/:str/*')
			.parse()
			.inspect(segments -> {
				var matcher = new PathMatcher<{str:String}>(segments);
				matcher.match('/str/foo/bar/bin').inspect(match -> {
					match.params.str.equals('foo');
					match.path.equals('/str/foo');
					match.remainder.equals('/bar/bin');
				});
			})
			.inspectError(error -> Assert.fail('Parsing failed: ${error}'));
	}

	@:test(expects = 4)
	function namedWildcardsArePassedToParams() {
		PathParser.ofString('/str/:str/*more')
			.parse()
			.inspect(segments -> {
				var matcher = new PathMatcher<{str:String, ?more:String}>(segments);
				matcher.match('/str/foo/bar/bin').inspect(match -> {
					match.params.str.equals('foo');
					match.params.more.equals('/bar/bin');
					match.params.more.equals(match.remainder);
					match.path.equals('/str/foo');
				});
			})
			.inspectError(error -> Assert.fail('Parsing failed: ${error}'));
	}

	@:test(expects = 2)
	function dynamicNamesAreSafelyConverted() {
		PathParser.ofString('/one/:this-is-a-param/:so_is_this')
			.parse()
			.inspect(segments -> {
				var matcher = new PathMatcher<{
					this_is_a_param:String,
					so_is_this:String
				}>(segments);
				matcher.match('/one/two/three').inspect(match -> {
					match.params.this_is_a_param.equals('two');
					match.params.so_is_this.equals('three');
				});
			})
			.inspectError(error -> Assert.fail('Parsing failed: ${error}'));
	}
}
