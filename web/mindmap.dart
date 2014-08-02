import 'dart:html';

void main() {
  querySelector("#create")
      .onClick.listen((event) => window.location.assign('/map/create'));
}
