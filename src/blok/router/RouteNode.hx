package blok.router;

import blok.router.path.PathMatch;
import blok.engine.*;

using Kit;

class RouteNode<Params:{}> implements Node {
	public final match:PathMatch<Params>;
	public final render:(match:PathMatch<Params>) -> Child;
	public final key:Null<Key>;

	public function new(match, render, ?key:Key) {
		this.match = match;
		this.render = render;
		this.key = key;
	}

	public function matches(other:Node):Bool {
		return other is RouteNode && key == other.key;
	}

	public function createView(parent:Maybe<View>, adaptor:Adaptor):View {
		return new RouteView(parent, this, adaptor);
	}
}
