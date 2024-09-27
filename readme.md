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

## RouteComponent

A `RouteComponent` mixes the functionality of a `Route` and a `Component`, as its name might suggest. Here's a simple example:

```haxe
class HelloLocation extends RouteComponent<'/hello/{location:String}'> {
  function render() {
    return Html.p()
      .child('Hello')
      // The "{location:String}" segment in the route is automatically 
      // added to the RouteComponent as a signal, much as if you wrote
      // `@:signal final location:String`.
      .child(location());
  }
}
```

Here's a more complex example from a notional blog site showing how `RouteComponents` can use standard Component features like `@:context` and `@:resource` and even `@:attribute`:


```haxe
class PostPage extends RouteComponent<'/post/{id:String}'> {
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

RouteComponents can be registered using their `.route` static method or using the `view` macro.

```haxe
Html.view(<Router>
  <HelloLocation />
  // Note that we need to set the `category` attribute here. 
  <PostPage category="default" />
  <fallback>{_ -> "Route not found"}</fallback>
</Router>);
// Or:
Router.node({
  routes: [
    HelloLocation.route({}),
    PostPage.route({category: 'default'})
  ],
  fallback: _ -> 'Route not found'
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
          ],
          fallback: _ -> 'Not found'
        })
      ));
  }
}
```

No checks are done to ensure that your `Link` is actually pointed to a valid URL, which is not ideal. However Blok Router *does* have a solution for this, and all Routes and RouteComponents come with a `link` static method that will generate correct Links for you:

```haxe
typedef Home = Route<'/'>;
typedef FooBar = Route<'/foo/{bar:String}'>;

// Creating links from the above:
Home.link().child('Home');
FooBar.link({bar: 'Bar'}).child('Foo Bar');

// Using the examples we wrote in the `RouteComponent` section:
HelloLocation.link({location: 'World'}).child('Hello world');
PostPage.link({id: 'first-post'}).child('First post');
```

These methods unfortunately will not work with the `view` macro, but `Routes` and `RouteComponents` also have a `createUrl` method that can enforce some type safety:

```haxe
Html.view(<>
  <Link to={Home.createUrl()}>'Home'</Link>
  <Link to={FooBar.createUrl({bar: 'Bar'})}>'Foo Bar'</Link>
  // etc
</>)
```
