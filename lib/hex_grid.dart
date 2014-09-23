import "dart:math";

class HexDirection {
  Point offset;
  String name;

  HexDirection._(this.name, int x, int y): offset = new Point(x, y) {}

  static List<HexDirection> all = [
    new HexDirection._('left', -1, 0),
    new HexDirection._('top-left', 0, -1),
    new HexDirection._('top-right', 1, -1),
    new HexDirection._('right', 1, 0),
    new HexDirection._('bottom-left', -1, 1),
    new HexDirection._('bottom-right', 0, 1),
  ];

  static _makeFromNameMap() {
    Map map = new Map();
    for(var hd in HexDirection.all) {
      map[hd.name] = hd;
    }
    return map;
  }

  static Map _fromNameMap = _makeFromNameMap();
  static HexDirection fromName(String name) => _fromNameMap[name];

  static _makeFromOffsetMap() {
    Map map = new Map();
    for(var hd in HexDirection.all) {
      map[hd.offset] = hd;
    }
    return map;
  }
  static Map _fromOffsetMap = _makeFromOffsetMap();
  static HexDirection fromOffset(Point offset) => _fromOffsetMap[offset];


  String toString() {
    return "HexDirection(${this.name})";
  }
}