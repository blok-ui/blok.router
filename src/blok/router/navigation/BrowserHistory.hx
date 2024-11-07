package blok.router.navigation;

import js.Browser;

using Kit;
using StringTools;

class BrowserHistory implements History {
	final onChange = new Event<Location>();

	public function new() {
		Browser.window.addEventListener('popstate', listener);
	}

	public function go(delta:Int) {}

	public function replace(to:String, ?state:Dynamic) {}

	public function push(to:String, ?state:Dynamic) {
		Browser.window.history.pushState(null, null, to);
		onChange.dispatch(to);
	}

	public function dispose() {
		Browser.window.removeEventListener('popstate', listener);
		onChange.cancel();
	}

	public function currentLocation():Location {
		Browser.window.location.extract(try {pathname: pathname, search: search, hash: hash});
		return new Location({pathname: pathname, search: search, hash: hash?.replace('#', '')});
	}

	public function subscribe(subscription:(location:Location) -> Void):Cancellable {
		subscription(currentLocation());
		return onChange.add(subscription);
	}

	function listener(_) {
		onChange.dispatch(currentLocation());
	}
}
