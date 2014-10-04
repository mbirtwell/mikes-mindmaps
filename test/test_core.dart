import "dart:math";
import "dart:async";

import "package:unittest/unittest.dart";
import "package:redis_client/redis_client.dart";

import "../server/core.dart";
import "../lib/map_node.dart";


main () {
  Core core;
  setUp(() {
    core = new Core();
    var setupMainClient = core.connect("192.168.33.10:6379").then((core) {
      return core.redisClient.select(1).then((_) {
        return core.redisClient.flushdb();
      }).then((_) {
        return core.initData();
      });
    });
    var setupSubscribeClient = core.connectSubscribeChannel("192.168.33.10:6379");
    return Future.wait([setupMainClient, setupSubscribeClient]);
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
    var node = new MindMapNode(new Point(0, 0), null, "herbs");
    core.addNode(1001, node).then(expectAsync((res) {
      return core.redisClient.lrange("map/1001");
    })).then(expectAsync((mapStored) {
      expect(mapStored, isList);
      expect(mapStored, hasLength(1));
      expect(new MindMapNode.fromMap(mapStored[0]), equals(node));
    }));
  });
  test('retrieve an non-existant mind map', () {
    core.getMindMap(1001).then(expectAsync((nodes) {
      expect(nodes, equals([]));
    }));
  });
  test('retrieve a mind map with a couple of items', (){
    var nodes = [
      new MindMapNode(new Point(0, 0), null, 'node1'),
      new MindMapNode(new Point(0, 1), new Point(0, 0), 'node2'),
    ];
    return core.redisClient.rpush('map/1001', nodes.map((node) => node.toMap())).then((_) {
      return core.getMindMap(1001);
    }).then((result) {
      expect(result, equals(nodes));
    });
  });
  test('add node to mindmap is signalled to subscription', () {
    var node = new MindMapNode(new Point(0, 1), new Point(0, 0), "node");
    core.subscribeToMindMap(1001).listen(expectAsync((update) {
      expect(update, equals(node));
    }));
    core.addNode(1001, node);
  });
}