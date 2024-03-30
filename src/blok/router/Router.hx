package blok.router;

import blok.ui.*;

class Router extends Component {
  @:attribute final routes:Array<Matchable>;
  @:attribute final fallback:(url:String)->Child;

  function render():Child {
    var nav = Navigator.from(this);
    var url = nav.url();

    for (route in routes) switch route.match(url) {
      case Some(render): 
        return render();
      case None:
    }

    return fallback(url);
  }
}
