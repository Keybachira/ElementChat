import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class CryptoService {
  static final CryptoService _instance = CryptoService._internal();
  factory CryptoService() => _instance;
  CryptoService._internal();

  encrypt.Key? _key;
  encrypt.IV? _iv;
  final Map<String, encrypt.Key> _peerKeys = {};

  void init() {
    final random = Random.secure();
    final keyBytes = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    _key = encrypt.Key(keyBytes);
    final ivBytes = Uint8List.fromList(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
    _iv = encrypt.IV(ivBytes);
  }

  String get publicKeyBase64 {
    if (_key == null) init();
    return base64Encode(_key!.bytes);
  }

  void addPeerKey(String peerAddress, String publicKeyBase64) {
    try {
      final keyBytes = base64Decode(publicKeyBase64);
      _peerKeys[peerAddress] = encrypt.Key(Uint8List.fromList(keyBytes));
    } catch (_) {}
  }

  encrypt.Key _getKeyForPeer(String peerAddress) {
    if (_peerKeys.containsKey(peerAddress)) {
      return _peerKeys[peerAddress]!;
    }
    return _key!;
  }

  String encryptMessage(String plainText, String peerAddress) {
    if (_key == null) init();
    
    final key = _getKeyForPeer(peerAddress);
    final iv = encrypt.IV.fromSecureRandom(12);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    
    return '${iv.base64}:${encrypted.base64}';
  }

  String decryptMessage(String encryptedData, String peerAddress) {
    if (_key == null) init();
    
    try {
      final parts = encryptedData.split(':');
      if (parts.length != 2) return encryptedData;
      
      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
      
      final key = _peerKeys[peerAddress] ?? _key!;
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
      
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (_) {
      return encryptedData;
    }
  }

  String getPublicKeyForExchange() {
    if (_key == null) init();
    return _key!.bytes.fold('', (prev, b) => prev + b.toRadixString(16).padLeft(2, '0'));
  }

  void dispose() {
    _peerKeys.clear();
  }
}