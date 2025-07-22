package blok.router;

import blok.router.path.PathMatch;
import blok.signal.Signal;
import blok.core.*;
import blok.engine.*;

using Kit;
using haxe.io.Path;
using Reflect;

@:allow(blok.router)
class RouteView<Params:{}> implements View {
	public static function from(view:IntoView) {
		return maybeFrom(view).orThrow('No RouteContext exists');
	}

	public static function maybeFrom(view:IntoView) {
		return view.unwrap()
			.findAncestorOfType(RouteView)
			.map(route -> route);
	}

	public static function getFullPathFromRelativePath(view:IntoView, path:String):Maybe<String> {
		if (path.isAbsolute()) return Some(path);

		function scan(view:IntoView, path:String):Maybe<String> {
			return view.unwrap()
				.findAncestorOfType(RouteView)
				.map(route -> {
					var root = route.node.match.path;
					var fullPath = Path.join([root, path]);
					return scan(route, fullPath).or(() -> fullPath);
				});
		}

		return scan(view, path);
	}

	public final match:Signal<PathMatch<Params>>;

	final adaptor:Adaptor;
	final child:ViewReconciler;
	final disposables:DisposableCollection;

	var parent:Maybe<View>;
	var node:RouteNode<Params>;

	public function new(parent, node, adaptor) {
		this.adaptor = adaptor;
		this.parent = parent;
		this.node = node;
		this.match = new Signal(node.match);
		this.disposables = new DisposableCollection();
		this.child = new ViewReconciler(this, adaptor);
	}

	public function currentNode():Node {
		return node;
	}

	public function currentParent():Maybe<View> {
		return parent;
	}

	function render() {
		return node.render(node.match);
	}

	public function insert(cursor:Cursor, ?hydrate:Bool):Result<View, ViewError> {
		return child.insert(render(), cursor, hydrate).map(_ -> (this : View));
	}

	public function update(parent:Maybe<View>, node:Node, cursor:Cursor):Result<View, ViewError> {
		this.parent = parent;
		this.node = this.node.replaceWith(node)
			.mapError(node -> ViewError.IncorrectNodeType(this, node))
			.orReturn();
		this.match.set(this.node.match);

		return child.reconcile(render(), cursor).map(_ -> (this : View));
	}

	public function remove(cursor:Cursor):Result<View, ViewError> {
		disposables.dispose();
		return child.remove(cursor).map(_ -> (this : View));
	}

	public function visitChildren(visitor:(child:View) -> Bool) {
		child.get().inspect(child -> visitor(child));
	}

	public function visitPrimitives(visitor:(primitive:Any) -> Bool) {
		child.get().inspect(child -> child.visitPrimitives(visitor));
	}

	public function addDisposable(disposable:DisposableItem) {
		disposables.addDisposable(disposable);
	}

	public function removeDisposable(disposable:DisposableItem) {
		disposables.removeDisposable(disposable);
	}
}
