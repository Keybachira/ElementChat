import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/theme/element_palette.dart';
import '../core/theme/element_typography.dart';
import '../models/message.dart';
import '../managers/identity_manager.dart';
import '../controllers/mesh_controller.dart';

class QRGroupScreen extends StatefulWidget {
  final GroupInfo? existingGroup;

  const QRGroupScreen({super.key, this.existingGroup});

  @override
  State<QRGroupScreen> createState() => _QRGroupScreenState();
}

class _QRGroupScreenState extends State<QRGroupScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isGenerating = false;
  GroupInfo? _currentGroup;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentGroup = widget.existingGroup ?? _createNewGroup();
  }

  GroupInfo _createNewGroup() {
    final identity = IdentityManager();
    return GroupInfo(
      groupId: DateTime.now().millisecondsSinceEpoch.toString(),
      groupName: '${identity.userName}\'s Group',
      leaderAddress: identity.myAddress,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _joinGroup(String qrData) {
    final groupInfo = GroupInfo.fromQRData(qrData);
    if (groupInfo.groupId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR Code inválido'),
          backgroundColor: ElementPalette.danger,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Entrando no grupo: ${groupInfo.groupName}'),
        backgroundColor: ElementPalette.success,
      ),
    );

    Navigator.of(context).pop(groupInfo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElementPalette.bg,
      appBar: AppBar(
        backgroundColor: ElementPalette.bg,
        foregroundColor: Colors.white,
        title: const Text('QR Code do Grupo'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: ElementPalette.primary,
          labelColor: ElementPalette.primary,
          unselectedLabelColor: ElementPalette.muted,
          tabs: const [
            Tab(text: 'MEU QR', icon: Icon(Icons.qr_code)),
            Tab(text: 'ESCANEAR', icon: Icon(Icons.qr_code_scanner)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyQRTab(),
          _buildScanTab(),
        ],
      ),
    );
  }

  Widget _buildMyQRTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: QrImageView(
              data: _currentGroup?.toQRData() ?? '',
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: ElementPalette.primary,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
          const SizedBox(height: 32),
          Text(
            _currentGroup?.groupName ?? 'Grupo',
            style: ElementTypography.title.copyWith(color: Colors.white),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'Líder: ${_currentGroup?.leaderAddress.toUpperCase() ?? ""}',
            style: ElementTypography.caption.copyWith(color: ElementPalette.muted),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.share, size: 16, color: ElementPalette.muted),
              const SizedBox(width: 8),
              Text(
                'Mostre este QR para outros joinharem ao grupo',
                style: ElementTypography.caption.copyWith(color: ElementPalette.muted),
              ),
            ],
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _currentGroup = _createNewGroup();
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Gerar novo código'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ElementPalette.primary,
              side: const BorderSide(color: ElementPalette.primary),
            ),
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }

  Widget _buildScanTab() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    _joinGroup(barcode.rawValue!);
                    break;
                  }
                }
              },
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.qr_code_scanner,
                  size: 40,
                  color: ElementPalette.accent,
                ),
                const SizedBox(height: 12),
                Text(
                  'Aponte a câmera para o QR Code\ndo grupo que deseja entrar',
                  style: ElementTypography.bodySmall.copyWith(color: ElementPalette.muted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class QRScannerOverlay extends StatelessWidget {
  final double scanWindowSize;

  const QRScannerOverlay({
    super.key,
    this.scanWindowSize = 280,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.5),
            BlendMode.srcOut,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Center(
                child: Container(
                  width: scanWindowSize,
                  height: scanWindowSize,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: Container(
            width: scanWindowSize,
            height: scanWindowSize,
            decoration: BoxDecoration(
              border: Border.all(
                color: ElementPalette.accent,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  child: _buildCorner(),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: _buildCorner(rotation: 90),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: _buildCorner(rotation: 270),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: _buildCorner(rotation: 180),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCorner({double rotation = 0}) {
    return Transform.rotate(
      angle: rotation * 3.14159 / 180,
      child: Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: ElementPalette.accent, width: 4),
            left: BorderSide(color: ElementPalette.accent, width: 4),
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
          ),
        ),
      ),
    );
  }
}