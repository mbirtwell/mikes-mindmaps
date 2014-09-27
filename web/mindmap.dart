import 'dart:html';
import 'dart:convert';
import 'dart:math';
import 'dart:svg' as svg;
import 'lib/urls.dart' as urls;
import 'lib/map_node.dart';
import 'lib/hex_grid.dart';

int mapId;
int hexSize = 150;

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
  var cx = window.innerWidth/2 + p.x * 2 * ox * r + p.y * 1.5 * r * tan(30 * PI / 180);
  var cy = window.innerHeight/2 + p.y * 1.5 * r;
  return new Point(cx, cy);
}

insert(Element el, Point p) {
  querySelector('body').append(el);
  var c = calcCenter(p);
  el
    ..style.left = "${c.x - el.offsetWidth/2}px"
    ..style.top = "${c.y - el.offsetHeight/2}px"
  ;
}

main () {
  mapId = int.parse(urls.map.parse(window.location.pathname)[0]);
  querySelector('#idIndicator').text = mapId.toString();

  HttpRequest.getString('/map/$mapId/get').then((String json) {
    List<MindMapNode> nodes = JSON.decode(json).map((item) => new MindMapNode.fromMap(item));
    if(nodes.length == 0) {
      makeAddNodeForm(null, new Point(0, 0));
    } else {
      nodes.forEach((node) => makeNode(node));
    }
  });

  for(var x = -2; x < 3; ++x) {
    for(var y = -1; y < 2; ++y) {
      addHex(new Point(x, y));
    }
  }
}

makeNode(MindMapNode node) {
  var div = new DivElement()
    ..classes.add('node')
  ;
  for(var direction in HexDirection.all) {
    div.append(new ButtonElement()
      ..text = "+"
      ..classes.addAll(["node-plus", direction.name])
      ..onClick.listen((event) {
        makeAddNodeForm(node.position, node.position + direction.offset);
      })
    );
  }
  div.append(new SpanElement()..text = node.contents);
  insert(div, node.position);
  return div;
}

makeAddNodeForm(Point parent, Point position) {
  var addNodeForm = new FormElement()
    ..classes.add('addnode')
    ..action = '#'
    ..append(new TextAreaElement())
    ..append(new ButtonElement()
      ..classes.add('add')
      ..text = 'Add'
      ..onClick.listen((event) => addNode(event, parent, position))
    )
  ;
  insert(addNodeForm, position);
}

addNode(Event e, Point parent, Point position) {
  e.preventDefault();
  Element addNode = (e.target as Element).parent;
  TextAreaElement textInput = addNode.querySelector('textarea');
  textInput.setAttribute("disabled", "true");
  MindMapNode node = new MindMapNode(textInput.value, position, parent);
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