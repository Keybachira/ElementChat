import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/element_palette.dart';
import '../core/theme/element_typography.dart';
import '../models/message.dart';
import '../services/lru_cache.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool showHeader;
  final Color? senderColor;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    this.showHeader = true,
    this.senderColor,
    this.onLongPress,
  });

  Color get _effectiveColor {
    if (senderColor != null) return senderColor!;
    return Color(ColorCache.getColorForAddress(message.senderAddress));
  }

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    return RepaintBoundary(
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Padding(
          padding: EdgeInsets.only(
            top: showHeader ? 12 : 2,
            bottom: 2,
          ),
          child: Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                _buildAvatar(),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (showHeader && !isMe) _buildSenderName(),
                    _buildBubble(isMe),
                  ],
                ),
              ),
              if (isMe) const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 14,
      backgroundColor: _effectiveColor.withOpacity(0.15),
      child: Text(
        message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
        style: TextStyle(
          color: _effectiveColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSenderName() {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        message.senderName,
        style: TextStyle(
          color: _effectiveColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBubble(bool isMe) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: isMe ? ElementPalette.messageBubbleGradient : null,
        color: isMe ? null : ElementPalette.surface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        border: Border.all(
          color: isMe ? ElementPalette.primary.withOpacity(0.3) : ElementPalette.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            message.body,
            style: ElementTypography.body.copyWith(height: 1.4),
          ),
          const SizedBox(height: 4),
          _buildStatusRow(isMe),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(begin: isMe ? 0.1 : -0.1, end: 0);
  }

  Widget _buildStatusRow(bool isMe) {
    if (!isMe) {
      return Text(
        _formatTime(message.timestamp),
        style: ElementTypography.caption.copyWith(color: ElementPalette.muted),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(message.timestamp),
          style: ElementTypography.caption.copyWith(color: ElementPalette.muted),
        ),
        const SizedBox(width: 4),
        _buildStatusIcon(),
      ],
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (message.status) {
      case MessageStatus.pending:
        icon = Icons.access_time;
        color = ElementPalette.warning;
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        color = ElementPalette.muted;
        break;
      case MessageStatus.relayed:
        icon = Icons.forward;
        color = ElementPalette.accent;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = ElementPalette.success;
        break;
      case MessageStatus.failed:
        icon = Icons.error_outline;
        color = ElementPalette.danger;
        break;
    }

    return Icon(icon, size: 14, color: color)
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 2.seconds,
          color: message.status == MessageStatus.pending
              ? ElementPalette.warning.withOpacity(0.5)
              : Colors.transparent,
        );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
