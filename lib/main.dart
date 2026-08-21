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
  RuleMode ruleMode = RuleMode.classic;
  int redSuperRank = 7;
  int blackSuperRank = 7;
  static const _redNames = <int, String>{
    7: '帥',
    6: '仕',
    5: '相',
    4: '俥',
    3: '傌',
    2: '炮',
    1: '兵',
  };
  static const _blackNames = <int, String>{
    7: '將',
    6: '士',
    5: '象',
    4: '車',
    3: '馬',
    2: '包',
    1: '卒',
  };
  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    model = DarkChessModel(
      mode: mode,
      ruleMode: ruleMode,
      redSuperRank: redSuperRank,
      blackSuperRank: blackSuperRank,
    );
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
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SegmentedButton<RuleMode>(
                      segments: const [
                        ButtonSegment(
                          value: RuleMode.classic,
                          label: Text('經典'),
                        ),
                        ButtonSegment(
                          value: RuleMode.superPieces,
                          icon: Icon(Icons.bolt),
                          label: Text('超級兵'),
                        ),
                      ],
                      selected: {ruleMode},
                      onSelectionChanged: (value) {
                        ruleMode = value.first;
                        _restart();
                      },
                    ),
                    if (ruleMode == RuleMode.superPieces) ...[
                      IconButton.outlined(
                        tooltip: '超級兵能力說明',
                        onPressed: _showSuperPieceHelp,
                        icon: const Icon(Icons.help_outline),
                      ),
                      _SuperPicker(
                        colorName: '紅',
                        value: redSuperRank,
                        names: _redNames,
                        onChanged: (value) {
                          redSuperRank = value;
                          _restart();
                        },
                      ),
                      _SuperPicker(
                        colorName: '黑',
                        value: blackSuperRank,
                        names: _blackNames,
                        onChanged: (value) {
                          blackSuperRank = value;
                          _restart();
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
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
                        '點棋背翻棋；金框棋子擁有所選棋種的超級能力。',
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

  void _showSuperPieceHelp() {
    showDialog<void>(
      context: context,
      builder: (context) => const _SuperPieceHelpDialog(),
    );
  }
}

class _SuperPieceHelpDialog extends StatelessWidget {
  const _SuperPieceHelpDialog();

  static const _abilities = <(String, String)>[
    ('帥／將', '獲得炮的跳吃能力；直線隔一枚棋子時，可以吃兵／卒。'),
    ('仕／士', '第一次吃子後，同一枚仕／士可以立刻再吃一枚；若沒有可吃的目標就換手。'),
    ('相／象', '成為斜線炮，可以沿斜線隔一枚棋子吃任意敵方明棋。'),
    ('俥／車', '像象棋的車一樣沿直線任意移動或吃子；隔一枚棋子也能吃任意敵方明棋。'),
    ('傌／馬', '可以斜走一格，也能吃帥／將以外的任意敵方明棋。'),
    ('炮／包', '可以沿直線吃暗棋，不分敵我；暗棋不會阻擋路徑，但遇到明棋就不能繼續。'),
    ('兵／卒', '可以吃仕／士以外的任何敵方明棋，但仍能被其他棋子正常吃掉。'),
  ];

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: const Icon(Icons.bolt, color: Color(0xFFFFD54F)),
    title: const Text('超級兵能力說明'),
    content: SizedBox(
      width: 460,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '紅黑雙方各選一種棋種，該方所有同類棋子都會獲得超級能力。翻開後會顯示金色外框與閃電標記。',
              style: TextStyle(color: Color(0xFFD2BEB0)),
            ),
            const SizedBox(height: 16),
            for (final ability in _abilities)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 62,
                      child: Text(
                        ability.$1,
                        style: const TextStyle(
                          color: Color(0xFFFFD54F),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(ability.$2)),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
    actions: [
      FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('知道了'),
      ),
    ],
  );
}

class _SuperPicker extends StatelessWidget {
  const _SuperPicker({
    required this.colorName,
    required this.value,
    required this.names,
    required this.onChanged,
  });
  final String colorName;
  final int value;
  final Map<int, String> names;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButton<int>(
    value: value,
    underline: const SizedBox.shrink(),
    borderRadius: BorderRadius.circular(14),
    items: names.entries
        .map(
          (entry) => DropdownMenuItem(
            value: entry.key,
            child: Text('$colorName：${entry.value}'),
          ),
        )
        .toList(),
    onChanged: (newValue) {
      if (newValue != null) onChanged(newValue);
    },
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
