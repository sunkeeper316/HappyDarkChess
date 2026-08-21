import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../game/dark_chess_game.dart';
import '../game/dark_chess_model.dart';
import 'lan_connection.dart';

class LanLobbyPage extends StatefulWidget {
  const LanLobbyPage({
    super.key,
    this.ruleMode = RuleMode.classic,
    this.redSuperRank = 7,
    this.blackSuperRank = 7,
  });
  final RuleMode ruleMode;
  final int redSuperRank;
  final int blackSuperRank;
  @override
  State<LanLobbyPage> createState() => _LanLobbyPageState();
}

class _LanLobbyPageState extends State<LanLobbyPage> {
  final _addressController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _host() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final host = LanHost();
    try {
      final address = await host.start();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LanGamePage.host(
            host,
            address: address,
            ruleMode: widget.ruleMode,
            redSuperRank: widget.redSuperRank,
            blackSuperRank: widget.blackSuperRank,
          ),
        ),
      );
      await host.close();
    } catch (error) {
      await host.close();
      if (mounted) setState(() => _error = '無法建立房間：$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    if (_addressController.text.trim().isEmpty) {
      setState(() => _error = '請輸入房主顯示的 IP 位址');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final client = LanClient();
    try {
      await client.connect(_addressController.text);
      if (!mounted) return;
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => LanGamePage.client(client)));
      await client.close();
    } catch (error) {
      await client.close();
      if (mounted) setState(() => _error = '連線失敗，請確認 Wi-Fi 與 IP：$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Wi-Fi 對戰')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.wifi, size: 64, color: Color(0xFFFFB36A)),
              const SizedBox(height: 18),
              const Text(
                '兩台裝置必須連上相同 Wi-Fi',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _busy ? null : _host,
                icon: const Icon(Icons.add_link),
                label: const Text('建立房間'),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('或加入房間'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
              ),
              TextField(
                controller: _addressController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '房主 IP',
                  hintText: '例如 192.168.1.23:4040',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: _busy ? null : _join,
                icon: const Icon(Icons.login),
                label: const Text('加入房間'),
              ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(top: 18),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class LanGamePage extends StatefulWidget {
  const LanGamePage.host(
    this._host, {
    super.key,
    required this.address,
    required this.ruleMode,
    required this.redSuperRank,
    required this.blackSuperRank,
  }) : _client = null,
       isHost = true;
  const LanGamePage.client(this._client, {super.key})
    : _host = null,
      address = null,
      ruleMode = RuleMode.classic,
      redSuperRank = 7,
      blackSuperRank = 7,
      isHost = false;
  final LanHost? _host;
  final LanClient? _client;
  final bool isHost;
  final String? address;
  final RuleMode ruleMode;
  final int redSuperRank;
  final int blackSuperRank;
  @override
  State<LanGamePage> createState() => _LanGamePageState();
}

class _LanGamePageState extends State<LanGamePage> {
  late final DarkChessModel model;
  late final DarkChessGame game;
  bool connected = false;

  @override
  void initState() {
    super.initState();
    model = DarkChessModel(
      mode: GameMode.twoPlayers,
      ruleMode: widget.ruleMode,
      redSuperRank: widget.redSuperRank,
      blackSuperRank: widget.blackSuperRank,
    );
    game = DarkChessGame(model, onCellTap: _tap);
    if (widget.isHost) {
      widget._host!.onConnectionChanged = (value) {
        if (mounted) setState(() => connected = value);
        if (value) widget._host!.sendState(model.toNetworkMap());
      };
      widget._host!.onRemoteTap = (index) {
        if (model.playerOneColor != null &&
            model.turnColor != model.playerOneColor &&
            model.tap(index)) {
          widget._host!.sendState(model.toNetworkMap());
        }
      };
    } else {
      connected = true;
      widget._client!.onConnectionChanged = (value) {
        if (mounted) setState(() => connected = value);
      };
      widget._client!.onState = (state) {
        model.applyNetworkMap(state);
        if (mounted) setState(() {});
      };
      final initialState = widget._client!.latestState;
      if (initialState != null) model.applyNetworkMap(initialState);
    }
  }

  void _tap(int index) {
    if (!connected) return;
    if (widget.isHost) {
      if ((model.playerOneColor == null ||
              model.turnColor == model.playerOneColor) &&
          model.tap(index)) {
        widget._host!.sendState(model.toNetworkMap());
      }
    } else if (model.playerOneColor != null &&
        model.turnColor != model.playerOneColor) {
      widget._client!.sendTap(index);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.isHost ? 'Wi-Fi 房主' : 'Wi-Fi 對戰'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Text(
              connected ? '● 已連線' : '○ 等待連線',
              style: TextStyle(
                color: connected ? Colors.greenAccent : Colors.orangeAccent,
              ),
            ),
          ),
        ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                if (widget.isHost && !connected)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A211C),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        const Text('請讓另一台裝置輸入此位址'),
                        const SizedBox(height: 6),
                        SelectableText(
                          widget.address!,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFB36A),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.isHost && !connected) const SizedBox(height: 14),
                ValueListenableBuilder<GameSnapshot>(
                  valueListenable: model.snapshot,
                  builder: (_, state, _) => Text(
                    connected ? state.message : '等待對手加入…',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (event) => game.handleTap(event.localPosition),
                      child: GameWidget(game: game),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.isHost ? '你是玩家一，第一次翻棋決定陣營' : '你是玩家二，請等待房主第一次翻棋',
                  style: const TextStyle(color: Color(0xFFCDBDB2)),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
