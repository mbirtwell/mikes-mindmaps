import "package:unittest/unittest.dart";
import "package:route/url_pattern.dart";
import '../lib/urls.dart' as urls;


class UrlPathMatches extends CustomMatcher
{
  String _examplePath;
  UrlPathMatches(examplePath):
    super('url matches example path $examplePath', 'url path', isTrue),
    _examplePath = examplePath;

  featureValueOf(UrlPattern actual) => actual.matches(_examplePath);
}


class UrlParsesToArgs extends CustomMatcher
{
  String _examplePath;
  UrlParsesToArgs(examplePath, exampleArgs):
    super('url args from $examplePath', 'url args', equals(exampleArgs)),
    _examplePath = examplePath;

  featureValueOf(UrlPattern actual) => actual.parse(_examplePath);
}


class UrlReversesFromArgs extends CustomMatcher
{
  List<String> _exampleArgs;
  UrlReversesFromArgs(exampleArgs, examplePath):
    super('url path from $exampleArgs', 'url path', equals(examplePath)),
    _exampleArgs = exampleArgs;

  featureValueOf(UrlPattern actual) => actual.reverse(_exampleArgs);
}


urlMatcher (examplePath, [exampleArgs]) {
  if(exampleArgs == null) {
    exampleArgs = [];
  }
  return allOf(new UrlPathMatches(examplePath),
               new UrlParsesToArgs(examplePath, exampleArgs),
               new UrlReversesFromArgs(exampleArgs, examplePath));

}


main () {
  test('index', () {
    expect(urls.index, urlMatcher('/'));
  });
  test('create map', () {
    expect(urls.create, urlMatcher('/map/create'));
  });
  test('map', () {
    expect(urls.map, urlMatcher('/map/1234', ['1234']));
  });
  test('data stream', () {
    expect(urls.data, urlMatcher('/map/1234/data', ['1234']));
  });
}