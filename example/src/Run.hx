import blok.*;
import blok.ErrorBoundary;
import blok.html.*;
import blok.router.*;
import blok.router.navigation.*;
import js.Browser;
import kit.Error.ErrorCode;

function main() {
	Client.mount(
		Browser.document.getElementById('root'),
		Html.view(<main>
			<Router navigator={new Navigator(
				new BrowserHistory(),
				new HashPathResolver(Browser.location.pathname)
			)}>
				<ErrorBoundary>
					<header>
						<Link to={Home.createUrl()}><h1>"Example"</h1></Link>
						<nav>
							<ul>
								<li><Link to="/test">'Test'</Link></li>
								<li><Link to="/other/foo">'foo'</Link></li>
								<li><Link to="/not-a-real-link">'foo'</Link></li>
								<li><Link to={TestTwo.createUrl({foo: 'foo'})}>'Test 2'</Link></li>
								<li><Link to={TestThree.createUrl({bar: 'Bin'})}>'Test 3'</Link></li>
							</ul>
						</nav>
					</header>

					<Match>
						<Home />
						<Route to="/test">{_ -> Html.div()
							.child(Home.link().child('Home'))
							.child(TestThree.link({bar:'Froob'}).child('Froob'))
							.child('Test')
						}</Route>
						// Note: `params` here are type checked!
						<Route to="/other/:thing">{params -> params.thing}</Route>
						<TestTwo title="Test Two" />
						<TestThree name="World" />
						// Note: Route order matters! A catch-all route (a route with the path "*") 
						// must come last or it will capture all routes.
						<NotFoundRoute />
					</Match>
					// Handle all other errors that might come up. 
					<fallback>
						{(error) -> <ErrorView code=InternalError>{error.message}</ErrorView>}
					</fallback>
				</ErrorBoundary>
			</Router>
		</main>)
	);
}

class Home extends Page<'/'> {
	function render() {
		return Html.view(<div>'Home'</div>);
	}
}

class TestTwo extends Page<'/test2/:foo'> {
	@:attribute final title:String;
	@:signal final testSignal:String = 'Ok';
	@:computed final foobar:String = foo() + ' bar';
	@:resource final test:String = 'foo'; // @todo: something better
	@:context final navigator:Navigator;

	public function render():Child {
		trace(navigator.location.peek().toString());
		return Html.view(<div>
			<h1>title</h1>
			<p>"The current value is:" {foo()} " and also " {foobar()}</p>
		</div>);
	}
}

class TestThree extends Page<'/test3/:bar/*more'> {
	@:attribute final name:String;

	function render():Child {
		return Html.div()
			.child(Html.h1().child('Test Three'))
			.child(Text.node('Hello ' + name + ' ' + bar()))
			.child(Match.of([
				Route.to('/').renders(_ -> Html.div().child(
					Html.ul().child(
						Html.li().child(
							// Paths in a Link can be relative!
							Link.to('./other/more').child('This is a sub route'),
						),
						Html.li().child(
							Link.to('./other/yams').child('This is also a sub route'),
						)
					)
				)),
				Route.to('/other/:more').renders(params -> Html.div().child(
					params.more,
					Link.to('../../').child('<- Back'),
					Link.to('../yams').child('yams'),
				)),
				// @todo: This does not get hit if we match too many segments.
				// Note sure why.
				NotFoundRoute.route({})
			]));
	}
}

class NotFoundRoute extends Page<'*url'> {
	function render() {
		return ErrorView.node({
			code: NotFound,
			children: [Text.ofString('Route not found: '), Text.ofSignal(url)]
		});
	}
}

class ErrorView extends Component {
	@:attribute final code:ErrorCode;
	@:children @:attribute final children:Children;

	function render() {
		return Html.div().child(
			Html.h3().child('Error: ${code}'),
			children
		);
	}
}
