import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';

enum MessageStatus { pending, sent, relayed, delivered, failed }

class Message {
  final String id;
  final String senderName;
  final String senderAddress;
  final String body;
  final DateTime timestamp;
  final MessageStatus status;
  final bool isMe;
  final List<String> seenBy;

  Message({
    required this.id,
    required this.senderName,
    required this.senderAddress,
    required this.body,
    required this.timestamp,
    this.status = MessageStatus.sent,
    required this.isMe,
    this.seenBy = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderName': senderName,
        'senderAddress': senderAddress,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
        'status': status.name,
        'seenBy': seenBy,
      };

  factory Message.fromJson(Map<String, dynamic> json, String myAddress) {
    final seenList = json['seenBy'] as List<dynamic>?;
    return Message(
      id: json['id'],
      senderName: json['senderName'],
      senderAddress: json['senderAddress'],
      body: json['body'],
      timestamp: DateTime.parse(json['timestamp']),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.delivered,
      ),
      isMe: json['senderAddress'] == myAddress,
      seenBy: seenList?.cast<String>() ?? [],
    );
  }

  Message copyWith({
    MessageStatus? status,
    List<String>? seenBy,
  }) =>
      Message(
        id: id,
        senderName: senderName,
        senderAddress: senderAddress,
        body: body,
        timestamp: timestamp,
        status: status ?? this.status,
        isMe: isMe,
        seenBy: seenBy ?? this.seenBy,
      );

  Message addSeen(String address) {
    if (seenBy.contains(address)) return this;
    return copyWith(seenBy: [...seenBy, address]);
  }

  bool hasSeen(String address) => seenBy.contains(address);
}

Uint8List compressMessage(String data) {
  if (data.length < 200) {
    return Uint8List.fromList(utf8.encode(data));
  }
  final compressed = GZipEncoder().encode(utf8.encode(data));
  return Uint8List.fromList(compressed ?? utf8.encode(data));
}

String decompressMessage(Uint8List data) {
  try {
    final decompressed = GZipDecoder().decodeBytes(data);
    return utf8.decode(decompressed);
  } catch (_) {
    return utf8.decode(data);
  }
}

class GroupInfo {
  final String groupId;
  final String groupName;
  final String leaderAddress;
  final List<String> peerAddresses;
  final DateTime createdAt;

  GroupInfo({
    required this.groupId,
    required this.groupName,
    required this.leaderAddress,
    this.peerAddresses = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'groupId': groupId,
        'groupName': groupName,
        'leaderAddress': leaderAddress,
        'peerAddresses': peerAddresses,
        'createdAt': createdAt.toIso8601String(),
      };

  factory GroupInfo.fromJson(Map<String, dynamic> json) {
    return GroupInfo(
      groupId: json['groupId'],
      groupName: json['groupName'],
      leaderAddress: json['leaderAddress'],
      peerAddresses: List<String>.from(json['peerAddresses'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  String toQRData() => base64Encode(utf8.encode(jsonEncode(toJson())));

  factory GroupInfo.fromQRData(String qrData) {
    try {
      final json = jsonDecode(utf8.decode(base64Decode(qrData)));
      return GroupInfo.fromJson(json);
    } catch (_) {
      return GroupInfo(
        groupId: '',
        groupName: '',
        leaderAddress: '',
      );
    }
  }
}
