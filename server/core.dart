part of mindmap_server;


class SubscriptionChannelState {
  final String name;
  const SubscriptionChannelState._(this.name);

  static const SubscriptionChannelState IDLE = const SubscriptionChannelState._('IDLE');
  static const SubscriptionChannelState SUBSCRIBING = const SubscriptionChannelState._('SUBSCRIBING');
  static const SubscriptionChannelState SUBSCRIBED = const SubscriptionChannelState._('SUBSCRIBED');
  static const SubscriptionChannelState UNSUBSCRIBING = const SubscriptionChannelState._('UNSUBSCRIBING');
}

class Subscription {
  SubscriptionChannelState state = SubscriptionChannelState.IDLE;
  Future subscriptionFuture;
  Future unsubscribeFuture;
  Completer secondarySubscribeCompleter;
  StreamController<MindMapNode> _stream;
  final String channel;
  int refCount = 0;

  Subscription(this.channel) {
    _stream = new StreamController.broadcast();
  }

  get stream => _stream.stream;

  onData(String data) {
    print("Sending update on $channel");
    _stream.sink.add(new MindMapNode.fromJson(data));
  }
}

class SubscriptionReference {
  Subscription _subscription;
  final int refNumber;

  SubscriptionReference(Subscription subscription):
    _subscription = subscription,
    refNumber = subscription.refCount
  {
    _subscription.refCount += 1;
  }

  get stream => _subscription.stream;
}

class SubscriptionChannel {
  SubscriptionChannelState _state = SubscriptionChannelState.IDLE;
  RedisConnectionCache _conn;
  Map<String, Subscription> _subscriptions = {};
  Future _primarySubscribeFuture;
  Future _primaryUnsubscibeFuture;

  SubscriptionChannel(connectionString):
    _conn = new RedisConnectionCache(connectionString)
  {}

  Future _primarySubscribe(Subscription subscription) {
    if(_state != SubscriptionChannelState.IDLE) {
      throw new StateError("Primary subscribe in when not idle");
    }
    _state = SubscriptionChannelState.SUBSCRIBING;
    return _primarySubscribeFuture = _conn.getConn().then((conn) {
      return conn.subscribe([subscription.channel], this._onMessage);
    }).then((_) {
      print("Primary subscription done for ${subscription.channel}");
      subscription.state = SubscriptionChannelState.SUBSCRIBED;
      _state = SubscriptionChannelState.SUBSCRIBED;
      _primarySubscribeFuture = null;
    });
  }

  Future _secondarySubscribe(Subscription subscription) {
    if(_state != SubscriptionChannelState.SUBSCRIBED) {
      throw new StateError("Secondary subscribe in when not subscribed");
    }
    subscription.secondarySubscribeCompleter = new Completer();
    return _conn.getConn().then((conn) {
      return conn.send(['SUBSCRIBE', subscription.channel]);
    }).then((_) {
      return subscription.secondarySubscribeCompleter.future;
    });
  }

  _subscribe(Subscription subscription) {
    var subscriptionFuture;
    switch(_state) {
      case SubscriptionChannelState.IDLE:
        subscriptionFuture = _primarySubscribe(subscription);
        break;
      case SubscriptionChannelState.SUBSCRIBING:
        subscriptionFuture = _primarySubscribeFuture.then((_) {
          return _secondarySubscribe(subscription);
        });
        break;
      case SubscriptionChannelState.SUBSCRIBED:
        subscriptionFuture = _secondarySubscribe(subscription);
        break;
      case SubscriptionChannelState.UNSUBSCRIBING:
        subscriptionFuture = _primaryUnsubscibeFuture.then((_) {
          return _primarySubscribe(subscription);
        });
        break;
    }
    return subscriptionFuture;
  }

  Future<SubscriptionReference> subscribe(String channel) {
    var subscription = _subscriptions.putIfAbsent(channel, () {
      return new Subscription(channel);
    });
    switch(subscription.state) {
      case SubscriptionChannelState.IDLE:
        subscription.subscriptionFuture = _subscribe(subscription);
        subscription.state = SubscriptionChannelState.SUBSCRIBING;
        break;
      case SubscriptionChannelState.SUBSCRIBING:
        break;
      case SubscriptionChannelState.SUBSCRIBED:
        return new Future.value(new SubscriptionReference(subscription));
      case SubscriptionChannelState.UNSUBSCRIBING:
        subscription.subscriptionFuture = subscription.unsubscribeFuture.then((_) {
          return _subscribe(subscription);
        });
        subscription.state = SubscriptionChannelState.SUBSCRIBING;
    }
    return subscription.subscriptionFuture.then((_) {
      return new SubscriptionReference(subscription);
    });
  }

  _onMessage(Receiver message) {
    message.receiveMultiBulk().then((val) {
      var type = val.replies[0].string;
      var channel = val.replies[1].string;
      if(type == "message") {
        var subscription = _subscriptions[channel];
        if(subscription == null) {
          print("Message for unscuscribed channel");
          return;
        }
        var data = val.replies[2].string;
        subscription.onData(data);
      } else if(type == "subscribe") {
        print("Subscription to channel ${channel} ${val.replies[2].integer}");
        var subscription = _subscriptions[channel];
        if(subscription == null) {
          print("Subscription for unsubscribed channel");
          return;
        }
        if(subscription.state != SubscriptionChannelState.SUBSCRIBING) {
          print("Unexpected subscribe message for channel $channel in state ${subscription.state.name}");
          return;
        }
        subscription.subscriptionFuture = null;
        subscription.state = SubscriptionChannelState.SUBSCRIBED;
        subscription.secondarySubscribeCompleter.complete();
      }
    });
  }

  Future close() {
    return _conn.close();
  }

}

class Core {
  static Core instance;

  String redisConnectionString;
  RedisClient redisClient;
  SubscriptionChannel subscriptions;

  Core(this.redisConnectionString) {
    subscriptions = new SubscriptionChannel(redisConnectionString);
  }

  static Future<Core> startUp(String redisConnectionString) {
    Core core = new Core(redisConnectionString);
    return core.connect().then((core){
      return core.initData();
    }).then((_) {
      instance = core;
      return core;
    });
  }

  Future<Core> connect() {
    print("Connecting to redis $redisConnectionString");
    return RedisClient.connect(redisConnectionString).then((client) {
      print("Connected to redis");
      this.redisClient = client;
      return this;
    });
  }

  Future<Core> initData() {
    print("Setting up default data");
    return this.redisClient.msetnx({
      "next_map_id": 1000,
    }).then((_) => this);
  }

  Future close() {
    return Future.wait([
      this.redisClient.close(),
      this.subscriptions.close(),
  ]);
  }

  Future<int> createMap() {
    return redisClient.incr("next_map_id");
  }

  Future addNode(int mapId, MindMapNode node) {
    print("Adding node $mapId: $node");
    return redisClient.rpush('map/$mapId', [node.toMap()]).then((_){
      return redisClient.publish('map/$mapId', JSON.encode(node.toMap())).then((_) {
        print("Added node $mapId: $node");
      });
    });
  }

  Future<List<MindMapNode>> getMindMap(int mapId) {
    return redisClient.lrange('map/$mapId').then((results) {
      return results.map((item) => new MindMapNode.fromMap(item));
    });
  }

  Future<SubscriptionReference> subscribeToMindMap(int mapId) {
    return subscriptions.subscribe('map/$mapId');
  }
}
