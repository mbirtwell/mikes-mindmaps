import 'dart:io';
import 'dart:async';
import 'package:http_server/http_server.dart';
import 'package:path/path.dart';
import 'package:route/server.dart';

import '../lib/urls.dart' as urls;
import 'handlers.dart';
import 'core.dart';

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
    })).whenComplete(() => new Future.delayed(new Duration(seconds:1), () {
      websock.add("I'm getting really playful now");
    }));
  });
}

serve(Core core) {
  var projroot = dirname(dirname(Platform.script.toFilePath()));
  var webroot = join(projroot, 'web');
  var vd = new VirtualDirectory(projroot);

  // for now. Necessary to server from packages as set up by DartEditor
  vd.jailRoot = false;

  serveFile(fn) {
    return (req) => vd.serveFile(new File(join(webroot, fn)), req);
  }

  HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 4040)
      .then((HttpServer server) {
    print('listening on localhost, port ${server.port}');
    var router = new Router(server)
      ..serve(urls.index).listen(serveFile('index.html'))
      ..serve(urls.create).listen(createMindMap)
      ..serve(urls.test).listen(serveTest)
      ..serve(urls.stream).listen(stream)
      ..serve(urls.map).listen(serveFile('mindmap.html'))
      ..serve(urls.addToMap).listen(addNode)
      ..defaultStream.listen(vd.serveRequest);
  }).catchError((e) => print(e.toString()));
}

main() {
  Core.startUp("192.168.33.10:6379").then((core) {
    serve(core);
  });
}
