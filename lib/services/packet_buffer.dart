import 'dart:async';
import 'dart:typed_data';

class PacketBuffer {
  static const _flushInterval = Duration(milliseconds: 16);
  static const _smallPacketThreshold = 64;

  final List<Uint8List> _pending = [];
  Timer? _timer;
  final void Function(Uint8List) _onFlush;

  PacketBuffer(this._onFlush);

  void add(Uint8List packet) {
    _pending.add(packet);
    if (packet.length > _smallPacketThreshold) {
      _flush();
    } else {
      _timer ??= Timer(_flushInterval, _flush);
    }
  }

  void _flush() {
    if (_pending.isEmpty) {
      _timer = null;
      return;
    }

    int totalSize = 0;
    for (final p in _pending) {
      totalSize += p.length;
    }

    final combined = Uint8List(totalSize);
    int offset = 0;
    for (final packet in _pending) {
      combined.setRange(offset, offset + packet.length, packet);
      offset += packet.length;
    }

    _onFlush(combined);
    _pending.clear();
    _timer = null;
  }

  void clear() {
    _timer?.cancel();
    _timer = null;
    _pending.clear();
  }

  bool get isEmpty => _pending.isEmpty;
  bool get isNotEmpty => _pending.isNotEmpty;
  int get pendingCount => _pending.length;
}

class KeepAliveManager {
  static const _pingInterval = Duration(seconds: 5);
  static const _timeout = Duration(seconds: 15);

  final Map<String, Timer> _timers = {};
  final Map<String, DateTime> _lastPings = {};
  final void Function(String address) _onPeerTimeout;
  final void Function(String address) _onPing;
  final List<String> _activePeers;

  KeepAliveManager({
    required void Function(String address) onPeerTimeout,
    required void Function(String address) onPing,
    required List<String> activePeers,
  })  : _onPeerTimeout = onPeerTimeout,
        _onPing = onPing,
        _activePeers = activePeers;

  void startPeer(String address) {
    _timers[address]?.cancel();
    _lastPings[address] = DateTime.now();

    _timers[address] = Timer.periodic(_pingInterval, (_) {
      _checkPeerStatus(address);
    });
  }

  void _checkPeerStatus(String address) {
    final lastPing = _lastPings[address];
    if (lastPing == null) return;

    if (DateTime.now().difference(lastPing) > _timeout) {
      _onPeerTimeout(address);
      stopPeer(address);
    } else {
      _onPing(address);
    }
  }

  void receivedPong(String address) {
    _lastPings[address] = DateTime.now();
  }

  void stopPeer(String address) {
    _timers[address]?.cancel();
    _timers.remove(address);
    _lastPings.remove(address);
  }

  void stopAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _lastPings.clear();
  }

  bool isPeerActive(String address) => _timers.containsKey(address);
}

class ConnectionPool {
  final Map<String, ConnectionEntry> _connections = {};
  final int maxConnections;

  ConnectionPool({this.maxConnections = 10});

  void add(String address, ConnectionEntry entry) {
    if (_connections.length >= maxConnections && !_connections.containsKey(address)) {
      final oldest = _connections.entries.first;
      oldest.value.close();
      _connections.remove(oldest.key);
    }
    _connections[address] = entry;
  }

  ConnectionEntry? get(String address) => _connections[address];

  void remove(String address) {
    _connections[address]?.close();
    _connections.remove(address);
  }

  void closeAll() {
    for (final entry in _connections.values) {
      entry.close();
    }
    _connections.clear();
  }

  List<String> get activeAddresses => _connections.keys.toList();
  int get count => _connections.length;
}

class ConnectionEntry {
  final DateTime createdAt;
  final void Function() close;

  ConnectionEntry({
    required this.createdAt,
    required this.close,
  });
}