import "dart:async";
import "package:redis_client/redis_client.dart";

import "../lib/map_node.dart";

class Core {
  static Core instance;

  RedisClient redisClient;

  Core();

  static Future<Core> startUp(String redisConnectionString) {
    return new Core().connect(redisConnectionString).then((core){
      return core.initData();
    }).then((core) {
      instance = core;
    });
  }

  Future<Core> connect(String redisConnectionString) {
    return RedisClient.connect(redisConnectionString).then((client) {
      this.redisClient = client;
      return this;
    });
  }

  Future<Core> initData() {
    return this.redisClient.msetnx({
      "next_map_id": 1000,
    }).then((_) => this);
  }

  Future close() {
    return this.redisClient.close();
  }

  Future<int> createMap() {
    return redisClient.incr("next_map_id");
  }

  Future<int> addNode(int mapId, MindMapNode node) {
    return redisClient.rpush('map/$mapId', [node.toMap()]);
  }

  Future<List<MindMapNode>> getMindMap(int mapId) {
    return redisClient.lrange('map/$mapId').then((results) {
      return results.map((item) => new MindMapNode.fromMap(item));
    });
  }
}
