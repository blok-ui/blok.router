package blok.router;

import blok.html.HtmlAttributes.GlobalAttr;
import blok.html.Html;
import blok.html.HtmlAttributeName;
import blok.signal.Signal;
import blok.ui.*;

abstract Link({
	public final url:String;

	public final props:{}

	public final children:Children;
}) {
	@:fromMarkup
	@:noUsing
	@:noCompletion
	public static function fromMarkup(props:GlobalAttr & {to:String}, ...children:Child) {
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

	public inline function attr(name:HtmlAttributeName, value:ReadOnlySignal<String>) {
		Reflect.setField(this.props, name, value);
	}

	public inline function child(...children:Child) {
		for (child in children) if (child.type == Fragment.componentType) {
			abstract.child(...child.getProps().children);
		} else {
			this.children.push(child);
		}
		return abstract;
	}

	@:to
	public function node():Child {
		return LinkWrapper.node({
			url: this.url,
			child: context -> {
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
			}
		});
	}

	@:to
	public inline function toChildren():Children {
		return node();
	}
}

class LinkWrapper extends Component {
	@:attribute final url:String;
	@:attribute final child:(context:View) -> Child;

	#if !blok.client
	function setup() {
		RouteVisitor
			.maybeFrom(this)
			.inspect(visitor -> visitor.enqueue(url));
	}
	#end

	function render() {
		return child(this);
	}
}
