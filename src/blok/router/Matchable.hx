package blok.router;

import blok.core.*;

using Kit;

interface Matchable extends Disposable {
	public function match(path:String):Maybe<Child>;
}
