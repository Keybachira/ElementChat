import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../managers/identity_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  late IdentityManager _identity;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _identity = IdentityManager();
    _loadSettings();
  }

  void _loadSettings() {
    _nameController.text = _identity.userName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty && name.length >= 2) {
      await _identity.updateName(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nome atualizado'),
            backgroundColor: Color(0xFF00C853),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _toggleVisibility(VisibilityMode mode) async {
    await _identity.setVisibility(mode);
  }

  Future<void> _toggleEncryption(bool enabled) async {
    await _identity.toggleEncryption(enabled);
  }

  Future<void> _clearData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141B2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Limpar dados', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Isso irá apagar seu histórico de mensagens e redefinir suas configurações. Tem certeza?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF8899AA))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Limpar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _identity.clearAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dados limpos. Reinicie o app.'),
            backgroundColor: Color(0xFF00E5FF),
          ),
        );
      }
    }
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
          'Configurações',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'PERFIL',
            children: [
              _buildSettingTile(
                icon: Icons.person_outline,
                title: 'Nome de usuário',
                subtitle: _identity.userName,
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF445566)),
                onTap: () => _showNameDialog(),
              ),
              _buildSettingTile(
                icon: Icons.phone_android,
                title: 'Endereço MAC',
                subtitle: _identity.myAddress.toUpperCase(),
                trailing: IconButton(
                  icon: const Icon(Icons.copy, size: 18, color: Color(0xFF445566)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _identity.myAddress));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Endereço copiado!'), backgroundColor: Color(0xFF00E5FF)),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'PRIVACIDADE',
            children: [
              _buildSettingTile(
                icon: _identity.visibility == VisibilityMode.visible 
                    ? Icons.visibility 
                    : Icons.visibility_off,
                title: 'Visibilidade',
                subtitle: _identity.visibility == VisibilityMode.visible 
                    ? 'Visível para outros dispositivos' 
                    : 'Oculto - apenas conexões manual',
                trailing: Switch(
                  value: _identity.visibility == VisibilityMode.visible,
                  activeColor: const Color(0xFF00E5FF),
                  onChanged: (v) => _toggleVisibility(v ? VisibilityMode.visible : VisibilityMode.hidden),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'SEGURANÇA',
            children: [
              _buildSettingTile(
                icon: Icons.lock_outline,
                title: 'Criptografia E2E',
                subtitle: _identity.encryptionEnabled 
                    ? 'Mensagens criptografadas' 
                    : 'Desabilitado',
                trailing: Switch(
                  value: _identity.encryptionEnabled,
                  activeColor: const Color(0xFF00E5FF),
                  onChanged: _toggleEncryption,
                ),
              ),
              _buildSettingTile(
                icon: Icons.key,
                title: 'Chave de criptografia',
                subtitle: '${_identity.encryptionKey.substring(0, 16)}...',
                trailing: IconButton(
                  icon: const Icon(Icons.copy, size: 18, color: Color(0xFF445566)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _identity.encryptionKey));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chave copiada!'), backgroundColor: Color(0xFF00E5FF)),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'DADOS',
            children: [
              _buildSettingTile(
                icon: Icons.delete_outline,
                title: 'Limpar dados',
                subtitle: 'Apagar histórico e configurações',
                titleColor: Colors.redAccent,
                onTap: _clearData,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'SOBRE',
            children: [
              _buildSettingTile(
                icon: Icons.info_outline,
                title: 'BT Chat',
                subtitle: 'Versão 1.0.0',
              ),
              _buildSettingTile(
                icon: Icons.bluetooth,
                title: 'Protocolo',
                subtitle: 'Bluetooth Classic (SPP)',
              ),
              _buildSettingTile(
                icon: Icons.wifi,
                title: 'Fallback',
                subtitle: 'Wi-Fi Direct (quando disponível)',
              ),
            ],
          ),
          const SizedBox(height: 40),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 2,
              color: Color(0xFF00E5FF),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141B2D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E2D42)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2D42),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF00E5FF)),
      ),
      title: Text(
        title,
        style: TextStyle(color: titleColor ?? Colors.white, fontWeight: FontWeight.w500, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF556677), fontSize: 12),
      ),
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _showNameDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141B2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editar nome', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _nameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Seu nome',
            hintStyle: const TextStyle(color: Color(0xFF445566)),
            filled: true,
            fillColor: const Color(0xFF0A0E1A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF8899AA))),
          ),
          TextButton(
            onPressed: () {
              _saveName();
              Navigator.pop(ctx);
            },
            child: const Text('Salvar', style: TextStyle(color: Color(0xFF00E5FF))),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.bluetooth, size: 24, color: Color(0xFF1E2D42)),
          const SizedBox(height: 8),
          Text(
            'Feito com 💙 para comunicação local',
            style: TextStyle(color: const Color(0xFF445566).withOpacity(0.6), fontSize: 12),
          ),
        ],
      ),
    );
  }
}