package blok.router;

import blok.ui.Child;

using Kit;

@:forward
abstract MatchableCollection(Array<Matchable>) from Array<Matchable> {
	@:from public static function ofMatchable(matchable:Matchable):MatchableCollection {
		return [matchable];
	}

	public function match(path:String):Maybe<() -> Child> {
		for (matchable in this) switch matchable.match(path) {
			case Some(value): return Some(value);
			case None:
		}
		return None;
	}
}
