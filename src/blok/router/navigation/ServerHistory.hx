package blok.router.navigation;

using Kit;

class ServerHistory implements History {
	final onChange = new Event<Location>();

	var stack:Array<Location> = [];

	public function new(?location:Location) {
		var currentLocation = location ?? Location.ofString('/');
		stack.push(currentLocation);
	}

	public function currentLocation() {
		return stack[stack.length - 1];
	}

	public function replace(to:String, ?state:Dynamic) {
		stack[stack.length - 1] = Location.ofString(to);
	}

	public function push(to:String, ?state:Dynamic) {
		var location = Location.ofString(to);
		if (currentLocation().equals(location)) {
			return;
		}
		stack.push(location);
		onChange.dispatch(location);
	}

	public function go(delta:Int):Void {
		var last = currentLocation();
		stack = stack.slice(0, delta);

		if (last.equals(currentLocation())) return;

		onChange.dispatch(currentLocation());
	}

	public function subscribe(subscription:(location:Location) -> Void):Cancellable {
		subscription(currentLocation());
		return onChange.add(subscription);
	}

	public function dispose() {
		onChange.cancel();
	}
}
