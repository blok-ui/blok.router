package blok.router;

import blok.core.BlokException;

final class RouteNotFoundException extends BlokComponentException {
	public final url:String;

	public function new(url, component) {
		super('Route not found', component);
		this.url = url;
	}
}
