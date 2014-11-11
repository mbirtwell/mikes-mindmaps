import "dart:async";

import "package:unittest/unittest.dart";
import "package:redis_client/redis_client.dart";

import "../server/redis_connection_cache.dart";

main () {
  String target = "192.168.33.10:6379";
  RedisConnectionCache conn;
  tearDown(() {
    if(conn != null) {
      return conn.close().then((_) {
        conn = null;
      });
    }
  });
  test("getConn returns a redis connection", () {
    conn = new RedisConnectionCache(target);
    conn.getConn().then(expectAsync((c) {
      expect(c, new isInstanceOf<RedisConnection>());
    }));
  });
  test("two sequential getConn returns a the same redis connection", () {
    conn = new RedisConnectionCache(target);
    var conn1;
    return conn.getConn().then((conn1_) {
      conn1 = conn1_;
      return conn.getConn();
    }).then((conn2) {
      expect(conn1, same(conn2));
    });
  });
  test("two simultaneous getConn returns a the same redis connection", () {
    conn = new RedisConnectionCache(target);
    var conn1 = conn.getConn();
    var conn2 = conn.getConn();
    return Future.wait([conn1, conn2]).then((conns) {
      expect(conns[1], same(conns[0]));
    });
  });
}
