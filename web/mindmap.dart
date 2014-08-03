import 'dart:html';
import '/lib/urls.dart' as urls;

main () {
  querySelector('#idIndicator')
    ..text = urls.map.parse(window.location.pathname)[0];
  querySelector('.addnode button.add')
    ..onClick.listen(addNode);
}

addNode(Event e) {
  e.preventDefault();
  Element addNode = (e.target as Element).parent;
  var nodeText = (addNode.querySelector('textarea') as TextAreaElement).value;
  addNode.remove();
  querySelector('body').append(
      new DivElement()
        ..classes.add('node')
        ..text = nodeText
  );
}