package blok.router;

import blok.signal.Computation;
import blok.context.Context;
import blok.debug.Debug;
import blok.router.navigation.*;
import blok.signal.Signal;

using Kit;

@:fallback(error('Not found'))
class Navigator implements Context {
	public final path:Computation<String>;
	public final location:ReadOnlySignal<Location>;

	final resolver:PathResolver;
	final history:History;

	var link:Null<Cancellable>;

	public function new(history, ?resolver:PathResolver) {
		this.history = history;
		this.resolver = resolver ?? new UrlPathResolver();
		this.location = new Signal(history.currentLocation());
		this.path = new Computation(() -> resolver.from(this.location()));
		this.link = history.subscribe(current -> (cast location : Signal<Location>).set(current));
	}

	public function go(path:String) {
		history.push(resolver.to(path));
	}

	public function dispose() {
		link.cancel();
		path.dispose();
	}
}
