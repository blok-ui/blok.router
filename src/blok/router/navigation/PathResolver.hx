package blok.router.navigation;

interface PathResolver {
	/**
		Convert a path from the actual location to a 
		path the Router will use to match routes.
	**/
	public function from(location:Location):String;

	/**
		Convert from the path the Router uses to the actual
		location. This may be the same as the router's path 
		(when using URLs) or it may be different (e.g. using 
		the URL hash).
	**/
	public function to(path:String):Location;

	public function toJson():{};
}
