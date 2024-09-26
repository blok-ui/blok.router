import blok.context.*;
import blok.html.*;
import blok.router.*;
import blok.ui.*;
import js.Browser;

function main() {
	// var routes = [
	// 	new Route<'/'>(_ -> Html.div()
	// 		.child('Home')
	// 		.child(Link.to('/test').child('Test'))
	// 	),
	// 	new Route<'/test'>(_ -> Html.div()
	// 		.child(Html.view(<Link url="/">"home"</Link>))
	// 		.child('Test')
	// 	),
	// 	Route.to('/other/{thing:String}')
	// 		.renders(params -> params.thing)
	// ];
	Client.mount(
		Browser.document.getElementById('root'),
		() -> Provider
			.provide(() -> new Navigator({url: '/'}))
			.child(_ -> Html.view(<Router>
				<Route to="/">{_ -> <div>
					'Home'
					<Link to="/test">'Test'</Link>
					<Link to="/other/foo">'foo'</Link>
					<Link to="/test2/foo">'Test 2'</Link>
					<Link to="/test3/foo">'Test 3'</Link>
				</div>}</Route>
				<Route to="/test">{_ -> <div>
					<Link to="/">"home"</Link>
					'Test'
				</div>}</Route>
				// Note: `params` here are type checked!
				<Route to="/other/{thing:String}">{params -> params.thing}</Route>
				<TestTwo title="Test Two" />
				<TestThree name="World" />
				<fallback>{url -> <p>'No routes found for ' {url}</p>}</fallback>
			</Router>))
	);
}

class TestTwo extends RouteView<'/test2/{foo:String}'> {
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

class TestThree extends RouteView<'/test3/{bar:String}'> {
	@:attribute final name:String;

	function render():Child {
		return Text.node('Hello ' + name + ' ' + bar());
	}
}
