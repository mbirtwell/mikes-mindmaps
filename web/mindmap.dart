import 'dart:html';
import '/lib/urls.dart' as urls;

main () {
  querySelector('#idIndicator')
    ..text = urls.map.parse(window.location.pathname)[0];
}