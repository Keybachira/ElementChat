import 'dart:collection';

class LRUCache<K, V> {
  final int maxSize;
  final LinkedHashMap<K, V> _cache = LinkedHashMap<K, V>();

  LRUCache(this.maxSize);

  V? get(K key) {
    if (!_cache.containsKey(key)) return null;
    
    final value = _cache.remove(key)!;
    _cache[key] = value;
    return value;
  }

  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  V? remove(K key) => _cache.remove(key);

  void clear() => _cache.clear();

  bool containsKey(K key) => _cache.containsKey(key);

  int get length => _cache.length;
  bool get isEmpty => _cache.isEmpty;
  bool get isNotEmpty => _cache.isNotEmpty;

  List<V> get values => _cache.values.toList();
  List<K> get keys => _cache.keys.toList();

  V? get first => _cache.isEmpty ? null : _cache.values.first;
  V? get last => _cache.isEmpty ? null : _cache.values.last;
}

class MessageCache {
  static final MessageCache _instance = MessageCache._internal();
  factory MessageCache() => _instance;
  MessageCache._internal();

  static const int _maxMessages = 200;
  final LRUCache<String, _CachedMessage> _cache = LRUCache(_maxMessages);

  void addMessage(String id, String senderName, String senderAddress, String body, DateTime timestamp, bool isMe) {
    _cache.put(id, _CachedMessage(
      id: id,
      senderName: senderName,
      senderAddress: senderAddress,
      body: body,
      timestamp: timestamp,
      isMe: isMe,
    ));
  }

  List<_CachedMessage> getRecentMessages({int? limit}) {
    final messages = _cache.values.toList();
    messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (limit != null && messages.length > limit) {
      return messages.sublist(0, limit);
    }
    return messages;
  }

  _CachedMessage? getMessage(String id) => _cache.get(id);

  bool hasMessage(String id) => _cache.containsKey(id);

  void removeMessage(String id) => _cache.remove(id);

  void clear() => _cache.clear();

  int get count => _cache.length;
}

class _CachedMessage {
  final String id;
  final String senderName;
  final String senderAddress;
  final String body;
  final DateTime timestamp;
  final bool isMe;

  _CachedMessage({
    required this.id,
    required this.senderName,
    required this.senderAddress,
    required this.body,
    required this.timestamp,
    required this.isMe,
  });
}

class ColorCache {
  static final Map<String, int> _colorCache = {};
  
  static const List<int> _colorValues = [
    0xFF00E5FF,
    0xFFFF6B6B,
    0xFFFFD93D,
    0xFF6BCB77,
    0xFFFF8C42,
    0xFFAA88FF,
  ];

  static int getColorForAddress(String address) {
    if (!_colorCache.containsKey(address)) {
      _colorCache[address] = _colorValues[address.hashCode.abs() % _colorValues.length];
    }
    return _colorCache[address]!;
  }

  static void clear() => _colorCache.clear();
}