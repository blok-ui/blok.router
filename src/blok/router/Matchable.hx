package blok.router;

import blok.core.Disposable;
import blok.ui.*;

using Kit;

interface Matchable extends Disposable {
	public function match(path:String):Maybe<() -> Child>;
}
