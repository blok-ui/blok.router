package blok.router.navigation;

using Kit;

@:forward
abstract Location({
	public final pathname:String;

	public final ?search:String;

	public final ?hash:String;
}) {
	@:from public static function ofString(url:String) {
		switch url.split('?') {
			case [pathname, search]:
				switch search.split('#') {
					case [search, hash]:
						return new Location({pathname: pathname, search: search, hash: hash});
					default:
						return new Location({pathname: pathname, search: search});
				}
			case [pathname]:
				switch pathname.split('#') {
					case [pathname, hash]:
						return new Location({pathname: pathname, hash: hash});
				}
			default:
		}

		return new Location({pathname: url});
	}

	public function new(props) {
		this = props;
	}

	public function equals(other:Location) {
		return this.pathname == other.pathname && this.search == other.search && this.hash == other.hash;
	}

	@:to
	public function toString():String {
		var path = this.pathname;

		if (this.search != null && this.search != '') {
			path += '?${this.search}';
		}

		if (this.hash != null && this.hash != '') {
			path += '#${this.hash}';
		}

		return path;
	}
}
