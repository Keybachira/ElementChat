import 'dart:async';
import '../models/message.dart';
import '../providers/connection_engine.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/wifi_direct_provider.dart';
import '../services/crypto_service.dart';
import '../services/notification_service.dart';
import '../services/message_store.dart';

enum GroupRole { leader, peer }

class MeshController {
  static final MeshController _instance = MeshController._internal();
  factory MeshController() => _instance;
  MeshController._internal();

  final BluetoothProvider _btProvider = BluetoothProvider();
  final WifiDirectProvider _wifiProvider = WifiDirectProvider();
  final CryptoService _cryptoService = CryptoService();
  final NotificationService _notificationService = NotificationService();
  final MessageStore _messageStore = MessageStore();
  
  ConnectionEngine? _activeProvider;
  String? _leaderId;
  GroupRole _myRole = GroupRole.peer;
  
  String _myAddress = '';
  String _myName = '';
  bool _encryptionEnabled = true;

  final _roleController = StreamController<GroupRole>.broadcast();
  final _fallbackController = StreamController<ConnectionType>.broadcast();
  final _messagesController = StreamController<List<Message>>.broadcast();

  List<Message> _messages = [];

  Stream<GroupRole> get roleStream => _roleController.stream;
  Stream<ConnectionType> get fallbackStream => _fallbackController.stream;
  Stream<List<Message>> get messagesStream => _messagesController.stream;
  List<Message> get messages => List.unmodifiable(_messages);
  String? get leaderId => _leaderId;
  GroupRole get myRole => _myRole;
  List<String> get connectedPeers => _activeProvider?.connectedPeers ?? [];
  bool get encryptionEnabled => _encryptionEnabled;
  String get publicKey => _cryptoService.getPublicKeyForExchange();

  void init(String myAddress, String myName) async {
    _myAddress = myAddress;
    _myName = myName;
    _activeProvider = _btProvider;
    _btProvider.init(myAddress, myName);
    _wifiProvider.init(myAddress, myName);
    _cryptoService.init();
    await _notificationService.init();
    await _messageStore.init();
    await _loadHistory();
    _setupPerformanceMonitoring();
    _setupMessageRelay();
  }

  Future<void> _loadHistory() async {
    final history = await _messageStore.loadMessages(limit: 100);
    _messages = history.reversed.toList();
    _messagesController.add(List.from(_messages));
  }

  void toggleEncryption(bool enabled) {
    _encryptionEnabled = enabled;
  }

  void _setupPerformanceMonitoring() {
    _btProvider.onPerformanceUpdate = (metrics) {
      if (_shouldFallback(metrics)) {
        _fallbackController.add(ConnectionType.wifiDirect);
        _notificationService.showFallbackSuggestion(
          reason: 'Latência alta detectada. ${metrics.latencyMs}ms',
        );
      }
    };
  }

  bool _shouldFallback(ConnectionMetrics metrics) {
    return metrics.isSlow;
  }

  void _setupMessageRelay() {
    _btProvider.messageStream.listen((msg) async {
      String decryptedBody = msg.body;
      
      if (_encryptionEnabled && !msg.isMe) {
        decryptedBody = _cryptoService.decryptMessage(msg.body, msg.senderAddress);
      }

      final decryptedMsg = Message(
        id: msg.id,
        senderName: msg.senderName,
        senderAddress: msg.senderAddress,
        body: decryptedBody,
        timestamp: msg.timestamp,
        status: MessageStatus.delivered,
        isMe: msg.isMe,
      );

      _messages.add(decryptedMsg);
      _messagesController.add(List.from(_messages));

      await _messageStore.saveMessage(decryptedMsg);

      if (!msg.isMe) {
        _notificationService.showMessageNotification(
          senderName: msg.senderName,
          message: decryptedBody,
          senderAddress: msg.senderAddress,
        );
      }

      _broadcastExcept(decryptedMsg, excludeAddress: msg.senderAddress);
    });
  }

  Future<bool> connectTo(String address) async {
    if (_activeProvider == null) return false;
    return await _activeProvider!.connect(address, _myName);
  }

