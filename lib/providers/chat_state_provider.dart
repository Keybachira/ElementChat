import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../controllers/mesh_controller.dart';
import '../services/lru_cache.dart';

class ChatStateProvider extends ChangeNotifier {
  final MeshController _meshController = MeshController();
  
  final List<Message> _messages = [];
  final MessageCache _messageCache = MessageCache();
  
  List<String> _peers = [];
  GroupRole _role = GroupRole.peer;
  bool _isConnected = false;

  StreamSubscription? _messagesSub;
  StreamSubscription? _roleSub;

  List<Message> get messages => List.unmodifiable(_messages);
  List<String> get peers => List.unmodifiable(_peers);
  GroupRole get role => _role;
  bool get isConnected => _isConnected;

  void init() {
    _loadFromCache();
    
    _messagesSub = _meshController.messagesStream.listen((msgs) {
      _updateMessages(msgs);
    });

    _roleSub = _meshController.roleStream.listen((role) {
      _role = role;
      notifyListeners();
    });

    _updateConnectionStatus();
  }

  void _loadFromCache() {
    final cached = _messageCache.getRecentMessages();
    for (final msg in cached.reversed) {
      _messages.add(Message(
        id: msg.id,
        senderName: msg.senderName,
        senderAddress: msg.senderAddress,
        body: msg.body,
        timestamp: msg.timestamp,
        status: MessageStatus.delivered,
        isMe: msg.isMe,
      ));
    }
  }

  void _updateMessages(List<Message> newMessages) {
    final oldLength = _messages.length;
    
    if (newMessages.length > oldLength) {
      final newMsgs = newMessages.sublist(oldLength);
      
      for (final msg in newMsgs) {
        _messages.add(msg);
        _messageCache.addMessage(
          msg.id, 
          msg.senderName, 
          msg.senderAddress, 
          msg.body, 
          msg.timestamp, 
          msg.isMe,
        );
      }
      
      if (_messages.length > 200) {
        final removed = _messages.sublist(0, _messages.length - 200);
        _messages.removeRange(0, _messages.length - 200);
        for (final msg in removed) {
          _messageCache.removeMessage(msg.id);
        }
      }
      
      notifyListeners();
    }
  }

  void _updateConnectionStatus() {
    _peers = _meshController.connectedPeers;
    _isConnected = _peers.isNotEmpty;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    await _meshController.sendMessage(text);
  }

  void refreshPeers() {
    _updateConnectionStatus();
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _roleSub?.cancel();
    super.dispose();
  }
}

class ChatMessageSelector {
  static List<Message> messages(List<Message> all) => all;
  
  static String roleLabel(GroupRole role) => role == GroupRole.leader ? 'líder' : 'peer';
  
  static int peerCount(List<String> peers) => peers.length;
}
