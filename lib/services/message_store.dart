import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/message.dart';

class MessageStore {
  static final MessageStore _instance = MessageStore._internal();
  factory MessageStore() => _instance;
  MessageStore._internal();

  Database? _db;
  final _pendingController = StreamController<List<Message>>.broadcast();
  final _updateController = StreamController<List<Message>>.broadcast();

  Stream<List<Message>> get pendingStream => _pendingController.stream;
  Stream<List<Message>> get messagesStream => _updateController.stream;

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'btchat_messages.db');

    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            senderName TEXT NOT NULL,
            senderAddress TEXT NOT NULL,
            body TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            status TEXT NOT NULL,
            isMe INTEGER NOT NULL
          )
        ''');
        
        await db.execute('''
          CREATE INDEX idx_timestamp ON messages(timestamp)
        ''');
        
        await db.execute('''
          CREATE INDEX idx_sender ON messages(senderAddress)
        ''');
      },
    );
  }

  Future<void> saveMessage(Message msg) async {
    if (_db == null) return;
    
    await _db!.insert(
      'messages',
      {
        'id': msg.id,
        'senderName': msg.senderName,
        'senderAddress': msg.senderAddress,
        'body': msg.body,
        'timestamp': msg.timestamp.toIso8601String(),
        'status': msg.status.name,
        'isMe': msg.isMe ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notifyUpdate();
  }

  Future<void> saveMessages(List<Message> messages) async {
    for (final msg in messages) {
      await saveMessage(msg);
    }
  }

  void _notifyUpdate() async {
    final messages = await loadMessages();
    _updateController.add(messages);
  }

  Future<List<Message>> loadMessages({int? limit, int? offset}) async {
    if (_db == null) return [];

    final results = await _db!.query(
      'messages',
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return results.map((row) => Message(
      id: row['id'] as String,
      senderName: row['senderName'] as String,
      senderAddress: row['senderAddress'] as String,
      body: row['body'] as String,
      timestamp: DateTime.parse(row['timestamp'] as String),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == row['status'],
        orElse: () => MessageStatus.delivered,
      ),
      isMe: (row['isMe'] as int) == 1,
    )).toList();
  }

  Future<List<Message>> loadMessagesFromContact(String senderAddress, {int? limit}) async {
    if (_db == null) return [];

    final results = await _db!.query(
      'messages',
      where: 'senderAddress = ?',
      whereArgs: [senderAddress],
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return results.map((row) => Message(
      id: row['id'] as String,
      senderName: row['senderName'] as String,
      senderAddress: row['senderAddress'] as String,
      body: row['body'] as String,
      timestamp: DateTime.parse(row['timestamp'] as String),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == row['status'],
        orElse: () => MessageStatus.delivered,
      ),
      isMe: (row['isMe'] as int) == 1,
    )).toList();
  }

  Future<List<Message>> searchMessages(String query) async {
    if (_db == null) return [];

    final results = await _db!.query(
      'messages',
      where: 'body LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'timestamp DESC',
    );

    return results.map((row) => Message(
      id: row['id'] as String,
      senderName: row['senderName'] as String,
      senderAddress: row['senderAddress'] as String,
      body: row['body'] as String,
      timestamp: DateTime.parse(row['timestamp'] as String),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == row['status'],
        orElse: () => MessageStatus.delivered,
      ),
      isMe: (row['isMe'] as int) == 1,
    )).toList();
  }

  Future<List<Message>> getMessagesByDateRange(DateTime start, DateTime end) async {
    if (_db == null) return [];

    final results = await _db!.query(
      'messages',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp ASC',
    );

    return results.map((row) => Message(
      id: row['id'] as String,
      senderName: row['senderName'] as String,
      senderAddress: row['senderAddress'] as String,
      body: row['body'] as String,
      timestamp: DateTime.parse(row['timestamp'] as String),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == row['status'],
        orElse: () => MessageStatus.delivered,
      ),
      isMe: (row['isMe'] as int) == 1,
    )).toList();
  }

  Future<List<Message>> getPendingMessages() async {
    if (_db == null) return [];

    final results = await _db!.query(
      'messages',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'timestamp ASC',
    );

    final pending = results.map((row) => Message(
      id: row['id'] as String,
      senderName: row['senderName'] as String,
      senderAddress: row['senderAddress'] as String,
      body: row['body'] as String,
      timestamp: DateTime.parse(row['timestamp'] as String),
      status: MessageStatus.pending,
      isMe: (row['isMe'] as int) == 1,
    )).toList();
    
    _pendingController.add(pending);
    return pending;
  }

  Future<void> updateMessageStatus(String id, MessageStatus status) async {
    if (_db == null) return;

    await _db!.update(
      'messages',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [id],
    );
    _notifyUpdate();
  }

  Future<void> deleteMessage(String id) async {
    if (_db == null) return;
    await _db!.delete('messages', where: 'id = ?', whereArgs: [id]);
    _notifyUpdate();
  }

  Future<void> clearAll() async {
    if (_db == null) return;
    await _db!.delete('messages');
    _notifyUpdate();
  }

  Future<void> clearContactHistory(String senderAddress) async {
    if (_db == null) return;
    await _db!.delete('messages', where: 'senderAddress = ?', whereArgs: [senderAddress]);
    _notifyUpdate();
  }

  Future<Map<String, int>> getContactStats() async {
    if (_db == null) return {};
    
    final results = await _db!.rawQuery('''
      SELECT senderAddress, COUNT(*) as count 
      FROM messages 
      GROUP BY senderAddress
    ''');
    
    return {
      for (final row in results)
        row['senderAddress'] as String: row['count'] as int
    };
  }

  Future<int> getTotalMessagesCount() async {
    if (_db == null) return 0;
    final result = await _db!.rawQuery('SELECT COUNT(*) as count FROM messages');
    return result.first['count'] as int;
  }

  Future<void> resendPending() async {
    final pending = await getPendingMessages();
    _pendingController.add(pending);
  }

  void dispose() {
    _pendingController.close();
    _updateController.close();
  }
}