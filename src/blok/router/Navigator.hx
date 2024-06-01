package blok.router;

import blok.data.Model;
import blok.context.Context;

@:fallback(new Navigator({url: '/'}))
class Navigator extends Model implements Context {
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
