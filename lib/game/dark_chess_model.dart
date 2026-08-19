import 'dart:math';
import 'package:flutter/foundation.dart';

enum PieceColor { red, black }

enum GameMode { computer, twoPlayers }

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
  DarkChessModel({required this.mode, Random? random})
    : _random = random ?? Random() {
    reset();
  }
  final GameMode mode;
  final Random _random;
  final List<ChessPiece?> board = List.filled(32, null);
  final ValueNotifier<GameSnapshot> snapshot = ValueNotifier(
    const GameSnapshot(message: '紅黑未定，請翻開一枚棋子', redCount: 16, blackCount: 16),
  );
  PieceColor? playerOneColor;
  PieceColor? turnColor;
  int? selected;
  bool gameOver = false;
  bool aiThinking = false;
  bool get isComputerTurn =>
      mode == GameMode.computer &&
      turnColor != null &&
      turnColor != playerOneColor;

  void reset() {
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
    if (piece != null && !piece.revealed) {
      piece.revealed = true;
      turnColor ??= piece.color;
      playerOneColor ??= piece.color;
      selected = null;
      _finishTurn();
      return true;
    }
    if (selected != null && canMove(selected!, index)) {
      board[index] = board[selected!];
      board[selected!] = null;
      selected = null;
      _finishTurn();
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
    if (target != null && (!target.revealed || target.color == moving.color)) {
      return false;
    }
    final fr = from ~/ 4, fc = from % 4, tr = to ~/ 4, tc = to % 4;
    final distance = (fr - tr).abs() + (fc - tc).abs();
    if (moving.rank == 2 && target != null) {
      if (fr != tr && fc != tc) return false;
      var screens = 0;
      if (fr == tr) {
        for (var c = min(fc, tc) + 1; c < max(fc, tc); c++) {
          if (board[fr * 4 + c] != null) screens++;
        }
      } else {
        for (var r = min(fr, tr) + 1; r < max(fr, tr); r++) {
          if (board[r * 4 + fc] != null) screens++;
        }
      }
      return screens == 1;
    }
    if (distance != 1) return false;
    if (target == null) return true;
    if (moving.rank == 1 && target.rank == 7) return true;
    if (moving.rank == 7 && target.rank == 1) return false;
    return moving.rank >= target.rank;
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
    final moves = legalMoves(turnColor!);
    final captures = moves.where((m) => board[m.to] != null).toList();
    if (captures.isNotEmpty) {
      captures.sort((a, b) => board[b.to]!.rank.compareTo(board[a.to]!.rank));
      final move = captures.first;
      board[move.to] = board[move.from];
      board[move.from] = null;
    } else if (hidden.isNotEmpty && (_random.nextBool() || moves.isEmpty)) {
      board[hidden[_random.nextInt(hidden.length)]]!.revealed = true;
    } else if (moves.isNotEmpty) {
      final move = moves[_random.nextInt(moves.length)];
      board[move.to] = board[move.from];
      board[move.from] = null;
    }
    _finishTurn();
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
