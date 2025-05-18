package blok.router;

import haxe.Exception;

final class RouteNotFoundException extends Exception {
	public final url:String;

	public function new(url) {
		super('Route not found');
		this.url = url;
	}
}
