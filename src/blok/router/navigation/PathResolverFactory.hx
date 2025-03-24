package blok.router.navigation;

using Reflect;

function createFromJson(json:{}):PathResolver {
	return switch json.field('type') {
		case 'HashPathResolver':
			new HashPathResolver(json.field('pathname'));
		case 'UrlPathResolver':
			new UrlPathResolver();
		default:
			new UrlPathResolver();
	}
}
