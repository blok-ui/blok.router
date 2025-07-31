package blok.router;

import haxe.io.Path;

/**
	Renders the first route that matches the current path.

	`Match` is context aware -- if used inside a Route it will
	match routes relative to the current path. If used on its
	own `Match` will use the current Navigator.
**/
#if php
// @todo: Haxe apparently doesn't have "match" on its list of reserved PHP
// keywords yet. Remove this when that is no longer the case.
@:native('MatchRoute')
#end
class Match extends Component {
	public inline static function of(routes) {
		return node({routes: routes});
	}

	@:children @:attribute final routes:MatchableCollection;

	function setup() {
		addDisposable(routes);
	}

	public function render():Child {
		return switch RouteView.maybeFrom(this) {
			case Some(route):
				var match = route.match();
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
