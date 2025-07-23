# Blok Router

Simple routing for Blok.

## Defining Routes

Defining routes is simple, and can be done using Blok's `view` macro or vanilla Haxe code:

```haxe
class Routes extends Component {
  function render() {
    return Html.view(<Router>
      <Match>
        <Route to="/">{_ -> <p>"This is the home route"</p>}</Route>
        <Route to="/foo/:bar">{params -> <p>{params.bar}</p>}</Route>
        <Route to="*">{_ -> "Route not found"}</Route>
      </Match>
    </Router>);
    // or:
    return Router.node({
      children: Match.of([
        Route.to('/').renders(_ -> Html.p().child('This is the home route')),
        Route.to('/foo/:bar').renders(params -> Html.p().child(params.bar)),
        Route.to('*').renders(_ -> "Route not found")
      ])
    });
  }
}
```

Use whichever you prefer.

The `Router` component is optional, but acts as a place to configure routing in your app and it's generally good practice to have one at the root of your app.

To configure your Router, you can provide a `Navigator`. For example, if you wanted to create a router for the browser that uses the hash instead of the full url, this is how you'd configure things:

```haxe
Html.view(<Router navigator={new blok.router.Navigator(
  new blok.router.navigation.BrowserHistory(),
  new blok.router.navigation.HashPathResolver()
)}></Router>);
```

The `Match` component is where your Routes should go. If a `Match` component doesn't match a route, it will throw a RouteNotFoundException. This can be caught using an ErrorBoundary, or you can define a wildcard route (any route with a '*' path) to handle invalid URLs.

```haxe
// Using an ErrorBoundary:
Html.view(<Router>
  <ErrorBoundary>
    <Match>
      <Route to="/">{_ -> <p>"This is the home route"</p>}</Route>
    </Match>
    <fallback>{e -> if (e is RouteNotFoundException) {
      'Route not found';
    else {
      'Internal Error';
    }}</fallback>
  </ErrorBoundary>
</Router>);
```

Matches can also be nested inside Routes, where they can allow nested routing:

```haxe
Html.view(<Router>
  <Match>
    // Note the wildcard on the end of the Route here (the "*") -- this is
    // required for sub-routing to work. Everything in the path after
    // "/foo/" will be used to match the sub-routes. 
    <Route to="/foo/*">
      {_ -> <Match>
        <Route to="/sub/:value">{params -> params.value}</Route>
        <Route to="*url">{params -> 'Not found: ${params.url}'}</Route>
      </Match>}
    </Route>
  </Match>
</Router>);
```

Routes use a simple syntax that should be familiar if you've used any similar libraries. Here's a quick overview:

```haxe
// A route with no params:
"foo/bar";
// A route with required params:
"foo/:bar/bin";
// A route with an optional segment:
"foo/(optional/:bar)/:etc";
// A route with a wildcard:
"foo/bar/*";
// A route with a named wildcard (which will pass it as a param to the route):
"foo/bar/*more";
```

> Note: this syntax is currently undergoing changes and is too unstable to document right now. Use at your own risk. 

## Page

A `Page` mixes the functionality of a `Route` and a `Component`. Here's a simple example:

```haxe
class HelloLocation extends Page<'/hello/:location'> {
  function render() {
    return Html.p()
      .child('Hello')
      // The ":location" segment in the route is automatically 
      // added to the Page as a signal, much as if you wrote
      // `@:signal final location:String`.
      .child(location());
  }
}
```

Here's a more complex example from a notional blog site showing how `Pages` can use standard Component features like `@:context` and `@:resource` and even `@:attribute`:

```haxe
class PostPage extends Page<'/post/:id'> {
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
  <Match>
    <HelloLocation />
    // Note that we need to set the `category` attribute here. 
    <PostPage category="default" />
  </Match>
</Router>);
// Or:
Router.node({
  children: Match.wrap([
    HelloLocation.route({}),
    PostPage.route({category: 'default'})
  ])
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
        Match.wrap([
          Route.to('/').renders(_ -> 'Home'),
          Route.to('/foo/:bar[String]').renders(props -> 'Foo ' + props.bar)
        ])
      ));
  }
}
```

Links can also use relative paths, which can be convenient when dealing with nested routes.

```haxe
Html.view(<Match>
  <Route to="/foo/bar/:foo/*">{_ -> <Match>
    <Route to="/:bin">{params -> <div>
      <p>{params.bin}</p>
      <Link to="../">"This will create a link relative to the enclosing Route"</Link>
    </div>}</Route>
  </Match>}
</Match>);
```

No checks are done to ensure that your `Link` is actually pointed to a valid URL, which is not ideal. However Blok Router *does* have a solution for this, and all Routes and Pages come with a `link` static method that will generate correct Links for you:

```haxe
typedef Home = Route<'/'>;
typedef FooBar = Route<'/foo/:bar'>;

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
