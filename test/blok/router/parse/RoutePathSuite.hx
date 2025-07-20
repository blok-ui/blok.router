package blok.router.parse;

class RoutePathSuite extends Suite {
	@:test(expects = 6)
	function simplePathWorks() {
		var path = new RoutePath<{two:String, ?name:String}>([
			StaticSegment('one'),
			DynamicSegment('two', RouteString),
			StaticSegment('three'),
			OptionalSegment([
				StaticSegment('name'),
				DynamicSegment('name', RouteString)
			]),
			StaticSegment('end')
		]);

		path
			.match('/one/matchedTwo/three/end')
			.inspect(params -> params.two.equals('matchedTwo'));
		path
			.match('/one/matchedTwo/three/name/Bill/end')
			.inspect(params -> {
				params.two.equals('matchedTwo');
				params.name.equals('Bill');
			});
		path
			.match('/not-a-matching-route/ok')
			.equals(None);
		path
			.match('/one/matchedTwo/three/wrongSegment/Bill/end')
			.equals(None);
		path
			.match('/one/matchedTwo/three/wrongSegment/Bill')
			.equals(None);
	}
}
