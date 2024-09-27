package blok.router;

import blok.data.Model;
import blok.context.Context;

@:fallback(instance())
class Navigator extends Model implements Context {
	public static function instance() {
		static var navigator:Null<Navigator> = null;
		if (navigator == null) navigator = new Navigator({url: '/'});
		return navigator;
	}

	@:signal public final url:String;

	#if pine.client
	function new() {
		// @todo: Watch the browser for push/pop state
	}
	#end

	public function go(path) {
		#if pine.client
		// @todo: Push to the browser
		#end
		url.set(path);
	}
}
