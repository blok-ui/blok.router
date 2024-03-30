package blok.router;

import blok.html.Html;
import blok.ui.*;

class Link extends Component {
  public static function to(url) {
    return new VLink(url);
  }

  @:attribute final url:String;
  @:attribute final className:String = null;
  @:children @:attribute final children:Children;

  #if !blok.client
  function setup() {
    RouteVisitor
      .maybeFrom(this)
      .inspect(visitor -> visitor.enqueue(url));
  }
  #end

  public function render():Child {
    var node = Html.a()
      .attr('href', url)
      .attr(ClassName, className)
      .child(children);

    switch Navigator.maybeFrom(this) {
      case Some(nav):
        // @todo: This needs to be configurable -- we won't
        // always want to intercept it.
        node.on(Click, e -> {
          e.preventDefault();
          nav.go(url);
        });
      case None:
    }

    return node;
  }
}

abstract VLink({
  public final url:String;
  public final ?className:String;
  public final children:Children;
}) {
  public inline function new(url) {
    this = {
      url: url,
      children: []
    };
  }

  public inline function child(child:Child) {
    this.children.push(child);
    return abstract;
  }

  @:to
  public inline function node():Child {
    return Link.node({
      url: this.url,
      className: this.className,
      children: this.children
    });
  }
}
