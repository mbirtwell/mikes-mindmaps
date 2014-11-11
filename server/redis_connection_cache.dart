import "dart:async";
import "package:redis_client/redis_client.dart";

class RedisConnectionCache {
  String _connectionString;
  bool _closed = false;
  Future _closing = null;
  Future<RedisConnection> _connecting = null;
  RedisConnection _conn = null;

  RedisConnectionCache(this._connectionString) {}

  get closed => _closed;

  Future close() {
    _closed = true;
    if(_conn != null) {
      _closing = _conn.close().then((_) {
        _closing = null;
      });
      _conn = null;
      return _closing;
    } else if(_closing != null) {
      return _closing;
    } else {
      return new Future.value(null);
    }
  }

  Future<RedisConnection> getConn() {
    if(closed) {
      throw new StateError("Attempt to connect whilst closing");
    } else if(_conn != null) {
      return new Future.value(_conn);
    } else if(_connecting != null) {
      return _connecting;
    } else {
      _connecting = RedisConnection.connect(_connectionString).then((conn) {
        _conn = conn;
        _connecting = null;
        return conn;
      });
      return _connecting;
    }
  }
}
