import '../models/message.dart';

abstract class ConnectionEngine {
  Future<bool> connect(String address, String myName);
  Future<bool> send(Message message);
  Stream<Message> get messageStream;
  Stream<List<String>> get peersStream;
  List<String> get connectedPeers;
  bool get isConnected;
  void disconnect(String address);
  Future<List<dynamic>> discoverDevices();
  void dispose();
}

enum ConnectionType { bluetooth, wifiDirect }

class ConnectionMetrics {
  final int latencyMs;
  final int packetSize;
  final DateTime timestamp;

  ConnectionMetrics({
    required this.latencyMs,
    required this.packetSize,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isSlow => latencyMs > 2000 || packetSize > 1024;
}

typedef PerformanceCallback = void Function(ConnectionMetrics metrics);
typedef FallbackSuggestionCallback = void Function(ConnectionType suggestedType);