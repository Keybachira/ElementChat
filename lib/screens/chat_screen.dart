import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../controllers/mesh_controller.dart';
import '../models/message.dart';
import '../core/theme/element_palette.dart';
import '../widgets/message_bubble.dart' as v2;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _meshController = MeshController();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocusNode = FocusNode();

  final List<Message> _messages = [];
  final Map<String, Color> _senderColors = {};
  
  StreamSubscription? _messagesSub;
  String _roleLabel = 'peer';

  static const int _maxMessagesInMemory = 200;

  @override
  void initState() {
    super.initState();
    _messages.addAll(_meshController.messages);
    if (_messages.length > _maxMessagesInMemory) {
      _messages.removeRange(0, _messages.length - _maxMessagesInMemory);
    }

    _messagesSub = _meshController.messagesStream.listen(_onMessageReceived);
    _meshController.roleStream.listen((role) {
      setState(() => _roleLabel = role == GroupRole.leader ? 'líder' : 'peer');
    });
  }

  void _onMessageReceived(List<Message> msgs) {
    if (msgs.length > _messages.length) {
      final newMessages = msgs.sublist(_messages.length);
      _messages.addAll(newMessages);
      
      if (_messages.length > _maxMessagesInMemory) {
        _messages.removeRange(0, _messages.length - _maxMessagesInMemory);
      }
      
      if (mounted) {
        setState(() {});
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Color _getColorForSender(String address) {
    if (!_senderColors.containsKey(address)) {
      final colors = [
        ElementPalette.accent,
        const Color(0xFFFF6B6B),
        const Color(0xFFFFD93D),
        const Color(0xFF6BCB77),
        const Color(0xFFFF8C42),
        const Color(0xFFAA88FF),
      ];
      final idx = address.hashCode.abs() % colors.length;
      _senderColors[address] = colors[idx];
    }
    return _senderColors[address]!;
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    await _meshController.sendMessage(text);
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElementPalette.bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildPeersRow(),
          const Divider(height: 1, color: ElementPalette.border),
          Expanded(child: _buildMessagesList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: ElementPalette.surface,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'ElementChat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _roleLabel == 'líder' 
                      ? ElementPalette.warning.withOpacity(0.2)
                      : ElementPalette.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _roleLabel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    color: _roleLabel == 'líder' 
                        ? ElementPalette.warning
                        : ElementPalette.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Text(
            _meshController.connectedPeers.isEmpty
                ? 'Sem conexões'
                : '${_meshController.connectedPeers.length} peer(s)',
            style: const TextStyle(fontSize: 11, color: ElementPalette.muted),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code, color: ElementPalette.accent),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildPeersRow() {
    final peers = _meshController.connectedPeers;
    if (peers.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 48,
      color: ElementPalette.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: peers.length,
        itemBuilder: (_, i) {
          final name = peers[i];
          final color = _getColorForSender(name);
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(name, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: ElementPalette.border),
            const SizedBox(height: 16),
            const Text('Nenhuma mensagem ainda.', style: TextStyle(color: ElementPalette.muted)),
            const SizedBox(height: 8),
            Text(
              _meshController.connectedPeers.isEmpty ? 'Conecte-se para começar.' : 'Diga olá!',
              style: const TextStyle(color: ElementPalette.muted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      cacheExtent: 500,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final prevMsg = index > 0 ? _messages[index - 1] : null;
        final showHeader = prevMsg == null || prevMsg.senderAddress != msg.senderAddress;

        return RepaintBoundary(
          key: ValueKey(msg.id),
          child: v2.MessageBubble(
            message: msg,
            showHeader: showHeader,
            senderColor: _getColorForSender(msg.senderAddress),
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: ElementPalette.surface,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _inputFocusNode,
              style: const TextStyle(color: Colors.white),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Mensagem...',
                hintStyle: const TextStyle(color: ElementPalette.muted),
                filled: true,
                fillColor: ElementPalette.bg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: ElementPalette.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}