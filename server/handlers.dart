import "dart:io";
import "dart:async";

Future createMindMap(HttpRequest request) {
  return request.response.redirect(new Uri(path:'/map/1'));
}