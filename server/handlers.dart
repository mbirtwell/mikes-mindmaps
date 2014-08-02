import "dart:io";
import "dart:async";

import "../lib/urls.dart" as urls;

Future createMindMap(HttpRequest request) {
  return request.response.redirect(new Uri(path:urls.map.reverse(['1001'])));
}