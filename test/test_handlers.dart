import 'package:unittest/unittest.dart';
import 'package:mock/mock.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:mirrors';
import 'package:route/url_pattern.dart';

import '../lib/urls.dart' as urls;
import '../server/handlers.dart';
import '../server/core.dart';

class HttpRequestMock extends Mock implements HttpRequest {
  Uri uri;
  String method;
  HttpResponseMock response = new HttpResponseMock();
  Stream<List<int>> _bodyStream;
  InstanceMirror _streamMirror;

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

class JsonDecoded extends CustomMatcher
{
  JsonDecoded(matcher): super(
    'json decode to be',
    'JSON',
    matcher
  );

  featureValueOf(actual) {
    try {
      return JSON_TO_BYTES.decode(actual);
    } catch(e) {
      return "Exception ${e}";
    }
  }
}

class CoreMock extends Mock implements Core
{

  noSuchMethod(i) => super.noSuchMethod(i);
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
    print("addNode");
    List<int> written = [];
    core.when(callsTo('addNode')).alwaysReturn(new Future.value(101001));
    var req = new HttpRequestMock(
        Uri.parse('/map/1001/add'),
        method:'POST',
        body: JSON_TO_BYTES.encode({
          'contents': 'herbs'
        }));
    req.response.when(callsTo('write')).thenCall((data)=>written.addAll(data));
    req.response.when(callsTo('close')).alwaysReturn(new Future.value(true));
    addNode(req).then(expectAsync((_) {
      core.getLogs(callsTo('addNode', 1001, 'herbs')).verify(happenedOnce);
      req.response.getLogs(callsTo('close')).verify(happenedOnce);
      expect(written, new JsonDecoded({'id': 101001}));
    }));
  });
}