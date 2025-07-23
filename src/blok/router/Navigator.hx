package blok.router;

import blok.router.navigation.*;
import blok.signal.Computation;
import blok.signal.Signal;

using Kit;

@:allow(blok.router)
@:fallback(createDefault())
class Navigator implements Context {
	public static function fromJson(json:{}) {
		return new Navigator(
			#if (js && !nodejs)
			new BrowserHistory(),
			#else
			new ServerHistory(),
			#end
			PathResolverFactory.createFromJson(Reflect.field(json, 'resolver'))
		);
	}

	public static function createDefault() {
		return new Navigator(
			#if (js && !nodejs)
			new BrowserHistory(),
			#else
			new ServerHistory(),
			#end
			new UrlPathResolver()
		);
	}

	public final path:Computation<String>;
	public final location:ReadOnlySignal<Location>;

	final resolver:PathResolver;
	final history:History;

	var link:Null<Cancellable>;

	public function new(history, ?resolver:PathResolver) {
		var location = new Signal(history.currentLocation());
		this.history = history;
		this.resolver = resolver ?? new UrlPathResolver();
		this.location = location;
		this.path = new Computation(() -> resolver.from(this.location()));
		this.link = history.subscribe(current -> location.set(current));
	}

	public function go(path:String) {
		history.push(resolver.to(path));
	}

	public function toJson():{} {
		return {
			resolver: resolver.toJson()
		};
	}

	public function dispose() {
		link.cancel();
	}
}
