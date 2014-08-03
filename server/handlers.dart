import "dart:io";
import "dart:async";

import "../lib/urls.dart" as urls;
import "core.dart";

Future createMindMap(HttpRequest request) {
  return Core.instance.createMap().then((mapId) {
      request.response.redirect(new Uri(path:urls.map.reverse([mapId])));
  });
}

Future addNode(HttpRequest req) {

}