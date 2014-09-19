import "dart:io";
import "dart:async";
import "dart:convert";

import "../lib/urls.dart" as urls;
import "../lib/map_node.dart";
import "core.dart";


Future createMindMap(HttpRequest request) {
  return Core.instance.createMap().then((mapId) {
      return request.response.redirect(new Uri(path:urls.map.reverse([mapId])));
  });
}

Future addNode(HttpRequest req) {
  var args = urls.addToMap.parse(req.uri.path);
  // assume that we only get one event
  return UTF8.decoder.bind(req).single.then((data) {
    return Core.instance.addNode(int.parse(args[0]), new MindMapNode.fromJson(data));
  }).then((nodeId) {
    req.response.headers.set('Content-Type', "application/json");
    req.response.write(JSON.encode({
      'id': nodeId
    }));
    return req.response.close();
  });
}