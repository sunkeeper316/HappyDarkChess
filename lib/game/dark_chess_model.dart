import 'dart:math';
import 'package:flutter/foundation.dart';

enum PieceColor { red, black }

enum GameMode { computer, twoPlayers }

enum RuleMode { classic, superPieces, playerSuperPieces }

class ChessPiece {
  ChessPiece(this.color, this.rank, this.label, {this.revealed = false});
  final PieceColor color;
  final int rank;
  final String label;
  bool revealed;
}

class BoardMove {
  const BoardMove(this.from, this.to);
  final int from;
  final int to;
}

class GameSnapshot {
  const GameSnapshot({
    required this.message,
    required this.redCount,
    required this.blackCount,
    this.turnColor,
  });
  final String message;
  final int redCount;
  final int blackCount;
  final PieceColor? turnColor;
}

class DarkChessModel {
  DarkChessModel({
    required this.mode,
    this.ruleMode = RuleMode.classic,
    this.redSuperRank = 7,
    this.blackSuperRank = 7,
    this.playerOneSuperRank = 7,
    this.playerTwoSuperRank = 7,
    Random? random,
  }) : _random = random ?? Random() {
    if (ruleMode == RuleMode.playerSuperPieces && mode == GameMode.computer) {
      playerTwoSuperRank = _random.nextInt(7) + 1;
    }
    reset();
  }
  final GameMode mode;
  RuleMode ruleMode;
  int redSuperRank;
  int blackSuperRank;
  int playerOneSuperRank;
  int playerTwoSuperRank;
  final Random _random;
  final List<ChessPiece?> board = List.filled(32, null);
  final List<ChessPiece> capturedPieces = [];
  final ValueNotifier<GameSnapshot> snapshot = ValueNotifier(
    const GameSnapshot(message: '紅黑未定，請翻開一枚棋子', redCount: 16, blackCount: 16),
  );
  PieceColor? playerOneColor;
  PieceColor? turnColor;
  int? selected;
  bool gameOver = false;
  bool aiThinking = false;
  int? comboPiece;
  bool get isComputerTurn =>
      mode == GameMode.computer &&
      turnColor != null &&
      turnColor != playerOneColor;

  bool isSuper(ChessPiece piece) {
    if (ruleMode == RuleMode.superPieces) {
      return piece.rank ==
          (piece.color == PieceColor.red ? redSuperRank : blackSuperRank);
    }
    if (ruleMode == RuleMode.playerSuperPieces && playerOneColor != null) {
      return piece.rank ==
          (piece.color == playerOneColor
              ? playerOneSuperRank
              : playerTwoSuperRank);
    }
    return false;
  }

  Map<String, dynamic> toNetworkMap() => {
    'board': board
        .map(
          (piece) => piece == null
              ? null
              : {
                  'color': piece.color.name,
                  'rank': piece.rank,
                  'label': piece.label,
                  'revealed': piece.revealed,
                },
        )
        .toList(),
    'capturedPieces': capturedPieces
        .map(
          (piece) => {
            'color': piece.color.name,
            'rank': piece.rank,
            'label': piece.label,
            'revealed': true,
          },
        )
        .toList(),
    'playerOneColor': playerOneColor?.name,
    'turnColor': turnColor?.name,
    'selected': selected,
    'gameOver': gameOver,
    'ruleMode': ruleMode.name,
    'redSuperRank': redSuperRank,
    'blackSuperRank': blackSuperRank,
    'playerOneSuperRank': playerOneSuperRank,
    'playerTwoSuperRank': playerTwoSuperRank,
    'comboPiece': comboPiece,
    'message': snapshot.value.message,
  };

  void applyNetworkMap(Map<String, dynamic> data) {
    final pieces = data['board'] as List<dynamic>;
    for (var i = 0; i < board.length; i++) {
      final value = pieces[i];
      if (value == null) {
        board[i] = null;
      } else {
        final map = value as Map<String, dynamic>;
        board[i] = ChessPiece(
          PieceColor.values.byName(map['color'] as String),
          map['rank'] as int,
          map['label'] as String,
          revealed: map['revealed'] as bool,
        );
      }
    }
    capturedPieces
      ..clear()
      ..addAll(
        (data['capturedPieces'] as List<dynamic>? ?? const []).map((value) {
          final map = value as Map<String, dynamic>;
          return ChessPiece(
            PieceColor.values.byName(map['color'] as String),
            map['rank'] as int,
            map['label'] as String,
            revealed: true,
          );
        }),
      );
    final playerColor = data['playerOneColor'] as String?;
    final currentTurn = data['turnColor'] as String?;
    playerOneColor = playerColor == null
        ? null
        : PieceColor.values.byName(playerColor);
    turnColor = currentTurn == null
        ? null
        : PieceColor.values.byName(currentTurn);
    selected = data['selected'] as int?;
    gameOver = data['gameOver'] as bool;
    final networkRuleMode = data['ruleMode'] as String?;
    if (networkRuleMode != null) {
      ruleMode = RuleMode.values.byName(networkRuleMode);
    }
    redSuperRank = data['redSuperRank'] as int? ?? redSuperRank;
    blackSuperRank = data['blackSuperRank'] as int? ?? blackSuperRank;
    playerOneSuperRank =
        data['playerOneSuperRank'] as int? ?? playerOneSuperRank;
    playerTwoSuperRank =
        data['playerTwoSuperRank'] as int? ?? playerTwoSuperRank;
    comboPiece = data['comboPiece'] as int?;
    _publish(data['message'] as String);
  }

