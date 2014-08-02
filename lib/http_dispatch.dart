import "dart:io";

class HttpResponseException implements Exception {
  int code;
  String msg;
  String body = "";

  HttpResponseException(this.code, {this.msg, this.body});
}

class Http404 extends HttpResponseException {
  String resource;

  Http404(String this.resource): super(404);
}

typedef void Handler(HttpRequest request);

class HandlerEntry
{
  RegExp re;
  Handler handler;
  HandlerEntry(this.re, this.handler);
}

class HttpDispatch {
  List<HandlerEntry> urls = [];

  HttpDispatch() {
  }

  Handler resolve (url) {
    for(var entry in urls) {
      if(entry.re.hasMatch(url)) {
        return entry.handler;
      }
    }
    throw new Http404(url);
  }

  void addHandler(RegExp re, Handler handler) {
    urls.add(new HandlerEntry(re, handler));
  }

  void handle(HttpRequest req) {
    try {
      var handler = resolve(req.uri.path);
      handler(req);
    } on HttpResponseException catch (e) {

    }
  }
}
