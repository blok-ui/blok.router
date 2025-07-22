package blok.router;

/**
	Use a Router to set up a place in your app that will change routes whenever
	the Navigator's url signal updates.
**/
class Router extends Component {
	@:children @:attribute final routes:MatchableCollection;

	function setup() {
		addDisposable(routes);
	}

	function render():Child {
		var path = Navigator.from(this).path();

		return switch routes.match(path) {
			case Some(render):
				render();
			case None:
				throw new RouteNotFoundException(path);
		}
	}
}
