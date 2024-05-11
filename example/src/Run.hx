import blok.context.*;
import blok.html.*;
import blok.router.*;
import js.Browser;

function main() {
  var routes = [
    new Route<'/'>(_ -> Html.div()
      .child('Home')
      .child(Link.to('/test').child('Test'))
    ),
    new Route<'/test'>(_ -> Html.div()
      .child(Html.view(<Link url="/">"home"</Link>))
      .child('Test')
    )
  ];

  Client.mount(
    Browser.document.getElementById('root'),
    () -> Provider
      .provide(() -> new Navigator({ url: '/' }))
      .child(_ -> Router.node({
        routes: routes,
        fallback: _ -> 'No route found'
      }))
  );
}
