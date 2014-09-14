import "dart:async";
import "package:redis_client/redis_client.dart";

class Core {
  static Core instance;

  RedisClient redisClient;

  Core();

  static Future<Core> startUp(redisConnectionString) {
    instance = new Core();
    return RedisClient.connect(redisConnectionString).then((client) {
      instance.redisClient = client;
      return instance.redisClient.msetnx({"next_map_id": 1000});
    }).then((_) => instance);
  }

  Future<int> createMap() {
    return redisClient.incr("next_map_id");
  }

  Future<int> addNode(int mapId, String text) => new Future.value(100001);
}
