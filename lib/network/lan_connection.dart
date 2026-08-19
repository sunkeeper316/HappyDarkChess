import 'dart:async';
import 'dart:convert';
import 'dart:io';

class LanHost {
  HttpServer? _server;
  WebSocket? _peer;
  StreamSubscription<dynamic>? _peerSubscription;
  void Function(int index)? onRemoteTap;
  void Function(bool connected)? onConnectionChanged;

  Future<String> start({int port = 4040}) async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _server!.listen((request) async {
      if (!WebSocketTransformer.isUpgradeRequest(request)) {
        request.response
          ..statusCode = HttpStatus.badRequest
          ..write('HappyDarkChess WebSocket only');
        await request.response.close();
        return;
      }
      final socket = await WebSocketTransformer.upgrade(request);
      await _peerSubscription?.cancel();
      await _peer?.close();
      _peer = socket;
      onConnectionChanged?.call(true);
      _peerSubscription = socket.listen(
        (data) {
          final message = jsonDecode(data as String) as Map<String, dynamic>;
          if (message['type'] == 'tap') {
            onRemoteTap?.call(message['index'] as int);
          }
        },
        onDone: () {
          _peer = null;
          onConnectionChanged?.call(false);
        },
        onError: (_) {
          _peer = null;
          onConnectionChanged?.call(false);
        },
      );
    });
    return _localAddress(port);
  }

  void sendState(Map<String, dynamic> state) {
    _peer?.add(jsonEncode({'type': 'state', 'state': state}));
  }

  Future<void> close() async {
    await _peerSubscription?.cancel();
    await _peer?.close();
    await _server?.close(force: true);
  }

  Future<String> _localAddress(int port) async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        if (!address.isLoopback) return '${address.address}:$port';
      }
    }
    return '找不到區域網路 IP';
  }
}

class LanClient {
  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  void Function(Map<String, dynamic> state)? onState;
  void Function(bool connected)? onConnectionChanged;
  Map<String, dynamic>? latestState;

  Future<void> connect(String address) async {
    final clean = address
        .trim()
        .replaceFirst(RegExp(r'^wss?://'), '')
        .replaceAll('/', '');
    final withPort = clean.contains(':') ? clean : '$clean:4040';
    _socket = await WebSocket.connect('ws://$withPort');
    onConnectionChanged?.call(true);
    _subscription = _socket!.listen(
      (data) {
        final message = jsonDecode(data as String) as Map<String, dynamic>;
        if (message['type'] == 'state') {
          latestState = message['state'] as Map<String, dynamic>;
          onState?.call(latestState!);
        }
      },
      onDone: () => onConnectionChanged?.call(false),
      onError: (_) => onConnectionChanged?.call(false),
    );
  }

  void sendTap(int index) {
    _socket?.add(jsonEncode({'type': 'tap', 'index': index}));
  }

  Future<void> close() async {
    await _subscription?.cancel();
    await _socket?.close();
  }
}