  void reset() {
    playerOneColor = null;
    turnColor = null;
    selected = null;
    comboPiece = null;
    gameOver = false;
    aiThinking = false;
    capturedPieces.clear();
    final pieces = <ChessPiece>[];
    void add(PieceColor color, int rank, String label, int count) {
      for (var i = 0; i < count; i++) {
        pieces.add(ChessPiece(color, rank, label));
      }
    }

    add(PieceColor.red, 7, '帥', 1);
    add(PieceColor.red, 6, '仕', 2);
    add(PieceColor.red, 5, '相', 2);
    add(PieceColor.red, 4, '俥', 2);
    add(PieceColor.red, 3, '傌', 2);
    add(PieceColor.red, 2, '炮', 2);
    add(PieceColor.red, 1, '兵', 5);
    add(PieceColor.black, 7, '將', 1);
    add(PieceColor.black, 6, '士', 2);
    add(PieceColor.black, 5, '象', 2);
    add(PieceColor.black, 4, '車', 2);
    add(PieceColor.black, 3, '馬', 2);
    add(PieceColor.black, 2, '包', 2);
    add(PieceColor.black, 1, '卒', 5);
    pieces.shuffle(_random);
    for (var i = 0; i < 32; i++) {
      board[i] = pieces[i];
    }
    _publish('紅黑未定，請翻開一枚棋子');
  }

  bool tap(int index) {
    if (gameOver || aiThinking || isComputerTurn) return false;
    final piece = board[index];
    if (comboPiece != null) {
      if (selected == comboPiece &&
          board[index] != null &&
          canMove(comboPiece!, index)) {
        _performMove(comboPiece!, index);
        return true;
      }
      selected = comboPiece;
      _publish('${_colorName(turnColor)}方：仕／士可再吃一枚棋子');
      return true;
    }
    if (selected != null && piece != null && !piece.revealed) {
      if (canMove(selected!, index)) {
        _performMove(selected!, index);
        return true;
      }
      final reason = _hiddenTargetCancelReason(selected!, index);
      selected = null;
      _publish('${_colorName(turnColor)}方：$reason；已取消選取');
      return true;
    }
    if (piece != null && !piece.revealed) {
      piece.revealed = true;
      turnColor ??= piece.color;
      playerOneColor ??= piece.color;
      selected = null;
      _finishTurn();
      return true;
    }
    if (selected != null && canMove(selected!, index)) {
      _performMove(selected!, index);
      return true;
    }
    if (piece != null && piece.revealed && piece.color == turnColor) {
      selected = selected == index ? null : index;
      _publish('${_colorName(turnColor!)}方：選擇目的地');
      return true;
    }
    selected = null;
    _publish('${_colorName(turnColor)}方回合');
    return true;
  }

