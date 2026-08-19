import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/dark_chess_game.dart';
import 'game/dark_chess_model.dart';
import 'network/lan_lobby_page.dart';

void main() => runApp(const HappyDarkChessApp());

class HappyDarkChessApp extends StatelessWidget {
  const HappyDarkChessApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: '歡樂暗棋',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFB83227),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF17110D),
      useMaterial3: true,
    ),
    home: const GameScreen(),
  );
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late DarkChessModel model;
  late DarkChessGame game;
  GameMode mode = GameMode.computer;
  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    model = DarkChessModel(mode: mode);
    game = DarkChessGame(model);
  }

  void _restart() => setState(_newGame);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '歡樂暗棋',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '翻開未知，吃光對手',
                            style: TextStyle(color: Color(0xFFBEA99B)),
                          ),
                        ],
                      ),
                    ),
                    SegmentedButton<GameMode>(
                      segments: const [
                        ButtonSegment(
                          value: GameMode.computer,
                          icon: Icon(Icons.smart_toy_outlined),
                          label: Text('電腦'),
                        ),
                        ButtonSegment(
                          value: GameMode.twoPlayers,
                          icon: Icon(Icons.people_outline),
                          label: Text('雙人'),
                        ),
                      ],
                      selected: {mode},
                      onSelectionChanged: (value) {
                        mode = value.first;
                        _restart();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<GameSnapshot>(
                  valueListenable: model.snapshot,
                  builder: (_, state, _) => _StatusCard(state: state),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) =>
                          game.handleTap(details.localPosition),
                      child: GameWidget(game: game),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LanLobbyPage()),
                    ),
                    icon: const Icon(Icons.wifi),
                    label: const Text('Wi-Fi 連線對戰'),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '點棋背翻棋；點己方棋子後，再點目的地。',
                        style: TextStyle(color: Color(0xFFCDBDB2)),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _restart,
                      icon: const Icon(Icons.refresh),
                      label: const Text('重新開局'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});
  final GameSnapshot state;
  @override
  Widget build(BuildContext context) {
    final color = state.turnColor == PieceColor.red
        ? const Color(0xFFFF756B)
        : const Color(0xFFD9D9D9);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A211C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              state.message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '紅 ${state.redCount}  ·  黑 ${state.blackCount}',
            style: const TextStyle(color: Color(0xFFD2BEB0)),
          ),
        ],
      ),
    );
  }
}
