# 📡 Element Chat— Chat em grupo via Bluetooth

App Flutter para chat em grupo **sem internet**, usando Bluetooth Clássico (SPP) com fallback para Wi-Fi Direct e criptografia E2E.

---

## 🏗 Arquitetura (UML)

```
lib/
├── main.dart                         # Entry point
├── models/
│   └── message.dart                  # Modelo de dados (ID, status, etc)
├── managers/
│   └── identity_manager.dart         # Registro local, chaves, visibilidade
├── providers/
│   ├── connection_engine.dart        # Classe abstrata (connect, send)
│   ├── bluetooth_provider.dart       # Implementação BT Classic
│   └── wifi_direct_provider.dart    # Implementação Wi-Fi Direct (placeholder)
├── controllers/
│   └── mesh_controller.dart          # Eleição de líder, relay, fallback, E2E
├── services/
│   ├── crypto_service.dart           # Criptografia AES-GCM E2E
│   ├── notification_service.dart    # Notificações locais
│   └── message_store.dart           # SQLite para sync offline
└── screens/
    ├── home_screen.dart              # Configurar nome
    ├── discovery_screen.dart        # Escanear e conectar
    └── chat_screen.dart             # Interface de chat
```

### Fluxo de Dados

```
Dispositivo A  ←──BT──→  Dispositivo B  ←──BT──→  Dispositivo C
                               (relay)
```

- **Eleição de Líder:** Quem cria o chat assume papel de Group Owner
- **Fallback:** Se latência > 2s ou pacote > 1KB, sugere mudança para Wi-Fi
- **Sincronização:** Mensagens salvas localmente (SQLite) + broadcast na rede
- **Pending:** Se destinatário offline, marca como "Pendente" e reenvia quando voltar
- **E2E:** Criptografia AES-GCM para todas as mensagens

---

## 🚀 Setup

### 1. Instalar dependências

```bash
flutter pub get
```

### 2. Android (totalmente suportado)

```bash
flutter run
```

**Versão mínima recomendada:** Android 6.0 (API 23)

---

## 📦 Dependências

| Pacote | Uso |
|--------|-----|
| `flutter_bluetooth_serial` | Bluetooth Clássico no Android |
| `sqflite` | Armazenamento local de mensagens |
| `path` | Manipulação de caminhos de arquivo |
| `encrypt` | Criptografia AES-GCM |
| `flutter_local_notifications` | Notificações locais |
| `shared_preferences` | Armazenamento de preferências |

---

## 🔐 Características Implementadas

- [x] Mesh relay automático
- [x] Eleição automática de líder
- [x] Monitoramento de performance (latência/tamanho pacote)
- [x] Sugestão de fallback Wi-Fi Direct
- [x] Escrita atômica (SQLite + broadcast)
- [x] Mensagens pendentes e reenvio
- [x] Criptografia E2E (AES-GCM)
- [x] Notificações locais
- [x] Histórico local completo (busca, filtros)

---

## 📡 Protocolo

Mensagens JSON delimitadas por `\n` sobre SPP (RFCOMM / Serial Port Profile).

```json
{"id":"123","senderName":"User1","senderAddress":"AA:BB:CC:DD","body":"crypted_data","timestamp":"2026-04-27T10:30:00Z","status":"sent"}
```

---

## 📱 Próximas Melhorias Sugeridas

- Suporte completo a Wi-Fi Direct
- Criptografia X25519 (troca de chaves Diffie-Hellman)
- Notificações em background (workmanager)
- Indicador de "digitando..."
- Suporte a emojis e reações
- Backup/export de histórico
