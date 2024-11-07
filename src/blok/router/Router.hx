package blok.router;

import blok.ui.*;

/**
	Use a Router to set up a place in your app that will change routes whenever
	the Navigator's url signal updates.

	The Router will throw a `blok.router.RouteNotFoundException` whenever a 
	matching route is not found. You can handle this via an `ErrorBoundary`
	or you can provide a catch-all route to handle routes that aren't found.
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
				return render();
			case None:
				throw new RouteNotFoundException(path, this);
		}
	}
}
