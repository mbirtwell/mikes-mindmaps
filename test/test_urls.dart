import "package:unittest/unittest.dart";
import "package:route/url_pattern.dart";
import "../server/urls.dart" as urls;

main () {
  test('index', () {
    expect(urls.index.matches('/'), isTrue);
    expect(urls.index.parse('/'), equals([]));
    expect(urls.index.reverse([]), equals('/'));
  });
  test('data stream', () {
    expect(urls.data.matches('/map/1234/data'), isTrue);
    expect(urls.data.parse('/map/1234/data'), equals(['1234']));
    expect(urls.data.reverse([1234]), equals('/map/1234/data'));
  });
}