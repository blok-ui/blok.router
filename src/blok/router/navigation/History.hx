package blok.router.navigation;

import blok.core.Disposable;

using Kit;

interface History extends Disposable {
	public function currentLocation():Location;
	public function push(to:String, ?state:Dynamic):Void;
	public function replace(to:String, ?state:Dynamic):Void;
	public function go(delta:Int):Void;
	public function subscribe(subscription:(location:Location) -> Void):Cancellable;
}
