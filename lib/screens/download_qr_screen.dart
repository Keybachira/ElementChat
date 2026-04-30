import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadQrScreen extends StatefulWidget {
  final String userName;

  const DownloadQrScreen({
    super.key,
    required this.userName,
  });

  @override
  State<DownloadQrScreen> createState() => _DownloadQrScreenState();
}

class _DownloadQrScreenState extends State<DownloadQrScreen> {
  static const _downloadUrlKey = 'app_download_url';

  final _linkController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  String get _downloadUrl => _linkController.text.trim();
  bool get _hasValidUrl => _isValidUrl(_downloadUrl);

  @override
  void initState() {
    super.initState();
    _loadSavedUrl();
  }

  Future<void> _loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_downloadUrlKey) ?? '';

    if (!mounted) return;

    setState(() {
      _linkController.text = savedUrl;
    });
  }

  Future<void> _saveUrl() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_downloadUrlKey, _downloadUrl);

    if (!mounted) return;

    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link de download guardado. O QR ja esta pronto.'),
        backgroundColor: Color(0xFF00C853),
      ),
    );
  }

  Future<void> _copyLink() async {
    if (!_hasValidUrl) return;

    await Clipboard.setData(ClipboardData(text: _downloadUrl));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copiado.'),
        backgroundColor: Color(0xFF00E5FF),
      ),
    );
  }

  bool _isValidUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'QR para download',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeroCard(),
          const SizedBox(height: 20),
          _buildLinkForm(),
          const SizedBox(height: 20),
          _buildQrCard(),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF141B2D),
            Color(0xFF10182A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E2D42)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF00E5FF), size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mostra o QR e acelera a instalacao',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Cola aqui o link do APK no Drive, GitHub Releases ou no teu site. O pessoal escaneia e baixa.',
                  style: TextStyle(
                    color: Color(0xFF8A97AB),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkForm() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141B2D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E2D42)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Link do APK',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Exemplo: https://teusite.com/element-chat.apk',
              style: TextStyle(
                color: Color(0xFF778899),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _linkController,
              keyboardType: TextInputType.url,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'https://...',
                hintStyle: const TextStyle(color: Color(0xFF556677)),
                filled: true,
                fillColor: const Color(0xFF0D1424),
                prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF00E5FF)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF1E2D42)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 2),
                ),
              ),
              onChanged: (_) => setState(() {}),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Cola um link para gerar o QR.';
                }
                if (!_isValidUrl(value.trim())) {
                  return 'Usa um link http ou https valido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveUrl,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: const Color(0xFF0A0E1A),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF0A0E1A),
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_isSaving ? 'A guardar...' : 'Guardar link'),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  onPressed: _hasValidUrl ? _copyLink : null,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1A2338),
                    foregroundColor: const Color(0xFF00E5FF),
                    minimumSize: const Size(52, 52),
                  ),
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141B2D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E2D42)),
      ),
      child: Column(
        children: [
          if (_hasValidUrl) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: QrImageView(
                data: _downloadUrl,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF00E5FF),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Escaneia para abrir o download',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.userName.trim().isEmpty
                  ? 'Quem escanear vai abrir o link do APK diretamente.'
                  : '${widget.userName} ja deixou o QR pronto para entrar no app.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8A97AB),
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _downloadUrl,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFF0D1424),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1E2D42)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_2_rounded, size: 64, color: Color(0xFF445566)),
                  SizedBox(height: 12),
                  Text(
                    'Ainda sem link',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Guarda um link de download para gerar o QR automaticamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8A97AB),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
