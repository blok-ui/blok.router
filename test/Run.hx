import blok.router.*;
import blok.router.path.*;

function main() {
	Runner
		.fromDefaults()
		.add(PathParserSuite)
		.add(MatchSuite)
		.run();
}
