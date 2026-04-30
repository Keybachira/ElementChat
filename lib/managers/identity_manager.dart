import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum VisibilityMode { visible, hidden }

class IdentityManager {
  static final IdentityManager _instance = IdentityManager._internal();
  factory IdentityManager() => _instance;
  IdentityManager._internal();

  final FlutterBluetoothSerial _bt = FlutterBluetoothSerial.instance;
  SharedPreferences? _prefs;

  String _userName = 'User';
  String _myAddress = '';
  String _encryptionKey = '';
  VisibilityMode _visibility = VisibilityMode.visible;
  bool _encryptionEnabled = true;

  String get userName => _userName;
  String get myAddress => _myAddress;
  String get encryptionKey => _encryptionKey;
  VisibilityMode get visibility => _visibility;
  bool get encryptionEnabled => _encryptionEnabled;
  bool get isInitialized => _myAddress.isNotEmpty;

  StreamController<IdentityManager> get updateStream => _updateController;
  final _updateController = StreamController<IdentityManager>.broadcast();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();

    try {
      final status = await Permission.bluetoothConnect.request();
      if (status.isGranted) {
        final info = await _bt.address;
        _myAddress = info ?? 'unknown';
      } else {
        _myAddress = 'no_permission';
      }
    } catch (e) {
      debugPrint('Erro ao inicializar Bluetooth: $e');
      _myAddress = 'error';
    }

    if (_encryptionKey.isEmpty) {
      _generateEncryptionKey();
      _saveSettings();
    }

    _updateController.add(this);
  }

  void _loadSettings() {
    _userName = _prefs?.getString('userName') ?? 'User';
    _visibility = VisibilityMode.values[_prefs?.getInt('visibility') ?? 0];
    _encryptionEnabled = _prefs?.getBool('encryption') ?? true;
  }

  Future<void> _saveSettings() async {
    await _prefs?.setString('userName', _userName);
    await _prefs?.setInt('visibility', _visibility.index);
    await _prefs?.setBool('encryption', _encryptionEnabled);
  }

  void _generateEncryptionKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    _encryptionKey = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> setVisibility(VisibilityMode mode) async {
    _visibility = mode;
    if (mode == VisibilityMode.visible) {
      await _bt.requestDiscoverable(120);
    }
    await _saveSettings();
    _updateController.add(this);
  }

  Future<void> updateName(String name) async {
    _userName = name;
    await _saveSettings();
    _updateController.add(this);
  }

  Future<void> toggleEncryption(bool enabled) async {
    _encryptionEnabled = enabled;
    await _saveSettings();
    _updateController.add(this);
  }

  Future<void> clearAllData() async {
    await _prefs?.clear();
    _userName = 'User';
    _visibility = VisibilityMode.visible;
    _encryptionEnabled = true;
    _generateEncryptionKey();
    await _saveSettings();
    _updateController.add(this);
  }

  void dispose() {
    _updateController.close();
  }
}
