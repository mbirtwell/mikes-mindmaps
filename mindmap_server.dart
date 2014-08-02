import 'dart:io';
import 'dart:async';
import 'package:http_server/http_server.dart';
import 'packages/path/path.dart';

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

  HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 4040)
      .then((HttpServer server) {
    print('listening on localhost, port ${server.port}');
    server.listen((HttpRequest request) {
      print('got request for ${request.uri.path}');
      var found = false;
      for(var entry in urls) {
        RegExp re = entry[0];
        if(re.hasMatch(request.uri.path)){
          var func = entry[1];
          found = true;
          func(request);
          break;
        }
      }
      if(!found) {
        print('No matcing URL');
        request.response.statusCode == 404;
        request.response.write("Not Found");
        request.response.close();
      }
    });
  }).catchError((e) => print(e.toString()));
}
