import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../controllers/mesh_controller.dart';
import '../providers/connection_engine.dart';
import '../core/theme/element_palette.dart';
import 'chat_screen.dart';
import 'qr_group_screen.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final _meshController = MeshController();
  List<BluetoothDevice> _found = [];
  final Set<String> _connecting = {};
  final Set<String> _connected = {};
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _setupFallbackListener();
    _scan();
  }

  void _setupFallbackListener() {
    _meshController.fallbackStream.listen((type) {
      if (type == ConnectionType.wifiDirect) {
        _showWifiSuggestion();
      }
    });
  }

  void _showWifiSuggestion() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141B2D),
        title: const Text('Conexão lenta', style: TextStyle(color: Colors.white)),
        content: const Text(
          'A conexão Bluetooth está lenta. Deseja mudar para Wi-Fi Direct para maior velocidade?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Agora não', style: TextStyle(color: Color(0xFF8899AA))),
          ),
          TextButton(
            onPressed: () {
              _meshController.acceptFallback(ConnectionType.wifiDirect);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mudando para Wi-Fi Direct...'),
                  backgroundColor: Color(0xFF00E5FF),
                ),
              );
            },
            child: const Text('Mudar', style: TextStyle(color: Color(0xFF00E5FF))),
          ),
        ],
      ),
    );
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _found = [];
    });

    final enabled = await FlutterBluetoothSerial.instance.isEnabled ?? false;
    if (!enabled) {
      await FlutterBluetoothSerial.instance.requestEnable();
    }

    final devices = await _meshController.discoverDevices();
    if (mounted) {
      setState(() {
        _found = devices.cast();
        _scanning = false;
      });
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() => _connecting.add(device.address));
    final ok = await _meshController.connectTo(device.address);
    if (mounted) {
      setState(() {
        _connecting.remove(device.address);
        if (ok) _connected.add(device.address);
      });
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conectado a ${device.name ?? device.address}'),
            backgroundColor: const Color(0xFF00C853),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao conectar com ${device.name ?? device.address}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _goToChat() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        foregroundColor: Colors.white,
        title: const Text(
          'Descobrir dispositivos',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.of(context).push<dynamic>(
                MaterialPageRoute(builder: (_) => const QRGroupScreen()),
              );
              if (result != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Grupo selecionado: ${result.groupName}'),
                    backgroundColor: ElementPalette.success,
                  ),
                );
              }
            },
            icon: const Icon(Icons.qr_code, color: ElementPalette.accent),
            tooltip: 'QR Code do Grupo',
          ),
          if (_connected.isNotEmpty)
            TextButton.icon(
              onPressed: _goToChat,
              icon: const Icon(Icons.chat_bubble_outline,
                  color: Color(0xFF00E5FF), size: 18),
              label: const Text(
                'ABRIR CHAT',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF141B2D),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E2D42)),
            ),
            child: Row(
              children: [
                Icon(
                  _scanning ? Icons.radar : Icons.bluetooth,
                  color: const Color(0xFF00E5FF),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _scanning
                        ? 'Procurando dispositivos...'
                        : '${_found.length} dispositivo(s) encontrado(s)',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
                if (_connected.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF00C853).withOpacity(0.4)),
                    ),
                    child: Text(
                      '${_connected.length} conectado(s)',
                      style: const TextStyle(
                          color: Color(0xFF00C853),
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: _scanning && _found.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF00E5FF),
                          strokeWidth: 2,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Procurando via Bluetooth...',
                          style: TextStyle(color: Color(0xFF8899AA)),
                        ),
                      ],
                    ),
                  )
                : _found.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.bluetooth_disabled,
                                size: 56, color: Color(0xFF2D3A4A)),
                            const SizedBox(height: 16),
                            const Text(
                              'Nenhum dispositivo encontrado.',
                              style: TextStyle(color: Color(0xFF445566)),
                            ),
                            const SizedBox(height: 24),
                            OutlinedButton.icon(
                              onPressed: _scan,
                              icon: const Icon(Icons.refresh,
                                  color: Color(0xFF00E5FF)),
                              label: const Text('Tentar novamente',
                                  style:
                                      TextStyle(color: Color(0xFF00E5FF))),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Color(0xFF00E5FF)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _found.length,
                        itemBuilder: (_, i) {
                          final device = _found[i];
                          final isConnecting =
                              _connecting.contains(device.address);
                          final isConnected =
                              _connected.contains(device.address);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141B2D),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isConnected
                                    ? const Color(0xFF00C853).withOpacity(0.5)
                                    : const Color(0xFF1E2D42),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              leading: CircleAvatar(
                                backgroundColor: isConnected
                                    ? const Color(0xFF00C853).withOpacity(0.15)
                                    : const Color(0xFF1E2D42),
                                child: Icon(
                                  isConnected
                                      ? Icons.bluetooth_connected
                                      : Icons.bluetooth,
                                  color: isConnected
                                      ? const Color(0xFF00C853)
                                      : const Color(0xFF00E5FF),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                device.name ?? 'Dispositivo desconhecido',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                device.address,
                                style: const TextStyle(
                                    color: Color(0xFF556677), fontSize: 12),
                              ),
                              trailing: isConnecting
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF00E5FF),
                                      ),
                                    )
                                  : isConnected
                                      ? const Icon(Icons.check_circle,
                                          color: Color(0xFF00C853))
                                      : ElevatedButton(
                                          onPressed: () => _connect(device),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF00E5FF),
                                            foregroundColor:
                                                const Color(0xFF0A0E1A),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text('CONECTAR',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1)),
                                        ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: !_scanning
          ? FloatingActionButton(
              onPressed: _scan,
              backgroundColor: const Color(0xFF00E5FF),
              child: const Icon(Icons.refresh, color: Color(0xFF0A0E1A)),
            )
          : null,
    );
  }
}