import "dart:math";
import "package:unittest/unittest.dart";
import "../lib/hex_grid.dart";

main() {
  test('hex direction all lists the hex directions', () {
    expect(HexDirection.all, hasLength(6));
  });
  test('hex direction from name returns a hex direction', () {
    var hd = HexDirection.fromName('right');
    expect(hd, new isInstanceOf<HexDirection>(HexDirection));
    expect(hd.name, equals('right'));
  });
  test('hex direction from offset returns a hex direction', () {
    var hd = HexDirection.fromOffset(new Point(1, 0));
    expect(hd, new isInstanceOf<HexDirection>(HexDirection));
    expect(hd.name, equals('right'));
  });
  test('hex grid constructs cells on demand', () {
    var grid = new HexGrid();
    expect(grid[new Point(2, 3)].position, equals(new Point(2, 3)));
  });
  test('hex grid constructs cells which are empty', () {
    var grid = new HexGrid();
    expect(grid[new Point(2, 3)].state, equals(CellState.empty));
  });
  test('Modifing hex cells is remembered', () {
    var grid = new HexGrid();
    grid[new Point(1, 1)].add(new Point(0, 0));
    expect(grid[new Point(1, 1)].state, equals(CellState.adding));
  });
  test('hex grid generates neighbours in all directions', () {
    var grid = new HexGrid();
    var neighbourOffsets = grid
      .getNeighbours(new Point(0, 0))
      .map((cell) => cell.position);
    expect(neighbourOffsets, unorderedEquals(HexDirection.all.map((dir) => dir.offset)));
  });
}