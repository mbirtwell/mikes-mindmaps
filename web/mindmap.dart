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
  var cx = window.innerWidth/2 + x * 2 * ox * r + y * 1.5 * r * tan(30 * PI / 180);
  var cy = window.innerHeight/2 + y * 1.5 * r;
  hex.points
    ..appendItem(svgEl.createSvgPoint()..x = cx ..y = cy - r)
    ..appendItem(svgEl.createSvgPoint()..x = cx + r * ox ..y = cy - r/2)
    ..appendItem(svgEl.createSvgPoint()..x = cx + r * ox ..y = cy + r/2)
    ..appendItem(svgEl.createSvgPoint()..x = cx ..y = cy + r)
    ..appendItem(svgEl.createSvgPoint()..x = cx - r * ox ..y =  cy + r/2)
    ..appendItem(svgEl.createSvgPoint()..x = cx - r * ox ..y =  cy - r/2)
  ;

  svgEl.append(new svg.TextElement()
    ..setAttribute('x', "$cx")
    ..setAttribute('y', cy.toString())
    ..text = "$x, $y"
  );
}

main () {
  mapId = int.parse(urls.map.parse(window.location.pathname)[0]);
  querySelector('#idIndicator').text = mapId.toString();

  var addNodeForm = querySelector('.addnode');
  addNodeForm
    ..style.top = "${window.innerHeight/2 - addNodeForm.offsetHeight/2}px"
    ..style.left = "${window.innerWidth/2 - addNodeForm.offsetWidth/2}px"
  ;
  querySelector('.addnode button.add')
    ..onClick.listen(addNode);

  for(var x = -2; x < 3; ++x) {
    for(var y = -1; y < 2; ++y) {
      addHex(x, y);
    }
  }
}

makeNode(text) {
  var div = new DivElement()
    ..classes.add('node')
  ;
  for(var pos in ["top-left", "top-right", "left",
                  "right", "bottom-left", "bottom-right"]) {
    div.append(new ButtonElement()
      ..text = "+"
      ..classes.addAll(["node-plus", pos])
    );
  }
  div.append(new SpanElement()..text = text);
  querySelector('body').append(div);
  div
    ..style.top = "${window.innerHeight/2 - div.offsetHeight/2}px"
    ..style.left = "${window.innerWidth/2 - div.offsetWidth/2}px"
  ;
  return div;
}

addNode(Event e) {
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
    makeNode(nodeText);
  });
}