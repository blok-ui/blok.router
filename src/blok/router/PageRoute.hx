package blok.router;

import blok.adaptor.*;
import blok.core.Owner;
import blok.debug.Debug;
import blok.diffing.Differ;
import blok.ui.*;

@:genericBuild(blok.router.PageRouteBuilder.buildGeneric())
class PageRoute<@:const Path> {}

abstract class PageRouteImpl extends View {
	var __child:Null<View> = null;

	abstract function setup():Void;

	abstract function render():Child;

	abstract function __updateProps():Void;

	function __render():VNode {
		return Scope.wrap(_ -> render());
	}

	function __initialize() {
		__child = __render().createComponent();
		__child?.mount(getAdaptor(), this, __slot);
		Owner.with(this, setup);
	}

	function __hydrate(cursor:Cursor) {
		__child = __render().createComponent();
		__child?.hydrate(cursor, getAdaptor(), this, __slot);
		Owner.with(this, setup);
	}

	function __update() {
		__updateProps();
		__child = updateChild(this, __child, __render(), __slot);
	}

	function __validate() {
		__child = updateChild(this, __child, __render(), __slot);
	}

	function __dispose() {}

	function __updateSlot(oldSlot:Null<Slot>, newSlot:Null<Slot>) {
		__child?.updateSlot(newSlot);
	}

	public function getPrimitive():Dynamic {
		var node = __child?.getPrimitive();
		assert(node != null, 'No primitive found');
		return node;
	}

	public function visitChildren(visitor:(child:View) -> Bool) {
		if (__child != null) visitor(__child);
	}
}
