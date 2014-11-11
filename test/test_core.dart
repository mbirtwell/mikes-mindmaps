import "dart:math";
import "dart:async";

import "package:unittest/unittest.dart";
import "package:redis_client/redis_client.dart";

import "../server/core.dart";
import "../lib/map_node.dart";


main () {
  Core core;
  setUp(() {
    print("\nSetup");
    expect(core, isNull);
    return new Core("192.168.33.10:6379").connect().then((core_) {
      return core_.redisClient.select(1).then((_) {
        return core_.redisClient.flushdb();
      }).then((_) {
        return core_.initData();
      }).then((_) {
        expect(core, isNull);
        core = core_;
        print("Setup done");
      });
    });
  });
  tearDown(() {
    return core.close().then((_) {
      core = null;
      print("TearDown done");
    });
  });
  test('add map', () {
    return core.createMap().then(expectAsync((res) {
      expect(res, equals(1001));
    }));
  });
  test('add node extends mindmap with node data', () {
    var node = new MindMapNode(new Point(0, 0), null, "herbs");
    return core.addNode(1001, node).then(expectAsync((res) {
      return core.redisClient.lrange("map/1001");
    })).then(expectAsync((mapStored) {
      expect(mapStored, isList);
      expect(mapStored, hasLength(1));
      expect(new MindMapNode.fromMap(mapStored[0]), equals(node));
    }));
  });
  test('retrieve an non-existant mind map', () {
    return core.getMindMap(1001).then(expectAsync((nodes) {
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
    print("TEST add node to mindmap is signalled to subscription");
    var node = new MindMapNode(new Point(0, 1), new Point(0, 0), "node");
    return core.subscribeToMindMap(1001).then((updateSubscription) {
      updateSubscription.stream.listen(expectAsync((update) {
        print("update in test");
        expect(update, equals(node));
      }, count:1, max:2));
    }).then((_) {
      core.addNode(1001, node);
    });
  });
  test('two subscriptions both get the data they expect', () {
    print("TEST two subscriptions both get the data they expect");
    var node1 = new MindMapNode(new Point(0, 1), new Point(0, 0), "node1");
    var node2 = new MindMapNode(new Point(0, 1), new Point(0, 0), "node2");
    return Future.wait([
      core.subscribeToMindMap(1001).then((updateSubscription) {
        print("subscribe 1");
        updateSubscription.stream.listen(expectAsync((update) {
          expect(update, equals(node1));
        }));
      }),
      core.subscribeToMindMap(1002).then((updateSubscription) {
        print("subscribe 2");
        updateSubscription.stream.listen(expectAsync((update) {
          expect(update, equals(node2));
        }));
      }),
    ]).then((_) {
      return core.addNode(1002, node2);
    }).then((_) {
      return core.addNode(1001, node1);
    });
  });
  test('two subscriptions both get the data they expect (interleaved adds)', () {
    print("TEST two subscriptions both get the data they expect (interleaved adds)");
    var node1 = new MindMapNode(new Point(0, 1), new Point(0, 0), "node1");
    var node2 = new MindMapNode(new Point(0, 1), new Point(0, 0), "node2");
    return Future.wait([
        core.subscribeToMindMap(1001).then((updateSubscription) {
          print("subscribe 1");
          updateSubscription.stream.listen(expectAsync((update) {
            expect(update, equals(node1));
          }));
        }),
        core.subscribeToMindMap(1002).then((updateSubscription) {
          print("subscribe 2");
          updateSubscription.stream.listen(expectAsync((update) {
            expect(update, equals(node2));
          }));
        }),
    ]).then((_) {
      return Future.wait([
          core.addNode(1002, node2),
          core.addNode(1001, node1),
      ]);
    });
  });
  test('two subscriptions two the same mind map both get data', () {
    print("TEST two same subscriptions start");
    var node1 = new MindMapNode(new Point(0, 1), new Point(0, 0), "node1");
    return new Future(() {
      print("Setup subscription one");
      return core.subscribeToMindMap(1001).then((updateSubscription) {
        print("Got subscription one");
        expect(updateSubscription.refNumber, equals(0));
        updateSubscription.stream.listen(expectAsync((update) {
          expect(update, equals(node1));
        }));
      });
    }).then((_) {
      print("Setup subscription two");
      return core.subscribeToMindMap(1001).then((updateSubscription) {
        print("Got subscription two");
        expect(updateSubscription.refNumber, equals(1));
        updateSubscription.stream.listen(expectAsync((update) {
          expect(update, equals(node1));
        }));
      });
    }).then((_) {
        print("addNode");
        core.addNode(1001, node1);
    });
  });
  test('subscription created after subscription closes works', () {
    // TODO
  });
}