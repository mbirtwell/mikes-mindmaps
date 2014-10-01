import 'dart:html';
import 'dart:convert';
import 'dart:math';
import 'dart:svg' as svg;
import 'lib/urls.dart' as urls;
import 'lib/map_node.dart';
import 'lib/hex_grid.dart';

int mapId;
int hexSize = 150;
HexGrid grid = new HexGrid();
BodyElement body;

addHex(Point p) {
  svg.SvgSvgElement svgEl = querySelector("svg.background");
  var hex = new svg.PolygonElement();
  hex.classes.add('wireframe');
  svgEl.append(hex);

  var r = hexSize;
  var ox = cos(30 * PI / 180);
  var c = calcCenter(p);
  hex.points
    ..appendItem(svgEl.createSvgPoint()..x = c.x ..y = c.y - r)
    ..appendItem(svgEl.createSvgPoint()..x = c.x + r * ox ..y = c.y - r/2)
    ..appendItem(svgEl.createSvgPoint()..x = c.x + r * ox ..y = c.y + r/2)
    ..appendItem(svgEl.createSvgPoint()..x = c.x ..y = c.y + r)
    ..appendItem(svgEl.createSvgPoint()..x = c.x - r * ox ..y =  c.y + r/2)
    ..appendItem(svgEl.createSvgPoint()..x = c.x - r * ox ..y =  c.y - r/2)
  ;

  svgEl.append(new svg.TextElement()
    ..setAttribute('x', c.x.toString())
    ..setAttribute('y', c.y.toString())
    ..text = "${p.x}, ${p.y}"
  );
}

Point calcCenter(Point p) {
  var r = hexSize;
  var ox = cos(30 * PI / 180);
  var cx = body.scrollWidth/2 + p.x * 2 * ox * r + p.y * 1.5 * r * tan(30 * PI / 180);
  var cy = body.scrollWidth/2 + p.y * 1.5 * r;
  return new Point(cx, cy);
}

insert(Element el, Point p) {
  body.append(el);
  var c = calcCenter(p);
  el
    ..style.left = "${c.x - el.offsetWidth/2}px"
    ..style.top = "${c.y - el.offsetHeight/2}px"
  ;
}

main () {
  body = querySelector('body');
  window.scrollTo((body.scrollWidth/2 - window.innerWidth/2).toInt(),
                  (body.scrollHeight/2 - window.innerHeight/2).toInt());
  mapId = int.parse(urls.map.parse(window.location.pathname)[0]);
  querySelector('#idIndicator').text = mapId.toString();

  HttpRequest.getString('/map/$mapId/get').then((String json) {
    List<MindMapNode> nodes = JSON.decode(json).map((item) => new MindMapNode.fromMap(item));
    if(nodes.length == 0) {
      makeAddNodeForm(null, new Point(0, 0));
    } else {
      nodes.forEach((node) {
        grid[node.position].fill(node);
        makeNode(node);
        if(node.parent != null)
          drawLine(node);
        removePlusButtons(node.position);
      });
    }
  });

//  for(var x = -2; x < 3; ++x) {
//    for(var y = -1; y < 2; ++y) {
//      addHex(new Point(x, y));
//    }
//  }
}

makeNode(MindMapNode node) {
  var wrapper = new DivElement()
    ..setAttribute('hex-cell-x', node.position.x.toString())
    ..setAttribute('hex-cell-y', node.position.y.toString())
    ..classes.add('nodeWrapper')
    ..append(new DivElement()
      ..classes.add('node')
      ..text = node.contents
      );
  for(var direction in HexDirection.all) {
    if (grid[node.position + direction.offset].state == CellState.empty) {
      wrapper.append(new ButtonElement()
        ..text = "+"
        ..classes.addAll(["add", "node-plus", direction.name])
        ..onClick.listen((event) {
        makeAddNodeForm(node.position, node.position + direction.offset);
      }));
    }
  }
  insert(wrapper, node.position);
}

drawLine(MindMapNode node) {
  svg.SvgSvgElement svgEl = querySelector("svg.background");
  var parentCenter = calcCenter(node.parent);
  var thisCenter = calcCenter(node.position);
  var line = new svg.LineElement()
    ..attributes = {
      'x1': parentCenter.x.toString(),
      'y1': parentCenter.y.toString(),
      'x2': thisCenter.x.toString(),
      'y2': thisCenter.y.toString(),
  }
    ..classes.add('mindmap-link')
  ;
  svgEl.append(line);
}

makeAddNodeForm(Point parent, Point position) {
  var addNodeForm;
  var node = grid[position].add(parent);
  addNodeForm = new FormElement()
    ..classes.add('addnode')
    ..action = '#'
    ..append(new TextAreaElement()
      ..setAttribute('placeholder', 'Add text here')
      ..onKeyPress.listen((event) {
        var keyEvent = new KeyEvent.wrap(event);
        if(keyEvent.keyCode == KeyCode.ENTER) {
          addNode(addNodeForm, node);
        }
      })
    )
    ..append(new ButtonElement()
      ..classes.add('add')
      ..text = '✔'
      ..onClick.listen((event) {
        event.preventDefault();
        addNode(addNodeForm, node);
      })
    )
  ;
  insert(addNodeForm, position);
  if(node.parent != null) {
    drawLine(node);
  }
  removePlusButtons(node.position);
}

addNode(Element addNode, MindMapNode node) {
  TextAreaElement textInput = addNode.querySelector('textarea');
  textInput.setAttribute("disabled", "true");
  node.contents = textInput.value;
  HttpRequest.request('/map/$mapId/add',
                      method: "POST",
                      mimeType: "application/json",
                      requestHeaders: {
                        'Content-Type': "application/json",
                      },
                      sendData: node.toJson()
                      ).then((req) {
    if(req.status != 200) {
      window.alert("error");
      return;
    }
    addNode.remove();
    makeNode(node);
  });
}

queryNodePlusButton(Point p, HexDirection d) {
  return querySelector('.nodeWrapper[hex-cell-x="${p.x}"][hex-cell-y="${p.y}"] .node-plus.${d.name}');
}

removePlusButtons(Point position) {
  for(var cell in grid.getNeighbours(position)) {
    if(cell.state != CellState.full) {
      continue;
    }
    var direction = HexDirection.fromOffset(position - cell.position);
    var button = queryNodePlusButton(cell.position, direction);
    button.remove();
  }
}