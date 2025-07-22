package blok.router.path;

typedef PathMatch<Params:{}> = {
	public final params:Params;
	public final path:String;
	public final ?remainder:String;
}
