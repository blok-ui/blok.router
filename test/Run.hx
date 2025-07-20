import blok.router.parse.*;
import blok.router.*;

function main() {
	Runner
		.fromDefaults()
		.add(ParserSuite)
		.add(RoutePathSuite)
			// .add(PathSuite)
		.run();
}
