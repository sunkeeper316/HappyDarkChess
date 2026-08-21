import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/dark_chess_game.dart';
import 'game/dark_chess_model.dart';
import 'network/lan_lobby_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const HappyDarkChessApp());
}

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
    home: const HomeScreen(),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  RuleMode ruleMode = RuleMode.classic;
  int redSuperRank = 7;
  int blackSuperRank = 7;
  int playerOneSuperRank = 7;
  int playerTwoSuperRank = 7;
  static const _pieceNames = <int, String>{
    7: '帥／將',
    6: '仕／士',
    5: '相／象',
    4: '俥／車',
    3: '傌／馬',
    2: '炮／包',
    1: '兵／卒',
  };

  void _start(GameMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          mode: mode,
          ruleMode: ruleMode,
          redSuperRank: redSuperRank,
          blackSuperRank: blackSuperRank,
          playerOneSuperRank: playerOneSuperRank,
          playerTwoSuperRank: playerTwoSuperRank,
        ),
      ),
    );
  }

  void _startLan() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LanLobbyPage(
          ruleMode: ruleMode,
          redSuperRank: redSuperRank,
          blackSuperRank: blackSuperRank,
          playerOneSuperRank: playerOneSuperRank,
          playerTwoSuperRank: playerTwoSuperRank,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.casino_outlined,
                  size: 72,
                  color: Color(0xFFFFB36A),
                ),
                const SizedBox(height: 12),
                const Text(
                  '歡樂暗棋',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900),
                ),
                const Text(
                  '選擇對戰方式，開始新的一局',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFBEA99B), fontSize: 16),
                ),
                const SizedBox(height: 30),
                _HomeBattleCard(
                  icon: Icons.smart_toy_outlined,
                  title: '電腦對戰',
                  subtitle: '挑戰會預測下一手的戰術 AI',
                  onTap: () => _start(GameMode.computer),
                ),
                const SizedBox(height: 12),
                _HomeBattleCard(
                  icon: Icons.people_outline,
                  title: '本機雙人',
                  subtitle: '兩位玩家在同一部裝置輪流對戰',
                  onTap: () => _start(GameMode.twoPlayers),
                ),
                const SizedBox(height: 12),
                _HomeBattleCard(
                  icon: Icons.wifi,
                  title: 'Wi-Fi 對戰',
                  subtitle: '兩台裝置連接相同 Wi-Fi 進行對戰',
                  onTap: _startLan,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A211C),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '本局規則',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<RuleMode>(
                        segments: const [
                          ButtonSegment(
                            value: RuleMode.classic,
                            label: Text('經典暗棋'),
                          ),
                          ButtonSegment(
                            value: RuleMode.superPieces,
                            icon: Icon(Icons.bolt),
                            label: Text('紅黑指定'),
                          ),
                          ButtonSegment(
                            value: RuleMode.playerSuperPieces,
                            icon: Icon(Icons.person_outline),
                            label: Text('玩家指定'),
                          ),
                        ],
                        selected: {ruleMode},
                        onSelectionChanged: (value) => setState(() {
                          ruleMode = value.first;
                        }),
                      ),
                      if (ruleMode == RuleMode.superPieces) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 18,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _SuperPicker(
                              colorName: '紅',
                              value: redSuperRank,
                              names: _GameScreenState._redNames,
                              onChanged: (value) => setState(() {
                                redSuperRank = value;
                              }),
                            ),
                            _SuperPicker(
                              colorName: '黑',
                              value: blackSuperRank,
                              names: _GameScreenState._blackNames,
                              onChanged: (value) => setState(() {
                                blackSuperRank = value;
                              }),
                            ),
                            TextButton.icon(
                              onPressed: () => showDialog<void>(
                                context: context,
                                builder: (_) => const _SuperPieceHelpDialog(),
                              ),
                              icon: const Icon(Icons.help_outline),
                              label: const Text('能力說明'),
                            ),
                          ],
                        ),
                      ],
                      if (ruleMode == RuleMode.playerSuperPieces) ...[
                        const SizedBox(height: 10),
                        const Text(
                          '能力綁定玩家，不受第一次翻到紅方或黑方影響。電腦對戰時 AI 會自行選擇。',
                          style: TextStyle(color: Color(0xFFCDBDB2)),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 18,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _SuperPicker(
                              colorName: '玩家一',
                              value: playerOneSuperRank,
                              names: _pieceNames,
                              onChanged: (value) => setState(() {
                                playerOneSuperRank = value;
                              }),
                            ),
                            _SuperPicker(
                              colorName: '玩家二（本機雙人）',
                              value: playerTwoSuperRank,
                              names: _pieceNames,
                              onChanged: (value) => setState(() {
                                playerTwoSuperRank = value;
                              }),
                            ),
                            TextButton.icon(
                              onPressed: () => showDialog<void>(
                                context: context,
                                builder: (_) => const _SuperPieceHelpDialog(),
                              ),
                              icon: const Icon(Icons.help_outline),
                              label: const Text('能力說明'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _HomeBattleCard extends StatelessWidget {
  const _HomeBattleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        child: Row(
          children: [
            Icon(icon, size: 38, color: const Color(0xFFFFB36A)),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFFCDBDB2)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.mode,
    required this.ruleMode,
    required this.redSuperRank,
    required this.blackSuperRank,
    required this.playerOneSuperRank,
    required this.playerTwoSuperRank,
  });
  final GameMode mode;
  final RuleMode ruleMode;
  final int redSuperRank;
  final int blackSuperRank;
  final int playerOneSuperRank;
  final int playerTwoSuperRank;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late DarkChessModel model;
  late DarkChessGame game;
  bool _allowPop = false;
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
      mode: widget.mode,
      ruleMode: widget.ruleMode,
      redSuperRank: widget.redSuperRank,
      blackSuperRank: widget.blackSuperRank,
      playerOneSuperRank: widget.playerOneSuperRank,
      playerTwoSuperRank: widget.playerTwoSuperRank,
    );
    game = DarkChessGame(model, onRuleNotice: _showRuleNotice);
  }

  void _restart() => setState(_newGame);

  Future<void> _showRuleNotice(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.info_outline,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('無法執行這一步'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: const Text('離開目前對局？'),
        content: const Text('目前的對局進度不會保存，確定要回到首頁嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('繼續遊戲'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('離開對局'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      setState(() => _allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowPop,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _confirmLeave();
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == GameMode.computer ? '電腦對戰' : '本機雙人'),
        actions: [
          if (widget.ruleMode != RuleMode.classic)
            IconButton(
              tooltip: '超級兵能力說明',
              onPressed: _showSuperPieceHelp,
              icon: const Icon(Icons.bolt),
            ),
          IconButton(
            tooltip: '重新開局',
            onPressed: _restart,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Column(
                children: [
                  ValueListenableBuilder<GameSnapshot>(
                    valueListenable: model.snapshot,
                    builder: (_, state, _) => _StatusCard(state: state),
                  ),
                  if (widget.ruleMode != RuleMode.classic) ...[
                    const SizedBox(height: 6),
                    ValueListenableBuilder<GameSnapshot>(
                      valueListenable: model.snapshot,
                      builder: (context, state, child) => _SuperSelectionBar(
                        model: model,
                        playerTwoLabel: widget.mode == GameMode.computer
                            ? 'AI'
                            : '玩家二',
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
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
                  const SizedBox(height: 6),
                  Text(
                    widget.ruleMode != RuleMode.classic
                        ? '金框棋子擁有超級能力'
                        : '點棋背翻棋；點己方棋子後再點目的地',
                    style: const TextStyle(color: Color(0xFFCDBDB2)),
                  ),
                ],
              ),
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
    ('帥／將', '獲得炮的跳吃能力，直線隔一枚棋子可吃任意敵方明棋；相鄰吃子仍使用原規則，不能直接吃兵／卒。'),
    ('仕／士', '第一次吃子後，同一枚仕／士可以立刻再吃一枚；若沒有可吃的目標就換手。'),
    ('相／象', '保留原本上下左右一格的移動與吃子；額外成為斜線炮，可沿斜線隔一枚棋子吃任意敵方明棋。'),
    ('俥／車', '像象棋的車一樣沿直線任意移動或吃任意敵方明棋；路徑中有暗棋或明棋都不能越過。'),
    ('傌／馬', '可以斜走一格，也能吃帥／將以外的任意敵方明棋。'),
    ('炮／包', '可沿直線跳過任意數量的暗棋，並吃掉暗棋後方的敵方明棋；路徑中的明棋會阻擋。也能直接吃暗棋，不分敵我。'),
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
              '超級棋種可以依紅黑陣營指定，也可以綁定玩家、不受首翻顏色影響。該方所有同類棋子都會獲得能力，翻開後顯示金框與閃電標記。',
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

class _SuperSelectionBar extends StatelessWidget {
  const _SuperSelectionBar({required this.model, required this.playerTwoLabel});
  final DarkChessModel model;
  final String playerTwoLabel;

  @override
  Widget build(BuildContext context) {
    late final String firstLabel;
    late final String firstPiece;
    late final PieceColor? firstColor;
    late final String secondLabel;
    late final String secondPiece;
    late final PieceColor? secondColor;

    if (model.ruleMode == RuleMode.superPieces) {
      firstLabel = '紅方';
      firstPiece = _pieceName(model.redSuperRank, PieceColor.red);
      firstColor = PieceColor.red;
      secondLabel = '黑方';
      secondPiece = _pieceName(model.blackSuperRank, PieceColor.black);
      secondColor = PieceColor.black;
    } else {
      firstColor = model.playerOneColor;
      secondColor = model.playerOneColor == null
          ? null
          : model.playerOneColor == PieceColor.red
          ? PieceColor.black
          : PieceColor.red;
      firstLabel = '玩家一${_colorSuffix(firstColor)}';
      firstPiece = _pieceName(model.playerOneSuperRank, firstColor);
      secondLabel = '$playerTwoLabel${_colorSuffix(secondColor)}';
      secondPiece = _pieceName(model.playerTwoSuperRank, secondColor);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF33291F),
        border: Border.all(color: const Color(0x66FFD54F)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt, size: 19, color: Color(0xFFFFD54F)),
              SizedBox(width: 5),
              Text('本局超級棋種', style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          _SuperChoiceChip(
            label: firstLabel,
            piece: firstPiece,
            color: firstColor,
          ),
          _SuperChoiceChip(
            label: secondLabel,
            piece: secondPiece,
            color: secondColor,
          ),
        ],
      ),
    );
  }

  static String _colorSuffix(PieceColor? color) => color == null
      ? '（陣營未定）'
      : color == PieceColor.red
      ? '（紅）'
      : '（黑）';
}

class _SuperChoiceChip extends StatelessWidget {
  const _SuperChoiceChip({
    required this.label,
    required this.piece,
    required this.color,
  });
  final String label;
  final String piece;
  final PieceColor? color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color == PieceColor.red
          ? const Color(0x332D0909)
          : const Color(0x33202020),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      '$label：$piece',
      style: TextStyle(
        color: color == PieceColor.red
            ? const Color(0xFFFF756B)
            : const Color(0xFFE8E8E8),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

String _pieceName(int rank, PieceColor? color) {
  const red = <int, String>{
    7: '帥',
    6: '仕',
    5: '相',
    4: '俥',
    3: '傌',
    2: '炮',
    1: '兵',
  };
  const black = <int, String>{
    7: '將',
    6: '士',
    5: '象',
    4: '車',
    3: '馬',
    2: '包',
    1: '卒',
  };
  const both = <int, String>{
    7: '帥／將',
    6: '仕／士',
    5: '相／象',
    4: '俥／車',
    3: '傌／馬',
    2: '炮／包',
    1: '兵／卒',
  };
  return switch (color) {
    PieceColor.red => red[rank]!,
    PieceColor.black => black[rank]!,
    null => both[rank]!,
  };
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
