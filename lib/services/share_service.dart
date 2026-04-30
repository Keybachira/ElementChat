import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  static String buildInviteMessage(String userName) {
    final normalizedName = userName.trim().isEmpty ? 'um amigo' : userName.trim();

    return '''
Entra no Element Chat comigo.

Chat 100% offline por Bluetooth: sem internet, sem saldo e sem servidor.

$normalizedName ja esta no app. Instala o APK, abre o Element Chat e entra na rede local em poucos segundos.

Partilha este APK com o teu grupo para a rede crescer mais rapido.
''';
  }

  static Future<ShareResult> shareAppInvite({
    required BuildContext context,
    required String userName,
  }) async {
    final box = context.findRenderObject() as RenderBox?;
    final inviteText = buildInviteMessage(userName);

    final params = ShareParams(
      title: 'Partilhar Element Chat',
      subject: 'Convite para o Element Chat',
      text: inviteText,
      sharePositionOrigin: box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    );

    return SharePlus.instance.share(params);
  }
}
