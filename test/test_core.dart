import "package:unittest/unittest.dart";

import "../server/core.dart";

main () {
  setUp(() {
    Core.instance = new Core();
  });
  test('add map', () {
    Core.instance.createMap().then(expectAsync((res) {
      expect(res, new isInstanceOf<int>());
    }));
  });
  test('add node', () {
    Core.instance.addNode(1001, "herbs").then(expectAsync((res) {
      expect(res, new isInstanceOf<int>());
    }));
  });
}