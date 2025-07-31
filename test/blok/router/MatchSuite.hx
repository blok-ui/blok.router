package blok.router;

import blok.html.Html;
import blok.html.server.*;
import blok.router.navigation.*;
import blok.test.SandboxFactory;

class MatchSuite extends Suite {
	@:test(expects = 2)
	function routesMatchCorrectly() {
		// @todo: Clean this up
		var routes = Html.view(<Match>
			<Route to="/">{_ -> 'One'}</Route>
			<Route to="/two">{_ -> 'Two'}</Route>
			<Route to="*">{_ -> 'not found'}</Route>
		</Match>);
		var adaptor = new ServerAdaptor();
		var factory = new SandboxFactory(
			adaptor,
			() -> new ElementPrimitive('#document')
		);
		var navigator = new Navigator(
			new ServerHistory('/'),
			new UrlPathResolver()
		);
		var sandbox = factory.wrap(Provider.provide(navigator).child(routes));

		return sandbox.mount().then(root -> {
			root.primitive.toString({includeTextMarkers: false}).equals('One');
			navigator.go('/two');
			// @todo: We need a consistent way to just schedule for the next render.
			return new Task(activate -> adaptor.schedule(() -> {
				adaptor.scheduleEffect(() -> activate(Ok(root)));
			}));
		}).then(root -> {
			root.primitive.toString({includeTextMarkers: false}).equals('Two');
			return Task.nothing();
		});
	}
}
