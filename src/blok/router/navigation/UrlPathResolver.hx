package blok.router.navigation;

class UrlPathResolver implements PathResolver {
	public function new() {}

	public function from(location:Location):String {
		return location.toString();
	}

	public function to(path:String):Location {
		return path;
	}
}
