import "dart:math";

import "package:unittest/unittest.dart";
import "package:redis_client/redis_client.dart";

import "../server/core.dart";
import "../lib/map_node.dart";


main () {
  Core core;
  setUp(() {
    return new Core().connect("192.168.33.10:6379").then((core) {
      return core.redisClient.select(1).then((_) {
        return core.redisClient.flushdb();
      }).then((_) {
        return core.initData();
      });
    }).then((core_){
      core = core_;
    });
  });
  tearDown(() {
    return core.close().then((_) {
      core = null;
    });
  });
  test('add map', () {
    core.createMap().then(expectAsync((res) {
      expect(res, equals(1001));
    }));
  });
  test('add node extends mindmap with node data', () {
    var node = new MindMapNode("herbs", new Point(0, 0), null);
    core.addNode(1001, node).then(expectAsync((res) {
      return core.redisClient.lrange("map/1001");
    })).then(expectAsync((mapStored) {
      expect(mapStored, isList);
      expect(mapStored, hasLength(1));
      expect(new MindMapNode.fromMap(mapStored[0]), equals(node));
    }));
  });
}