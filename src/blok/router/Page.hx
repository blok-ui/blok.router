package blok.router;

import blok.Component;
import blok.core.*;

@:genericBuild(blok.router.PageBuilder.buildGeneric())
class Page<@:const Path> {}

abstract class PageState implements ComponentLike implements DisposableHost {
	@:noCompletion
	final __disposables:DisposableCollection = new DisposableCollection();

	abstract public function render():Child;

	abstract public function setup():Void;

	public function investigate() {
		return new ComponentInvestigator(cast getView());
	}

	public function addDisposable(disposable:DisposableItem) {
		__disposables.addDisposable(disposable);
	}

	public function removeDisposable(disposable:DisposableItem) {
		__disposables.removeDisposable(disposable);
	}
}
