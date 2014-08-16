import 'dart:html';
import 'dart:convert';
import '/lib/urls.dart' as urls;

int mapId;

main () {
  mapId = int.parse(urls.map.parse(window.location.pathname)[0]);
  querySelector('#idIndicator').text = mapId.toString();
  querySelector('.addnode button.add')
    ..onClick.listen(addNode);
}

makeNode(text) {
  var div = new DivElement()
    ..classes.add('node')
    ..style.top = "${window.innerHeight/2 - 30}px"
    ..style.left = "${window.innerWidth/2 - 100}px"
  ;
  for(var pos in ["top", "left", "right", "bottom"]) {
    div.append(new ButtonElement()
      ..text = "+"
      ..classes.addAll(["node-plus", pos])
    );
  }
  div.append(new SpanElement()..text = text);
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
    querySelector('body').append(makeNode(nodeText));
  });
}