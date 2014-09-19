
import "package:unittest/unittest.dart";
import "package:redis_client/redis_client.dart";

import "../server/core.dart";


main () {
  var core;
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
  test('add node extends', () {
    core.addNode(1001, "herbs").then(expectAsync((res) {
      expect(res, new isInstanceOf<int>());
    }));
  });
  test('redis client', () {
    RedisClient.connect("192.168.33.10:6379").then(expectAsync((RedisClient client) {
      client.lrange('test', startingFrom: 0, endingAt: 2).then(expectAsync((result) {
        expect(result, equals(["entry 2", "entry 1"]));
        client.close();
      }));
    }));
  });
}