package blok.router;

import blok.ui.*;

using Kit;

interface Matchable {
	public function match(path:String):Maybe<() -> Child>;
}
