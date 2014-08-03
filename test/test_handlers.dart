import 'package:unittest/unittest.dart';
import 'package:mock/mock.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:route/url_pattern.dart';

import '../lib/urls.dart' as urls;
import '../server/handlers.dart';
import '../server/core.dart';

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
    'json decode',
    'Check the data decoded as JSON',
    matcher
  );

  featureValueOf(actual) => new JsonDecoder().convert(actual);
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
      req.response.getLogs(callsTo('redirect', new UriMatchingPattern(urls.map, ['1001']))).verify(happenedOnce);
    }));
  });
  test('addNode', () {
    StringBuffer written;
    core.when(callsTo('addNode')).alwaysReturn(new Future.value(101001));
    var req = new HttpRequestMock(Uri.parse('/map/1001/add'), method:'POST');
    // TODO mock the request having data
    req.response.when(callsTo('write')).thenCall((data)=>written.write(data));
    req.response.when(callsTo('close')).alwaysReturn(new Future.value(true));
    addNode(req).then(expectAsync((_) {
      // TODO expect the call to core.addNode to have the correct data
      req.response.getLogs(callsTo('close')).verify(happenedOnce);
      expect(written, new JsonDecoded({'id': 101001}));
    }));
  });
}