  bool canMove(int from, int to) {
    if (from == to) return false;
    final moving = board[from];
    final target = board[to];
    if (moving == null || !moving.revealed || moving.color != turnColor) {
      return false;
    }
    final fr = from ~/ 4, fc = from % 4, tr = to ~/ 4, tc = to % 4;
    final distance = (fr - tr).abs() + (fc - tc).abs();
    final superPiece = isSuper(moving);

    // Super cannon can jump across any number of face-down pieces. It may
    // destroy a face-down target regardless of colour, or capture an enemy
    // revealed target after at least one face-down screen. A revealed piece
    // anywhere in the path blocks the shot.
    if (superPiece && moving.rank == 2 && target != null) {
      if (fr != tr && fc != tc) return false;
      var hiddenScreens = 0;
      for (final index in _between(from, to)) {
        final screen = board[index];
        if (screen != null && screen.revealed) return false;
        if (screen != null) hiddenScreens++;
      }
      if (!target.revealed) return true;
      return hiddenScreens > 0 && target.color != moving.color;
    }
    if (target != null && (!target.revealed || target.color == moving.color)) {
      return false;
    }

    if (superPiece && moving.rank == 7 && target != null && target.rank == 1) {
      return _screensBetween(from, to, straightOnly: true) == 1;
    }
    if (superPiece && moving.rank == 5 && target != null) {
      if ((fr - tr).abs() != (fc - tc).abs()) return false;
      return _screensBetween(from, to) == 1;
    }
    if (superPiece && moving.rank == 4) {
      if (fr != tr && fc != tc) return false;
      final screens = _screensBetween(from, to, straightOnly: true);
      return screens == 0;
    }
    if (superPiece &&
        moving.rank == 3 &&
        (fr - tr).abs() == 1 &&
        (fc - tc).abs() == 1) {
      return target == null || target.rank != 7;
    }
    if (moving.rank == 2 && target != null) {
      if (fr != tr && fc != tc) return false;
      return _screensBetween(from, to, straightOnly: true) == 1;
    }
    if (distance != 1) return false;
    if (target == null) return true;
    if (superPiece && moving.rank == 1) return target.rank != 6;
    if (moving.rank == 1 && target.rank == 7) return true;
    if (moving.rank == 7 && target.rank == 1) return false;
    return moving.rank >= target.rank;
  }

  String _hiddenTargetCancelReason(int from, int to) {
    final moving = board[from];
    if (moving == null || !isSuper(moving) || moving.rank != 2) {
      return '暗棋不能直接吃，只有超級炮／包可以';
    }
    final fr = from ~/ 4;
    final fc = from % 4;
    final tr = to ~/ 4;
    final tc = to % 4;
    if (fr != tr && fc != tc) {
      return '超級炮／包只能攻擊同一行或同一列';
    }
    if (_between(from, to).any((index) {
      final piece = board[index];
      return piece != null && piece.revealed;
    })) {
      return '路徑上有明棋阻擋，不能跳過';
    }
    return '這不是合法的超級炮／包目標';
  }

  Iterable<int> _between(int from, int to) sync* {
    final fr = from ~/ 4, fc = from % 4, tr = to ~/ 4, tc = to % 4;
    final dr = tr == fr ? 0 : (tr > fr ? 1 : -1);
    final dc = tc == fc ? 0 : (tc > fc ? 1 : -1);
    var r = fr + dr, c = fc + dc;
    while (r != tr || c != tc) {
      yield r * 4 + c;
      r += dr;
      c += dc;
    }
  }

  int _screensBetween(int from, int to, {bool straightOnly = false}) {
    final fr = from ~/ 4, fc = from % 4, tr = to ~/ 4, tc = to % 4;
    final straight = fr == tr || fc == tc;
    final diagonal = (fr - tr).abs() == (fc - tc).abs();
    if ((!straight && straightOnly) || (!straight && !diagonal)) return -1;
    return _between(from, to).where((index) => board[index] != null).length;
  }

  void _performMove(int from, int to) {
    final moving = board[from]!;
    final capturedPiece = board[to];
    final captured = capturedPiece != null;
    if (capturedPiece != null) {
      capturedPiece.revealed = true;
      capturedPieces.add(capturedPiece);
    }
    final isSecondComboCapture = comboPiece == from;
    board[to] = moving;
    board[from] = null;
    selected = null;
    comboPiece = null;
    if (!isSecondComboCapture &&
        captured &&
        isSuper(moving) &&
        moving.rank == 6) {
      final oldTurn = turnColor;
      turnColor = moving.color;
      final hasSecondCapture = legalMoves(
        moving.color,
      ).any((move) => move.from == to && board[move.to] != null);
      turnColor = oldTurn;
      if (hasSecondCapture) {
        comboPiece = to;
        selected = to;
        _publish('${_colorName(turnColor)}方：仕／士可再吃一枚棋子');
        return;
      }
    }
    _finishTurn();
  }

  List<BoardMove> legalMoves(PieceColor color) {
    final oldTurn = turnColor;
    turnColor = color;
    final moves = <BoardMove>[];
    for (var from = 0; from < 32; from++) {
      for (var to = 0; to < 32; to++) {
        if (canMove(from, to)) moves.add(BoardMove(from, to));
      }
    }
    turnColor = oldTurn;
    return moves;
  }

