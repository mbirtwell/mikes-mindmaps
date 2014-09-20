import "package:route/url_pattern.dart";

UrlPattern index = new UrlPattern(r'/');
UrlPattern test = new UrlPattern(r'/test');
UrlPattern stream = new UrlPattern(r'/stream');
UrlPattern create = new UrlPattern(r'/map/create');
UrlPattern map = new UrlPattern(r'/map/(\d+)');
UrlPattern addToMap = new UrlPattern(r'/map/(\d+)/add');
UrlPattern getMindMap = new UrlPattern(r'/map/(\d+)/get');
UrlPattern data = new UrlPattern(r'/map/(\d+)/data');
