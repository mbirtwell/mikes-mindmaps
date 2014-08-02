import "package:unittest/unittest.dart";
import '../lib/http_dispatch.dart';

class Match404ForResource extends Matcher
{
  String resource;

  Match404ForResource(String this.resource);

  matches(item, matchState) {
    if(! item is Http404)
      return false;
    return item.resource == this.resource;
  }

  describe(Description desc) {
    desc.add("is a Http404 exception with resource ${resource}");
  }

  describeMismatch(item, Description mmDesc, state, verbose) {
    if(item is Http404)
      mmDesc.add("actual resource ${item.resource}");
    return mmDesc;
  }
}

main () {
  test("construct http dispatch", () {
    expect(new HttpDispatch(), new isInstanceOf(HttpDispatch));
  });
  test("construct http dispatch 2", () {
    expect(new HttpDispatch(), new isInstanceOf(HttpDispatch));
  });
  group("Url match tests", () {
    HttpDispatch dispatch;
    setUp(() => dispatch = new HttpDispatch());
    tearDown(() => dispatch = null);
    test("Empty urllist", () {
      expect(() => dispatch.resolve('/'), throwsA(new Match404ForResource('/')));
    });
    test("Add Handler", () {
      dispatch.addHandler(new RegExp(r"^$"), (request) => null);
      expect(dispatch.urls, hasLength(equals(1)));
    });
    test("Resolve Handler", () {
      var handler = (request) => null;
      dispatch.addHandler(new RegExp(r"^/$"), handler);
      expect(dispatch.resolve("/"), same(handler));
    });
  });
}
