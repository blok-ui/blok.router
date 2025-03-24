package blok.router;

using Kit;

@:forward
abstract MatchableCollection(Array<Matchable>) from Array<Matchable> {
	@:from public static function ofMatchable(matchable:Matchable):MatchableCollection {
		return [matchable];
	}

	public function match(path:String):Maybe<() -> Child> {
		for (matchable in this) switch matchable.match(path) {
			case None:
			case matched: return matched;
		}
		return None;
	}

	@:to public function toDisposable():DisposableItem {
		return () -> for (matchable in this) matchable.dispose();
	}
}
