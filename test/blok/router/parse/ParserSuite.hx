package blok.router.parse;

class ParserSuite extends Suite {
	@:test(expects = 8)
	function pathsAreParsed() {
		var source = '/one/:two/:three:Int/(optional/:optional)/end';
		var parser = new Parser(source);

		Parser.of('/one/:two/:three:Int/(optional/:optional)/end')
			.parse()
			.inspect((path:RoutePath<{two:String, three:String, ?optional:String}>) -> {
				path.match('/one/two/3/end').inspect(params -> {
					params.two.equals('two');
					params.three.equals('3');
					params.optional.equals(null);
				});
				path.match('/one/two/3/optional/bar/end').inspect(params -> {
					params.two.equals('two');
					params.three.equals('3');
					params.optional.equals('bar');
				});
				path.match('/one/two/3').equals(None);
				path.match('/one/two/3/optional/bar').equals(None);
			})
			.inspectError(error -> Assert.fail('Parsing failed: ${error}'));
	}

	@:test(expects = 3)
	function typesAreParsedCorrectly() {
		Parser.of('/str/:str:String/int/:int:Int')
			.parse()
			.inspect((path:RoutePath<{str:String, int:String}>) -> {
				path.match('/str/str/int/1').inspect(params -> {
					params.str.equals('str');
					params.int.equals('1');
				});
				path.match('/str/str/int/int').equals(None);
			})
			.inspectError(error -> Assert.fail('Parsing failed: ${error}'));
	}
}
