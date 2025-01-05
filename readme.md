# Blok Router

Simple routing for Blok.

## Defining Routes

Defining routes is simple, and can be done using Blok's `view` macro or vanilla Haxe code:

```haxe
class Routes extends Component {
  function render() {
    return Html.view(<Router>
      <Route to="/">{_ -> <p>"This is the home route"</p>}</Route>
      <Route to="/foo/{bar:String}">{params -> <p>{params.bar}</p>}</Route>
      <Route to="*">{_ -> "Route not found"}</Route>
    </Router>);
    // or:
    return Router.node({
      routes: [
        Route.to('/').renders(_ -> Html.p().child('This is the home route')),
        Route.to('/foo/{bar:String}').renders(params -> Html.p().child(params.bar)),
        Route.to('*').renders(_ -> "Route not found")
      ]
    });
  }
}
```

Use whichever you prefer.

If a Router doesn't match a route, it will throw a RouteNotFoundException. This can be caught using an ErrorBoundary, or you can define a wildcard route (any route with a '*' path) to handle invalid URLs.

```haxe
// Using an ErrorBoundary:
Html.view(<ErrorBoundary>
  <Router>
    <Route to="/">{_ -> <p>"This is the home route"</p>}</Route>
  </Router>
  <fallback>{e -> if (e is RouteNotFoundException) {
    'Route not found';
  else {
    'Internal Error';
  }}</fallback>
</ErrorBoundary>);
```

## Page

A `Page` mixes the functionality of a `Route` and a `Component`. Here's a simple example:

```haxe
class HelloLocation extends Page<'/hello/{location:String}'> {
  function render() {
    return Html.p()
      .child('Hello')
      // The "{location:String}" segment in the route is automatically 
      // added to the Page as a signal, much as if you wrote
      // `@:signal final location:String`.
      .child(location());
  }
}
```

Here's a more complex example from a notional blog site showing how `Pages` can use standard Component features like `@:context` and `@:resource` and even `@:attribute`:

```haxe
class PostPage extends Page<'/post/{id:String}'> {
  @:attribute final category:String;
  @:context final posts:PostContext;
  @:resource final post = posts.get(category, id());

  function render() {
    return Html.div().child(
      Html.header().child(
        Html.h1().child(post().title)
      ),
      Html.div().child(
        post().content
      )
    );
  }
}
```

Pages can be registered using their `.route` static method or using the `view` macro.

```haxe
Html.view(<Router>
  <HelloLocation />
  // Note that we need to set the `category` attribute here. 
  <PostPage category="default" />
</Router>);
// Or:
Router.node({
  routes: [
    HelloLocation.route({}),
    PostPage.route({category: 'default'})
  ]
});
```

## Linking to routes

You can link to your routes using the `Link` view. When clicked, the link will update the nearest `Navigator` context which will in turn cause all dependent `Routers` to update. For example:

```haxe
class Root extends Component {
  function render() {
    return Provider
      .provide(() -> new Navigator({url: '/'}))
      .child(_ -> Html.div().child(
        Html.header().child(
          Link.to('/').child('Home'),
          Link.to('/foo/bar').child('Foo Bar'),
          // Using the view macro:
          Html.view(<Link to="/foo/bin">'Foo Bin'</Link>)
        ),
        Router.node({
          routes: [
            Route.to('/').renders(_ -> 'Home'),
            Route.to('/foo/{bar:String}').renders(props -> 'Foo ' + props.bar)
          ]
        })
      ));
  }
}
```

No checks are done to ensure that your `Link` is actually pointed to a valid URL, which is not ideal. However Blok Router *does* have a solution for this, and all Routes and Pages come with a `link` static method that will generate correct Links for you:

```haxe
typedef Home = Route<'/'>;
typedef FooBar = Route<'/foo/{bar:String}'>;

// Creating links from the above:
Home.link().child('Home');
FooBar.link({bar: 'Bar'}).child('Foo Bar');

// Using the examples we wrote in the `Page` section:
HelloLocation.link({location: 'World'}).child('Hello world');
PostPage.link({id: 'first-post'}).child('First post');
```

These methods unfortunately will not work with the `view` macro, but `Routes` and `Pages` also have a `createUrl` method that can enforce some type safety:

```haxe
Html.view(<>
  <Link to={Home.createUrl()}>'Home'</Link>
  <Link to={FooBar.createUrl({bar: 'Bar'})}>'Foo Bar'</Link>
  // etc
</>)
```
