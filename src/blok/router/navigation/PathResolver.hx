package blok.router.navigation;

interface PathResolver {
	public function from(location:Location):String;
	public function to(path:String):Location;
}
