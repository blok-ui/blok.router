package blok.router;

import blok.ui.*;

class Router extends Component {
	@:attribute final fallback:(url:String) -> Child;
	@:children @:attribute final routes:MatchableCollection;

	function setup() {
		addDisposable(routes);
	}

	function render():Child {
		var nav = Navigator.from(this);
		var url = nav.url();

		switch routes.match(url) {
			case Some(render):
				return render();
			case None:
		}

		return fallback(url);
	}
}
