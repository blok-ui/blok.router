package blok.router;

import haxe.io.Path;

/**
	Renders the first route that matches the current path.

	`Match` is context aware -- if used inside a Route it will
	match routes relative to the current path. If used on its
	own `Match` works the same as `Router`.
**/
class Match extends Component {
	@:children @:attribute final routes:MatchableCollection;

	function setup() {
		addDisposable(routes);
	}

	public function render():Child {
		return switch RouteView.maybeFrom(this) {
			case Some(route):
				var match = RouteView.from(this).match();
				return switch routes.match(match.remainder) {
					case Some(child):
						child;
					case None:
						throw new RouteNotFoundException(Path.join([
							match.path,
							match.remainder
						]));
				}
			case None:
				var path = Navigator.from(this).path();
				return switch routes.match(path) {
					case Some(child):
						child;
					case None:
						throw new RouteNotFoundException(path);
				}
		}
	}
}
