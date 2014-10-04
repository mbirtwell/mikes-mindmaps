import "dart:async";
import "dart:convert";
import "package:redis_client/redis_client.dart";

import "../lib/map_node.dart";

class Core {
  static Core instance;

  RedisClient redisClient;
  RedisClient subscribeClient;

  Core();

  static Future<Core> startUp(String redisConnectionString) {
    Core core = new Core();
    Future mainConnect = core.connect(redisConnectionString).then((core){
      return core.initData();
    });
    Future subscribeConnect = core.connectSubscribeChannel(redisConnectionString);
    return Future.wait([mainConnect, subscribeConnect]).then((_) {
      instance = core;
      return core;
    });
  }

  Future<Core> connect(String redisConnectionString) {
    print("Connecting to redis $redisConnectionString");
    return RedisClient.connect(redisConnectionString).then((client) {
      print("Connected to redis");
      this.redisClient = client;
      return this;
    });
  }

  connectSubscribeChannel(String redisConnectionString) {
    print("Connecting subscribe client to redis $redisConnectionString");
    return RedisClient.connect(redisConnectionString).then((client) {
      print("Connected subscribe client to redis");
      this.subscribeClient = client;
      return this;
    });
  }

  Future<Core> initData() {
    print("Setting up default data");
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

  Future addNode(int mapId, MindMapNode node) {
    return Future.wait([
      redisClient.rpush('map/$mapId', [node.toMap()]),
      redisClient.publish('map/$mapId', JSON.encode(node.toMap())),
  ]);
  }

  Future<List<MindMapNode>> getMindMap(int mapId) {
    return redisClient.lrange('map/$mapId').then((results) {
      return results.map((item) => new MindMapNode.fromMap(item));
    });
  }

  Stream<MindMapNode> subscribeToMindMap(int mapId) {
    StreamController<MindMapNode> sc = new StreamController();
    subscribeClient.subscribe(['map/$mapId'], (Receiver message) {
      message.receiveMultiBulkStrings().then((val) {
        if(val[0] == "message" && val[1] == 'map/$mapId') {
          sc.sink.add(new MindMapNode.fromJson(val[2]));
        }
      });
    });
    return sc.stream;
  }
}
