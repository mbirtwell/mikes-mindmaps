import "dart:math";
import "dart:convert";

class MindMapNode {
  String contents;
  Point position;
  Point parent;

  MindMapNode(this.position, this.parent, [this.contents]) {
    if(this.position == null) {
      throw new ArgumentError("Position must be set");
    }
    if(this.parent == null && this.position != new Point(0, 0)) {
      throw new ArgumentError("All non central points must have a parent");
    }
  }

  MindMapNode.fromMap(Map data):
    this(_pointFromMap(data['position']),
         _pointFromMap(data['parent']),
         data['contents']);

  MindMapNode.fromJson(String json): this.fromMap(JSON.decode(json));

  static Map _pointToMap(Point p) {
    if(p == null) {
      return null;
    }
    return {
      'x': p.x,
      'y': p.y,
    };
  }

  static _pointFromMap(Map m) {
    if(m == null) {
      return null;
    }
    return new Point(m['x'], m['y']);
  }

  toMap() {
    var data = {
        'contents': this.contents,
        'position': _pointToMap(this.position),
    };
    if(parent == null) {
      data['parent'] = null;
    } else {
      data['parent'] = _pointToMap(this.parent);
    }
    return data;
  }

  toJson() => JSON.encode(toMap());

  bool operator ==(Object other_) {
    // To work with unittest we must return false and not throw when
    // compared against other types
    if(other_ is! MindMapNode) {
      return false;
    }
    MindMapNode other = other_ as MindMapNode;
    return this.contents == other.contents &&
      this.position == other.position &&
      this.parent == other.parent;
  }

  get hashCode {
    return this.contents.hashCode ^ this.position.hashCode ^
        this.parent.hashCode;
  }

  String toString() {
    return "MindMapNode($position, $parent, $contents)";
  }
}
