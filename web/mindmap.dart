import 'dart:html';
import 'dart:convert';
import 'dart:math';
import 'dart:svg' as svg;
import '/lib/urls.dart' as urls;

int mapId;
int hexSize = 150;

addHex(x, y) {
  svg.SvgSvgElement svgEl = querySelector("svg.background");
  var hex = new svg.PolygonElement();
  hex.classes.add('wireframe');
  svgEl.append(hex);

  var r = hexSize;
  var ox = cos(30 * PI / 180);
  var c = calcCenter(x, y);
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
    ..text = "$x, $y"
  );
}

Point calcCenter(int x, int y) {
  var r = hexSize;
  var ox = cos(30 * PI / 180);
  var cx = window.innerWidth/2 + x * 2 * ox * r + y * 1.5 * r * tan(30 * PI / 180);
  var cy = window.innerHeight/2 + y * 1.5 * r;
  return new Point(cx, cy);
}

insert(Element el, int x, int y) {
  querySelector('body').append(el);
  var c = calcCenter(x, y);
  el
    ..style.left = "${c.x - el.offsetWidth/2}px"
    ..style.top = "${c.y - el.offsetHeight/2}px"
  ;
}

main () {
  mapId = int.parse(urls.map.parse(window.location.pathname)[0]);
  querySelector('#idIndicator').text = mapId.toString();

  makeAddNodeForm(0, 0);

  for(var x = -2; x < 3; ++x) {
    for(var y = -1; y < 2; ++y) {
      addHex(x, y);
    }
  }
}

makeNode(text, x, y) {
  var div = new DivElement()
    ..classes.add('node')
  ;
  for(var posInfo in [
      ["left", -1, 0],
      ["top-left", 0, -1],
      ["top-right", 1, -1],
      ["right", 1, 0],
      ["bottom-left", -1, 1],
      ["bottom-right", 0, 1],
  ]) {
    var posCls = posInfo[0];
    var xoff = posInfo[1];
    var yoff = posInfo[2];
    div.append(new ButtonElement()
      ..text = "+"
      ..classes.addAll(["node-plus", posCls])
      ..onClick.listen((event) {
        makeAddNodeForm(x + xoff, y + yoff);
      })
    );
  }
  div.append(new SpanElement()..text = text);
  insert(div, x, y);
  return div;
}

makeAddNodeForm(int x, int y) {
  var addNodeForm = new FormElement()
    ..classes.add('addnode')
    ..action = '#'
    ..append(new TextAreaElement())
    ..append(new ButtonElement()
      ..classes.add('add')
      ..text = 'Add'
      ..onClick.listen((event) => addNode(event, x, y))
    )
  ;
  insert(addNodeForm, x, y);
}

addNode(Event e, int x, int y) {
  e.preventDefault();
  Element addNode = (e.target as Element).parent;
  TextAreaElement textInput = addNode.querySelector('textarea');
  textInput.setAttribute("disabled", "true");
  String nodeText = textInput.value;
  HttpRequest.request('/map/$mapId/add',
                      method: "POST",
                      mimeType: "application/json",
                      requestHeaders: {
                        'Content-Type': "application/json",
                      },
                      sendData: JSON.encode({
                        "contents": nodeText
                      })
                      ).then((req) {
    if(req.status != 200) {
      window.alert("error");
      return;
    }
    addNode.remove();
    makeNode(nodeText, x, y);
  });
}