  Future<void> sendMessage(String text) async {
    final msgId = DateTime.now().microsecondsSinceEpoch.toString();
    
    String encryptedBody = text;
    if (_encryptionEnabled) {
      final peers = _activeProvider?.connectedPeers ?? [];
      for (final peer in peers) {
        encryptedBody = _cryptoService.encryptMessage(text, peer);
        break;
      }
    }

    final msg = Message(
      id: msgId,
      senderName: _myName,
      senderAddress: _myAddress,
      body: encryptedBody,
      timestamp: DateTime.now(),
      status: MessageStatus.pending,
      isMe: true,
    );

    _messages.add(msg);
    _messagesController.add(List.from(_messages));
    await _messageStore.saveMessage(msg);

    bool sent = false;
    if (_activeProvider != null) {
      sent = await _activeProvider!.send(msg);
    }

    if (sent) {
      final sentMsg = msg.copyWith(status: MessageStatus.sent);
      final idx = _messages.indexWhere((m) => m.id == msg.id);
      if (idx != -1) _messages[idx] = sentMsg;
      _messagesController.add(List.from(_messages));
      await _messageStore.updateMessageStatus(msgId, MessageStatus.sent);
    } else {
      final failedMsg = msg.copyWith(status: MessageStatus.failed);
      final idx = _messages.indexWhere((m) => m.id == msg.id);
      if (idx != -1) _messages[idx] = failedMsg;
      _messagesController.add(List.from(_messages));
      await _messageStore.updateMessageStatus(msgId, MessageStatus.failed);
      _fallbackController.add(ConnectionType.wifiDirect);
    }
  }

  void _broadcastExcept(Message msg, {String? excludeAddress}) async {
    for (final peer in _activeProvider!.connectedPeers) {
      String encryptedBody = msg.body;
      if (_encryptionEnabled) {
        encryptedBody = _cryptoService.encryptMessage(msg.body, peer);
      }
      
      final relayMsg = Message(
        id: msg.id,
        senderName: msg.senderName,
        senderAddress: msg.senderAddress,
        body: encryptedBody,
        timestamp: msg.timestamp,
        status: MessageStatus.sent,
        isMe: msg.isMe,
      );
      
      await _btProvider.send(relayMsg);
    }
  }

  void acceptFallback(ConnectionType type) {
    if (type == ConnectionType.wifiDirect) {
      _activeProvider = _wifiProvider;
      _fallbackController.add(ConnectionType.wifiDirect);
    }
  }

  void _handleLeaderDisconnection() {
    _performElection();
  }

  void _performElection() {
    final peers = _activeProvider?.connectedPeers ?? [];
    peers.add(_myAddress);
    peers.sort();
    
    final newLeader = peers.first;
    
    if (newLeader == _myAddress) {
      _myRole = GroupRole.leader;
    } else {
      _myRole = GroupRole.peer;
      _leaderId = newLeader;
    }
    
    _roleController.add(_myRole);
  }

  Future<List<dynamic>> discoverDevices() async {
    return await _btProvider.discoverDevices();
  }

  void disconnect(String address) {
    _activeProvider?.disconnect(address);
    _notificationService.showConnectionNotification(
      deviceName: address,
      connected: false,
    );
    
    if (address == _leaderId) {
      _handleLeaderDisconnection();
    }
  }

  void addPeerKey(String peerAddress, String publicKey) {
    _cryptoService.addPeerKey(peerAddress, publicKey);
  }

  Future<void> resendPendingMessages() async {
    final pending = await _messageStore.getPendingMessages();
    for (final msg in pending) {
      await sendMessage(msg.body);
    }
  }

  Future<List<Message>> searchMessages(String query) async {
    return await _messageStore.searchMessages(query);
  }

  Future<void> clearHistory() async {
    await _messageStore.clearAll();
    _messages.clear();
    _messagesController.add(List.from(_messages));
  }

  void dispose() {
    _btProvider.dispose();
    _wifiProvider.dispose();
    _cryptoService.dispose();
    _messageStore.dispose();
    _roleController.close();
    _fallbackController.close();
    _messagesController.close();
  }
}