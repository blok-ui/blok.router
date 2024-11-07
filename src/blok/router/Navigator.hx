package blok.router;

import blok.context.Context;
import blok.debug.Debug;
import blok.router.navigation.*;
import blok.signal.Signal;

using Kit;

@:fallback(error('Not found'))
class Navigator implements Context {
	public var path(get, never):String;

	inline function get_path() return resolver.from(location());

	public var location(get, never):ReadOnlySignal<Location>;

	inline function get_location() return __location;

	final resolver:PathResolver;
	final history:History;
	final __location:Signal<Location>;

	var link:Null<Cancellable>;

	public function new(history, ?resolver:PathResolver) {
		this.history = history;
		this.resolver = resolver ?? new UrlPathResolver();
		this.__location = new Signal(history.currentLocation());
		this.link = history.subscribe(location -> __location.set(location));
	}

	public function go(path:String) {
		history.push(resolver.to(path));
	}

	public function dispose() {
		link.cancel();
	}
}
