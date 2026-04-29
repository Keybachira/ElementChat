import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../models/message.dart';
import 'connection_engine.dart';

class _PeerConnection {
  final BluetoothDevice device;
  BluetoothConnection? connection;
  final StreamController<Message> _messageController = StreamController<Message>.broadcast();
  DateTime? _lastPing;
  int _sentPackets = 0;
  int _totalLatencyMs = 0;

  Stream<Message> get messageStream => _messageController.stream;
  String get address => device.address;
  String get name => device.name ?? device.address;
  bool get isConnected => connection?.isConnected ?? false;

  _PeerConnection(this.device);

  Future<void> connect(String myAddress, String myName) async {
    connection = await BluetoothConnection.toAddress(device.address);
    _listenForMessages(myAddress);
    _startPingClock();
  }

  void _listenForMessages(String myAddress) {
    StringBuffer buffer = StringBuffer();
    connection?.input?.listen((Uint8List data) {
      String chunk = utf8.decode(data);
      buffer.write(chunk);
      String current = buffer.toString();

      while (current.contains('\n')) {
        int idx = current.indexOf('\n');
        String raw = current.substring(0, idx).trim();
        buffer.clear();
        buffer.write(current.substring(idx + 1));
        current = buffer.toString();

        if (raw.isNotEmpty) {
          try {
            final json = jsonDecode(raw) as Map<String, dynamic>;
            final msg = Message.fromJson(json, myAddress);
            _messageController.add(msg);
          } catch (_) {}
        }
      }
    }, onDone: () => connection = null);
  }

  void _startPingClock() {
    Timer.periodic(const Duration(seconds: 5), (_) {
      if (isConnected) {
        _lastPing = DateTime.now();
      }
    });
  }

  Future<bool> send(Message message) async {
    if (!isConnected) return false;
    final startTime = DateTime.now();
    try {
      final encoded = jsonEncode(message.toJson()) + '\n';
      connection?.output.add(Uint8List.fromList(utf8.encode(encoded)));
      await connection?.output.allSent;
      _sentPackets++;
      _totalLatencyMs += DateTime.now().difference(startTime).inMilliseconds;
      return true;
    } catch (_) {
      return false;
    }
  }

  ConnectionMetrics getMetrics() {
    final avgLatency = _sentPackets > 0 ? (_totalLatencyMs ~/ _sentPackets) : 0;
    return ConnectionMetrics(
      latencyMs: avgLatency,
      packetSize: 256,
    );
  }

  void dispose() {
    _messageController.close();
    connection?.close();
  }
}

class BluetoothProvider implements ConnectionEngine {
  final FlutterBluetoothSerial _bt = FlutterBluetoothSerial.instance;
  final Map<String, _PeerConnection> _peers = {};
  String _myAddress = '';
  String _myName = '';

  final StreamController<Message> _messageController = StreamController<Message>.broadcast();
  final StreamController<List<String>> _peersController = StreamController<List<String>>.broadcast();

  PerformanceCallback? onPerformanceUpdate;
  FallbackSuggestionCallback? onFallbackSuggestion;

  @override
  Stream<Message> get messageStream => _messageController.stream;
  @override
  Stream<List<String>> get peersStream => _peersController.stream;
  @override
  List<String> get connectedPeers => _peers.values.map((p) => p.name).toList();
  @override
  bool get isConnected => _peers.isNotEmpty;

  void init(String myAddress, String myName) {
    _myAddress = myAddress;
    _myName = myName;
  }

  @override
  Future<bool> connect(String address, String myName) async {
    final device = await _bt.getBondedDevices().then((devices) =>
      devices.firstWhere((d) => d.address == address, orElse: () => throw Exception('Device not found'))
    );
    
    if (_peers.containsKey(device.address)) return true;
    
    try {
      final peer = _PeerConnection(device);
      await peer.connect(_myAddress, _myName);
      _peers[device.address] = peer;

      peer.messageStream.listen((msg) {
        _messageController.add(msg);
        _broadcastExcept(msg, excludeAddress: device.address);
      });

      _peersController.add(connectedPeers);
      
      _startPerformanceMonitoring(device.address);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _startPerformanceMonitoring(String address) {
    Timer.periodic(const Duration(seconds: 10), (_) {
      final peer = _peers[address];
      if (peer != null && peer.isConnected) {
        final metrics = peer.getMetrics();
        onPerformanceUpdate?.call(metrics);
        if (metrics.isSlow) {
          onFallbackSuggestion?.call(ConnectionType.wifiDirect);
        }
      }
    });
  }

  void _broadcastExcept(Message msg, {String? excludeAddress}) async {
    for (final peer in _peers.values) {
      if (peer.address != excludeAddress) {
        await peer.send(msg);
      }
    }
  }

  @override
  Future<bool> send(Message message) async {
    bool allSent = true;
    for (final peer in _peers.values) {
      final sent = await peer.send(message);
      if (!sent) allSent = false;
    }
    return allSent;
  }

  @override
  void disconnect(String address) {
    _peers[address]?.dispose();
    _peers.remove(address);
    _peersController.add(connectedPeers);
  }

  @override
  Future<List<dynamic>> discoverDevices() async {
    List<BluetoothDevice> results = [];
    try {
      StreamSubscription? sub;
      Completer<List<BluetoothDevice>> completer = Completer();
      sub = _bt.startDiscovery().listen(
        (r) => results.add(r.device),
        onDone: () {
          sub?.cancel();
          completer.complete(results);
        },
      );
      return await completer.future.timeout(const Duration(seconds: 15), onTimeout: () {
        sub?.cancel();
        return results;
      });
    } catch (_) {
      return results;
    }
  }

  @override
  void dispose() {
    for (final p in _peers.values) {
      p.dispose();
    }
    _messageController.close();
    _peersController.close();
  }
}