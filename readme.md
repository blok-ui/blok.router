# Blok Router

Simple routing for Blok.

## Defining Routes

Defining routes is simple, and can be done using Blok's `view` macro or vanilla Haxe code:

```haxe
class Root extends Component {
  function render() {
    return Html.view(<Router>
      <Route to="/">{_ -> <p>"This is the home route"</p>}</Route>
      <Route to="/foo/{bar:String}">{params -> <p>{params.bar}</p>}</Route>
      <fallback>{_ -> "Route not found"}</fallback>
    </Router>);
    // or:
    return Router.node({
      routes: [
        Route.to('/').renders(_ -> Html.p().child('This is the home route')),
        Route.to('/foo/{bar:String}').renders(params -> Html.p().child(params.bar))
      ],
      fallback: _ -> "Route not found"
    });
  }
}
```

Use whichever you prefer.

> More to come
