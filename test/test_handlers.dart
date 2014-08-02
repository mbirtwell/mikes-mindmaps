import 'package:unittest/unittest.dart';
import 'package:mock/mock.dart';
import 'dart:async';
import 'dart:io';

import '../server/handlers.dart';

class HttpRequestMock extends Mock implements HttpRequest {
  Uri uri;
  String method;
  HttpResponseMock response = new HttpResponseMock();

  HttpRequestMock(this.uri, {this.method: 'GET'});

  noSuchMethod(i) => super.noSuchMethod(i);
}

class HttpResponseMock extends Mock implements HttpResponse {
  int statusCode;

  Future close() {
    return new Future.value();
  }

  noSuchMethod(i) => super.noSuchMethod(i);
}


main () {
  test('create new map', () {
    var req = new HttpRequestMock(new Uri(path:'/map/create'));
    req.response.when(callsTo('redirect', anything)).thenReturn(new Future.value(true));
    createMindMap(req).whenComplete(expectAsync(() {
      req.response.getLogs(callsTo('redirect', anything)).verify(happenedOnce);
    }));
  });
}