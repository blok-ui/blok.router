package blok.router;

class Router extends Component {
	@:attribute final navigator:Navigator = null;
	@:children @:attribute final children:Children;

	function render():Child {
		return Provider.provide(
			navigator ?? Navigator.createDefault()
		).child(children);
	}
}
