package blok.router;

import haxe.io.Path;

class Group extends Component {
	@:children @:attribute final routes:MatchableCollection;

	public function render():Child {
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
	}
}
