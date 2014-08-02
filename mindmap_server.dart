import 'dart:io';
import 'dart:async';
import 'package:http_server/http_server.dart';
import 'package:path/path.dart';
import 'package:route/server.dart';

serveTest(HttpRequest req) {
  req.response.write("test page");
  req.response.close();
}

stream(HttpRequest req) {
  WebSocketTransformer.upgrade(req).then((websock) {
    new Future.delayed(new Duration(seconds:1), () {
      websock.add("Hello there");
    }).whenComplete(() => new Future.delayed(new Duration(seconds:2), () {
      websock.add("It's mighty nice to see you");
    }));
  });
}

main() {
  var webroot = join(dirname(Platform.script.toFilePath()), 'web');
  var vd = new VirtualDirectory(webroot);
  // for now. Necessary to server from packages as set up by DartEditor
  vd.jailRoot = false;

  var urls = [
      [new RegExp(r"^/$"), (request) => vd.serveFile(new File(join(webroot, 'index.html')), request)],
      [new RegExp(r"^/test$"), serveTest],
      [new RegExp(r"^/stream$"), stream],
      [new RegExp(r""), (request) => vd.serveRequest(request)]
  ];

  urls = {
    'index': new UrlPattern(r'/'),
    'test': new UrlPattern(r'/test'),
    'stream': new UrlPattern(r'/stream'),
  };

  HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 4040)
      .then((HttpServer server) {
    print('listening on localhost, port ${server.port}');
    var router = new Router(server)
      ..serve(urls['index']).listen((req) => vd.serveFile(new File(join(webroot, 'index.html')), req))
      ..serve(urls['test']).listen(serveTest)
      ..serve(urls['stream']).listen(stream)
      ..defaultStream.listen(vd.serveRequest);
  }).catchError((e) => print(e.toString()));
}
