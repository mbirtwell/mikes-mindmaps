import "dart:async";

class Core {
  static Core instance;

  Core();

  Future<int> createMap() => new Future.value(1001);

  Future<int> addNode(int mapId, String text) => new Future.value(100001);
}
