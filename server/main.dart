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

serve(Core core, bool serveBuild, String bindIp, int port) {
  var projroot = dirname(dirname(Platform.script.toFilePath()));
  if(serveBuild) {
    projroot = "$projroot/build";
  }
  var webroot = join(projroot, 'web');

  print("Setting up virtual directory $projroot");
  var vd = new VirtualDirectory(projroot);

  // for now. Necessary to server from packages as set up by DartEditor
  vd.jailRoot = false;

  serveFile(fn) {
    var f = new File(join(webroot, fn));
    return (req) {
      print("serving file $f for ${req.uri}");
      vd.serveFile(f, req);
    };
  }

  print("Starting HTTP Server ${bindIp}:$port");
  HttpServer.bind(bindIp, port)
      .then((HttpServer server) {
    print('listening on localhost, port ${server.port}');

    var httpReqStream = server.transform(new StreamTransformer.fromHandlers(
      handleData: (HttpRequest req, EventSink<HttpRequest> sink) {
        print("got request ${req.uri}");
        sink.add(req);
    }));
    var router = new Router(httpReqStream)
      ..serve(urls.index).listen(serveFile('index.html'))
      ..serve(urls.create).listen(createMindMap)
      ..serve(urls.test).listen(serveTest)
      ..serve(urls.stream).listen(stream)
      ..serve(urls.map).listen(serveFile('mindmap.html'))
      ..serve(urls.addToMap).listen(addNode)
      ..serve(urls.getMindMap).listen(getMindMap)
      ..serve(urls.data).listen(getUpdates)
      ..defaultStream.listen(vd.serveRequest);
  }).catchError((e) => print(e.toString()));
}

main() {
  print("Starting Mike's mindmaps");
  var redisConnectionString;
  var deployed;
  if(Platform.environment.containsKey("REDISCLOUD_URL")) {
    var redisUrlPrefix = "redis://rediscloud:";
    var redisUrl = Platform.environment['REDISCLOUD_URL'];
    if(!redisUrl.startsWith(redisUrlPrefix)) {
      throw new ArgumentError("Bad redis URL $redisUrl");
    }
    redisConnectionString = redisUrl.substring(redisUrlPrefix.length);
    deployed = true;
  } else {
    redisConnectionString = "192.168.33.10:6379";
    deployed = false;
  }

  var portEnv = Platform.environment['PORT'];
  var port;
  if(portEnv == null) {
    port = 4040;
  } else {
    port = int.parse(portEnv);
  }

  var bindIp;
  if(deployed) {
    bindIp = '0.0.0.0';
  } else {
    bindIp = '127.0.0.1';
  }
  print("Starting core");
  Core.startUp(redisConnectionString).then((core) {
    serve(core, deployed, bindIp, port);
  });
}
