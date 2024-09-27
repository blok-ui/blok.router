import blok.context.*;
import blok.html.*;
import blok.router.*;
import blok.ui.*;
import js.Browser;

function main() {
	Client.mount(
		Browser.document.getElementById('root'),
		() -> Provider
			.provide(() -> new Navigator({url: '/'}))
			.child(_ -> Html.view(<main>
				<header>
					<Link to={Home.createUrl()}><h1>"Example"</h1></Link>
					<nav>
						<ul>
							<li><Link to="/test">'Test'</Link></li>
							<li><Link to="/other/foo">'foo'</Link></li>
							<li><Link to={TestTwo.createUrl({foo: 'foo'})}>'Test 2'</Link></li>
							<li><Link to={TestThree.createUrl({bar: 'Bin'})}>'Test 3'</Link></li>
						</ul>
					</nav>
				</header>

				<Router>
					<Home />
					<Route to="/test">{_ -> Html.div()
						.child(Home.link().child('Home'))
						.child(TestThree.link({bar:'Froob'}).child('Froob'))
						.child('Test')
					}</Route>
					// Note: `params` here are type checked!
					<Route to="/other/{thing:String}">{params -> params.thing}</Route>
					<TestTwo title="Test Two" />
					<TestThree name="World" />
					<fallback>{url -> <p>'No routes found for ' {url}</p>}</fallback>
				</Router>
			</main>))
	);
}

class Home extends RouteComponent<'/'> {
	function render() {
		return Html.view(<div>'Home'</div>);
	}
}

class TestTwo extends RouteComponent<'/test2/{foo:String}'> {
	@:attribute final title:String;
	@:signal final testSignal:String = 'Ok';
	@:computed final foobar:String = foo() + ' bar';
	@:resource final test:String = 'foo'; // @todo: something better
	@:context final navigator:Navigator;

	public function render():Child {
		trace(navigator.url);
		return Html.view(<div>
			<h1>title</h1>
			<p>"The current value is:" {foo()} " and also " {foobar()}</p>
		</div>);
	}
}

class TestThree extends RouteComponent<'/test3/{bar:String}'> {
	@:attribute final name:String;

	function render():Child {
		return Text.node('Hello ' + name + ' ' + bar());
	}
}
