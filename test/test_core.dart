import "package:unittest/unittest.dart";
import "package:redis_client/redis_client.dart";

import "../server/core.dart";


main () {
  setUp(() {
    return Core.startUp("192.168.33.10:6379");
  });
  tearDown(() {
    return Core.instance.redisClient.close();
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
  test('redis client', () {
    RedisClient.connect("192.168.33.10:6379").then(expectAsync((RedisClient client) {
      client.lrange('test', startingFrom: 0, endingAt: 2).then(expectAsync((result) {
        expect(result, equals(["entry 2", "entry 1"]));
        client.close();
      }));
    }));
  });
}