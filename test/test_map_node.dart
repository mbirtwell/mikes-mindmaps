import "dart:convert";
import "dart:math";
import "package:unittest/unittest.dart";

import "../lib/map_node.dart";

main () {
  test('constructed central map node has expected attributes', () {
    var node = new MindMapNode(new Point(0, 0), null, "contents");
    expect(node.contents, equals("contents"));
    expect(node.position, equals(new Point(0, 0)));
    expect(node.parent, isNull);
  });
  test('constructed map node has expected attributes', () {
    var node = new MindMapNode(new Point(1, 0), new Point(0, 0), "contents");
    expect(node.contents, equals("contents"));
    expect(node.position, equals(new Point(1, 0)));
    expect(node.parent, equals(new Point(0, 0)));
  });
  test('node compares equal with itself', () {
    var node = new MindMapNode(new Point(1, 0), new Point(0, 0), "contents");
    expect(node == node, isTrue);
  });
  test('identically contstructed nodes compare equal', () {
    var node1 = new MindMapNode(new Point(1, 0), new Point(0, 0), "contents");
    var node2 = new MindMapNode(new Point(1, 0), new Point(0, 0), "contents");
    expect(node1 == node2, isTrue);
  });
  test("nodes with different content don't compare equal", () {
    var node1 = new MindMapNode(new Point(1, 0), new Point(0, 0), "contents 1");
    var node2 = new MindMapNode(new Point(1, 0), new Point(0, 0), "contents");
    expect(node1 == node2, isFalse);
  });
  test("nodes with different positions don't compare equal", () {
    var node1 = new MindMapNode(new Point(1, 0), new Point(0, 0), "contents");
    var node2 = new MindMapNode(new Point(1, -1), new Point(0, 0), "contents");
    expect(node1 == node2, isFalse);
  });
  test("nodes with different parents don't compare equal", () {
    var node1 = new MindMapNode(new Point(1, 0), new Point(0, 0), "contents");
    var node2 = new MindMapNode(new Point(1, 0), new Point(1, 1), "contents");
    expect(node1 == node2, isFalse);
  });
  test("from json constructor loads the data", () {
    var node = new MindMapNode.fromJson('{"contents": "some contents", "position": {"x": 1, "y": 0}, "parent": {"x": 0, "y": 0}}');
    expect(node, equals(new MindMapNode(new Point(1, 0), new Point(0, 0), "some contents")));
  });
  test("from json constructor loads the data with null parent", () {
    var node = new MindMapNode.fromJson('{"contents": "some contents", "position": {"x": 0, "y": 0}, "parent": null}');
    expect(node, equals(new MindMapNode(new Point(0, 0), null, "some contents")));
  });
  test("to json contains the expected data", () {
    var node = new MindMapNode(new Point(1, 0), new Point(0, 0), "contents");
    expect(JSON.decode(node.toJson()), equals({
      'contents': 'contents',
      'position': {'x': 1, 'y': 0},
      'parent': {'x': 0, 'y': 0},
    }));
  });
  test("to json contains the expected data with null parent", () {
    var node = new MindMapNode(new Point(0, 0), null, "contents");
    expect(JSON.decode(node.toJson()), equals({
        'contents': 'contents',
        'position': {'x': 0, 'y': 0},
        'parent': null,
    }));
  });
}