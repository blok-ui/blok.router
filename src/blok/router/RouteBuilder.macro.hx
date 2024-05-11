package blok.router;

import blok.macro.*;
import haxe.macro.Context;
import haxe.macro.Expr;
import kit.macro.*;

using blok.router.RouteTools;
using kit.Hash;
using kit.macro.Tools;

function buildGeneric() {
  return switch Context.getLocalType() {
    case TInst(_, [ TInst(_.get() => {kind: KExpr(macro $v{(url:String)})}, _) ]):
      buildRoute(url.normalizeUrl());
    default:
      throw 'assert';
  }
}

function buildRoute(url:String) {
  var suffix = url.hash();
  var pos = Context.getLocalClass().get().pos;
  var pack = [ 'blok', 'router' ];
  var name = 'Route_${suffix}';
  var path:TypePath = { pack: pack, name: name, params: [] };

  if (path.typePathExists()) return TPath(path);
  
  var fields = new ClassFieldCollection([]);
  var route = url.processRoute();
  var routeParamsType = route.paramsType;
  var renderType = macro:(params:$routeParamsType)->blok.ui.Child;
  
  fields.add(macro class {
    static final matcher = ${route.matcher};
  
    public static function createUrl(props:$routeParamsType):String {
      return ${route.urlBuilder};
    }

    public static function link(props:$routeParamsType) {
      return blok.router.Link.to(createUrl(props));
    }

    final render:$renderType;

    public function new(render) {
      this.render = render;
    }

    public function match(url:String):kit.Maybe<()->blok.ui.Child> {
      if (matcher.match(url)) {
        return Some(() -> render(${route.paramsBuilder}));
      }
      return None;
    }
  });

  Context.defineType({
    pack: pack,
    name: name,
    pos: pos,
    meta: [],
    kind: TDClass(null, [
      {
        pack: ['blok', 'router'],
        name: 'Matchable'
      }
    ], false, true, false),
    fields: fields.export()
  });

  return TPath(path);
}
