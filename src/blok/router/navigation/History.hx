package blok.router.navigation;

using Kit;

// @todo: Probably remove ?state args and `replace` and `go` methods?
interface History extends Disposable {
	public function currentLocation():Location;
	public function push(to:String, ?state:Dynamic):Void;
	public function replace(to:String, ?state:Dynamic):Void;
	public function go(delta:Int):Void;
	public function subscribe(subscription:(location:Location) -> Void):Cancellable;
}
