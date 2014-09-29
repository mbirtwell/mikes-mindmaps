import "dart:math";

import "map_node.dart";

class HexDirection {
  final Point offset;
  final String name;

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


class CellState {

  final String name;

  CellState._(this.name) {}

  static final CellState empty = new CellState._('empty');
  static final CellState adding = new CellState._('adding');
  static final CellState full = new CellState._('full');
}


class HexCell {
  final Point position;
  CellState _state;
  MindMapNode _node;

  HexCell(this.position): _state = CellState.empty;

  get state => _state;
  get node => _node;

  MindMapNode add(Point parent) {
    assert(_state == CellState.empty);
    _state = CellState.adding;
    _node = new MindMapNode(this.position, parent);
    return _node;
  }

  fill(MindMapNode node) {
    assert(_state == CellState.empty);
    _state = CellState.full;
    _node = node;
  }
}


class HexGrid {
  Map<Point, HexCell> _cells = {};

  HexCell operator [] (Point p) {
    return _cells.putIfAbsent(p, () => new HexCell(p));
  }

  Iterable<HexCell> getNeighbours(Point center) {
    return HexDirection.all.map((dir) => this[center + dir.offset]);
  }

}