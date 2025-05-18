package blok.router;

import blok.engine.FragmentNode;
import blok.html.AttributeName;
import blok.html.Html;
import blok.html.HtmlAttributes;
import blok.signal.Signal;

abstract Link({
	public final url:String;

	public final props:{}

	public final children:Children;
}) {
	@:fromMarkup
	@:noUsing
	@:noCompletion
	public static function fromMarkup(props:GlobalAttributes & {to:String}, ...children:Child) {
		var url = Reflect.field(props, 'to');
		Reflect.deleteField(props, 'to');
		return new Link(url, props).child(...children).node();
	}

	public static function to(url) {
		return new Link(url);
	}

	public inline function new(url, ?props:{}) {
		this = {
			url: url,
			props: props ?? {},
			children: []
		};
	}

	public inline function attr(name:AttributeName<GlobalAttributes>, value:ReadOnlySignal<String>) {
		Reflect.setField(this.props, name, value);
		return abstract;
	}

	public inline function child(...children:Child) {
		for (child in children) if (child is FragmentNode) {
			abstract.child(...(cast child : FragmentNode).children);
		} else {
			this.children.push(child);
		}
		return abstract;
	}

	@:to
	public function node():Child {
		return Scope.wrap(context -> {
			var node = Html.a()
				.attr('href', this.url)
				.child(this.children);

			for (prop in Reflect.fields(this.props)) {
				node.attr(prop, Reflect.field(this.props, prop));
			}

			switch Navigator.maybeFrom(context) {
				case Some(nav):
					// @todo: This needs to be configurable -- we won't
					// always want to intercept it.
					node.on(Click, e -> {
						e.preventDefault();
						nav.go(this.url);
					});
				case None:
			}

			return node;
		});
	}

	@:to
	public inline function toChildren():Children {
		return node();
	}
}
