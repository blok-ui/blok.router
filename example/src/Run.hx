import blok.context.*;
import blok.html.*;
import blok.router.*;
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
			.child(_ -> Html.view(<Router fallback={_ -> 'No routes found'}>
				<Route to="/">{_ -> <div>
					'Home'
					<Link url="/test">'Test'</Link>
					<Link url="/other/foo">'foo'</Link>
				</div>}</Route>
				<Route to="/test">{_ -> <div>
					<Link url="/">"home"</Link>
					'Test'
				</div>}</Route>
				<Route to="/other/{thing:String}">{params -> params.thing}</Route>
			</Router>))
	);
}
