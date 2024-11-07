package blok.router.navigation;

using StringTools;

class HashPathResolver implements PathResolver {
	final pathname:String;

	public function new(pathname) {
		this.pathname = pathname;
	}

	public function from(location:Location):String {
		if (location.hash == null || location.hash.length == 0) return '/';
		return location.hash;
	}

	public function to(path:String):Location {
		return new Location({pathname: pathname, hash: path});
	}
}
