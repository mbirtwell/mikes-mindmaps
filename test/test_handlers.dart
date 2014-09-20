import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:mirrors';
import 'dart:math';
import 'package:unittest/unittest.dart';
import 'package:mock/mock.dart';
import 'package:route/url_pattern.dart';

import '../lib/map_node.dart';
import '../lib/urls.dart' as urls;
import '../server/handlers.dart';
import '../server/core.dart';

class HttpHeadersMock extends Mock implements HttpHeaders {

}

class HttpRequestMock extends Mock implements HttpRequest {
  Uri uri;
  String method;
  HttpResponseMock response = new HttpResponseMock();
  Stream<List<int>> _bodyStream;
  InstanceMirror _streamMirror;
  HttpHeadersMock headers = new HttpHeadersMock();

  HttpRequestMock(this.uri, {this.method: 'GET', List<int> body}) {
    var bodyIterable = [];
    if(body != null) {
      bodyIterable.add(body);
    }
    _bodyStream = new Stream.fromIterable(bodyIterable);
    _streamMirror = reflect(_bodyStream);
//    _streamMirror.type.instanceMembers.forEach((key, val) {
//      print("$key: $val ${val.isGetter} ${val.simpleName}");
//    });
  }

  when(CallMatcher logFilter) {
    // TODO: disallow behaviours to be set on Stream methods
    return super.when(logFilter);
  }

  noSuchMethod(Invocation i){
    // Always call Mock.noSuchMethod to populate the log even for Stream methods
    var rv = super.noSuchMethod(i);
    if(_streamMirror.type.instanceMembers.containsKey(i.memberName)) {
      _streamMirror.delegate(i);
    }
  }
}

class HttpResponseMock extends Mock implements HttpResponse {
  int statusCode;
  HttpHeadersMock headers = new HttpHeadersMock();

  noSuchMethod(i) => super.noSuchMethod(i);
}


class UriMatchingPattern extends Matcher
{
  UrlPattern pattern;
  Matcher argMatcher;
  UriMatchingPattern(this.pattern, [argMatcher]) {
    if(argMatcher != null) {
      this.argMatcher = wrapMatcher(argMatcher);
    }
  }

  bool matches(Uri actual, Map state) {
    var args;
    try {
      args = pattern.parse(actual.path);
    } on ArgumentError {
      state['pattenMatch'] = false;
      return false;
    }
    if(this.argMatcher == null) {
      return true;
    }
    if (argMatcher.matches(args, state)) return true;
    addStateInfo(state, {'args': args, 'patternMatch': true});
    return false;
  }

  describe(Description desc) {
    desc.add("Url matches pattern ${pattern}");
    if(argMatcher != null) {
      desc.add(" and args match ").addDescriptionOf(argMatcher);
    }
  }

  Description describeMismatch(item, Description desc,
                               Map state, bool verbose)
  {
    if(state['patternMatch']) {
      desc.add('has args ${state['args']}');
      var innerDescription = new StringDescription();
      argMatcher.describeMismatch(state['args'], innerDescription,
                                  state['state'], verbose);
      if (innerDescription.length > 0) {
        desc.add(' which ').add(innerDescription.toString());
      }
    } else {
      desc.add("has path ${item.path}");
    }
  }
}

//Codec<Object, List<int>> JSON_TO_BYTES = JSON.fuse(UTF8);
//class JsonDecoded extends CustomMatcher
//{
//  JsonDecoded(matcher): super(
//    'json decode to be',
//    'JSON',
//    matcher
//  );
//
//  featureValueOf(actual) {
//    try {
//      return JSON_TO_BYTES.decode(actual);
//    } catch(e) {
//      return "Exception ${e}";
//    }
//  }
//}

class CoreMock extends Mock implements Core
{

  noSuchMethod(i) => super.noSuchMethod(i);
}

class ResponseVerifier {
  HttpRequestMock req;
  StringBuffer written = new StringBuffer();

  ResponseVerifier(String uri, [body=null]) {
    var method = "GET";
    if(body != null) {
      method = "POST";
      body = UTF8.encode(body);
    }
    req = new HttpRequestMock(Uri.parse(uri), method: method, body: body);
    req.response.when(callsTo('write')).thenCall((data)=>written.write(data));
    req.response.when(callsTo('close')).alwaysReturn(new Future.value(true));
  }

  verify(Matcher response) {
    req.response.getLogs(callsTo('close')).verify(happenedOnce);
    expect(JSON.decode(written.toString()), response);

  }
}

main () {
  CoreMock core;
  setUp(() {
    Core.instance = core = new CoreMock();
  });
  test('create new map', () {
    core.when(callsTo('createMap')).alwaysReturn(new Future.value(1001));
    var req = new HttpRequestMock(new Uri(path:'/map/create'));
    req.response.when(callsTo('redirect', anything)).thenReturn(new Future.value(true));
    createMindMap(req).then(expectAsync((_) {
      core.getLogs(callsTo('createMap')).verify(happenedOnce);
      req.response.getLogs(callsTo('redirect', new UriMatchingPattern(urls.map, ['1001']))).verify(happenedOnce);
    }));
  });
  test('addNode', () {
    var node = new MindMapNode('herbs', new Point(0, 0), null);
    var responseVerifier = new ResponseVerifier('/map/1001/add', node.toJson());
    core.when(callsTo('addNode')).alwaysReturn(new Future.value(101001));
    addNode(responseVerifier.req).then(expectAsync((_) {
      core.getLogs(callsTo('addNode', 1001, node)).verify(happenedOnce);
      responseVerifier.verify(equals({'id': 101001}));
    }));
  });
  test('getMindMap returns an empty mind map from core', () {
    var responseVerifier = new ResponseVerifier('/map/1001/get');
    core.when(callsTo('getMindMap')).alwaysReturn(new Future.value([].map((x) => x)));
    getMindMap(responseVerifier.req).then(expectAsync((_) {
      core.getLogs(callsTo('getMindMap', 1001)).verify(happenedOnce);
      responseVerifier.verify(equals([]));
    }));
  });
  test('getMindMap returns an interesting mind map from core', () {
    var nodes = [
        new MindMapNode('node1', new Point(0, 0), null),
        new MindMapNode('node2', new Point(0, 1), new Point(0, 0)),
    ];
    var responseVerifier = new ResponseVerifier('/map/1002/get');
    core.when(callsTo('getMindMap')).alwaysReturn(new Future.value(nodes));
    getMindMap(responseVerifier.req).then(expectAsync((_) {
      core.getLogs(callsTo('getMindMap', 1002)).verify(happenedOnce);
      responseVerifier.verify(equals(nodes.map((node) => node.toMap())));
    }));
  });
}