  void playComputerTurn() {
    if (!isComputerTurn || gameOver) return;
    final hidden = <int>[
      for (var i = 0; i < 32; i++)
        if (board[i] != null && !board[i]!.revealed) i,
    ];
    var moves = legalMoves(turnColor!);
    if (comboPiece != null) {
      moves = moves
          .where((move) => move.from == comboPiece && board[move.to] != null)
          .toList();
    }
    final captures = moves.where((m) => board[m.to] != null).toList();
    if (captures.isNotEmpty) {
      final move = _bestComputerMove(captures);
      _performMove(move.from, move.to);
      if (comboPiece != null) playComputerTurn();
      return;
    } else if (hidden.isNotEmpty &&
        (moves.isEmpty || _random.nextInt(100) < 35)) {
      board[_bestFlip(hidden)]!.revealed = true;
    } else if (moves.isNotEmpty) {
      final move = _bestComputerMove(moves);
      _performMove(move.from, move.to);
      return;
    }
    _finishTurn();
  }

  BoardMove _bestComputerMove(List<BoardMove> moves) {
    var bestScore = -1 << 30;
    final best = <BoardMove>[];
    for (final move in moves) {
      final score = _scoreComputerMove(move);
      if (score > bestScore) {
        bestScore = score;
        best
          ..clear()
          ..add(move);
      } else if (score == bestScore) {
        best.add(move);
      }
    }
    return best[_random.nextInt(best.length)];
  }

  int _scoreComputerMove(BoardMove move) {
    final moving = board[move.from]!;
    final target = board[move.to];
    var score = target == null
        ? 0
        : _pieceValue(target, hiddenFairly: true) * 12;
    if (target != null && isSuper(moving) && moving.rank == 6) score += 90;

    // Temporarily play the move, then inspect the opponent's best immediate
    // reply. Hidden identities are deliberately not used by this evaluation.
    board[move.to] = moving;
    board[move.from] = null;
    final oldTurn = turnColor;
    turnColor = moving.color == PieceColor.red
        ? PieceColor.black
        : PieceColor.red;
    final replies = legalMoves(turnColor!);
    var worstReply = 0;
    var movedPieceThreatened = false;
    for (final reply in replies) {
      final captured = board[reply.to];
      if (captured == null) continue;
      final loss = _pieceValue(captured, hiddenFairly: true) * 10;
      if (loss > worstReply) worstReply = loss;
      if (reply.to == move.to) movedPieceThreatened = true;
    }
    score -= worstReply;
    if (movedPieceThreatened) score -= _pieceValue(moving) * 3;

    // Prefer useful central squares and positions with more future choices.
    final row = move.to ~/ 4;
    final col = move.to % 4;
    if (col == 1 || col == 2) score += 5;
    if (row > 0 && row < 7) score += 2;
    score += legalMoves(moving.color).where((m) => m.from == move.to).length;

    turnColor = oldTurn;
    board[move.from] = moving;
    board[move.to] = target;
    return score;
  }

  int _bestFlip(List<int> hidden) {
    var bestScore = -1 << 30;
    final best = <int>[];
    for (final index in hidden) {
      var score = 0;
      final row = index ~/ 4;
      final col = index % 4;
      for (final delta in const [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
        final r = row + delta.$1;
        final c = col + delta.$2;
        if (r < 0 || r >= 8 || c < 0 || c >= 4) continue;
        final neighbour = board[r * 4 + c];
        if (neighbour == null || !neighbour.revealed) continue;
        score += neighbour.color == turnColor ? 4 : -6;
      }
      if (col == 1 || col == 2) score += 1;
      if (score > bestScore) {
        bestScore = score;
        best
          ..clear()
          ..add(index);
      } else if (score == bestScore) {
        best.add(index);
      }
    }
    return best[_random.nextInt(best.length)];
  }

  int _pieceValue(ChessPiece piece, {bool hiddenFairly = false}) {
    if (!piece.revealed && hiddenFairly) return 4;
    var value = switch (piece.rank) {
      7 => 9,
      6 => 7,
      5 => 6,
      4 => 6,
      3 => 5,
      2 => 6,
      _ => 3,
    };
    if (isSuper(piece)) value += 4;
    return value;
  }

  void _finishTurn() {
    final red = board.where((p) => p?.color == PieceColor.red).length;
    final black = board.where((p) => p?.color == PieceColor.black).length;
    if (red == 0 || black == 0) {
      gameOver = true;
      _publish('${red == 0 ? '黑' : '紅'}方獲勝！');
      return;
    }
    turnColor = turnColor == PieceColor.red ? PieceColor.black : PieceColor.red;
    _publish(isComputerTurn ? '電腦思考中…' : '${_colorName(turnColor)}方回合');
  }

  void _publish(String message) => snapshot.value = GameSnapshot(
    message: message,
    redCount: board.where((p) => p?.color == PieceColor.red).length,
    blackCount: board.where((p) => p?.color == PieceColor.black).length,
    turnColor: turnColor,
  );
  String _colorName(PieceColor? color) => color == null
      ? '目前'
      : color == PieceColor.red
      ? '紅'
      : '黑';
}
