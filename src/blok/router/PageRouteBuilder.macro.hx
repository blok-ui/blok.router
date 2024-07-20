package blok.router;

import blok.macro.*;
import haxe.macro.Context;
import haxe.macro.Expr;
import kit.macro.*;
import kit.macro.step.*;

using blok.router.RouteTools;
using kit.Hash;
using kit.macro.Tools;

final factory = new ClassBuilderFactory([
	new ConstantFieldBuildStep(),
	new ComputedFieldBuildStep(),
	new SignalFieldBuildStep({
		updatable: false
	}),
	new ResourceFieldBuildStep(),
	new ConstructorBuildStep({
		customParser: options -> {
			var propType = options.props;
			return (macro function(props:$propType) {
				${options.inits};
				var prevOwner = blok.core.Owner.setCurrent(owner);
				try ${options.lateInits} catch (e) {
					blok.core.Owner.setCurrent(prevOwner);
					throw e;
				}
				blok.core.Owner.setCurrent(prevOwner);
				${
					switch options.previousExpr {
						case Some(expr): macro blok.signal.Observer.untrack(() -> $expr);
						case None: macro null;
					}
				}
			}).extractFunction();
		}
	})
]);

function buildGeneric() {
	return switch Context.getLocalType() {
		case TInst(_, [TInst(_.get() => {kind: KExpr(macro $v{(url : String)})}, _)]):
			buildPageRoute(url.normalizeUrl());
		default:
			throw 'assert';
	}
}

function buildPageRoute(url:String) {
	var suffix = url.hash();
	var pos = Context.getLocalClass().get().pos;
	var pack = ['blok', 'router'];
	var name = 'Route_${suffix}';
	var path:TypePath = {pack: pack, name: name, params: []};

	if (path.typePathExists()) return TPath(path);

	var fields = new ClassFieldCollection([]);

	fields.add(macro class {
		@:noCompletion
		var __context:blok.signal.Signal<Null<blok.ui.View>> = new blok.signal.Signal(null);

		function context():blok.ui.View {
			var context = __context.get();
			blok.debug.Debug.assert(context != null);
			return context;
		}

		public abstract function render():blok.ui.Child;
	});

	Context.defineType({
		pack: pack,
		name: name,
		pos: pos,
		meta: [
			{
				name: ':autoBuild',
				params: [macro blok.router.PageRouteBuilder.build($v{url})],
				pos: (macro null).pos
			}
		],
		kind: TDClass(null, [
			{
				pack: ['blok', 'router'],
				name: 'Matchable'
			}
		], false, false, true),
		fields: fields.export()
	});

	return TPath(path);
}

function build(url:String) {
	return factory
		.withSteps(new PageRouteBuilder(url))
		.fromContext()
		.export();
}

// @todo: Does this need to be a DisposableHost? I think Resources don't get
// disposed automatically?
class PageRouteBuilder implements BuildStep {
	public final priority:Priority = Late;

	final url:String;

	public function new(url) {
		this.url = url;
	}

	public function apply(builder:ClassBuilder) {
		var route = url.processRoute();
		var routeParamsType = route.paramsType;
		var update:Array<Expr> = [];
		var tp = builder.getTypePath();

		switch route.paramsType {
			case TAnonymous(fields):
				for (field in fields) {
					var name = field.name;
					var ct = switch field.kind {
						case FVar(t, _): t;
						default: throw 'assert';
					}

					update.push(macro this.$name.set(params.$name));
					builder.add(macro class {
						final $name:blok.signal.Signal<$ct> = new blok.signal.Signal(null);
					});
				}
			default:
				throw 'assert';
		}

		builder.add(macro class {
			@:fromMarkup
			@:noUsing
			@:noCompletion
			public static function fromMarkup(props):blok.router.Matchable {
				return new $tp(props);
			}

			static final matcher = ${route.matcher};

			final owner = new blok.core.Owner();

			public static function createUrl(props:$routeParamsType):String {
				return ${route.urlBuilder};
			}

			public static function link(props:$routeParamsType) {
				return blok.router.Link.to(createUrl(props));
			}

			public function match(url:String):kit.Maybe<() -> blok.ui.Child> {
				if (matcher.match(url)) {
					var params = ${route.paramsBuilder};
					@:mergeBlock $b{update};
					return Some(() -> blok.ui.Scope.wrap(context -> {
						__context.set(context);
						return render();
					}));
				}
				return None;
			}

			public function dispose() {
				owner.dispose();
			}
		});
	}
}
