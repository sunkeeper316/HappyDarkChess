import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_dark_chess/game/dark_chess_model.dart';

void main() {
  test('board begins with 32 pieces', () {
    final game = DarkChessModel(mode: GameMode.twoPlayers, random: Random(1));
    expect(game.board.whereType<ChessPiece>().length, 32);
    expect(game.snapshot.value.redCount, 16);
    expect(game.snapshot.value.blackCount, 16);
  });
  test('first flip assigns player color and changes turn', () {
    final game = DarkChessModel(mode: GameMode.twoPlayers, random: Random(2));
    final color = game.board.first!.color;
    game.tap(0);
    expect(game.playerOneColor, color);
    expect(game.board.first!.revealed, isTrue);
    expect(game.turnColor, isNot(color));
  });
  test('soldier captures general but general cannot capture soldier', () {
    final game = DarkChessModel(mode: GameMode.twoPlayers, random: Random(3));
    game.board.fillRange(0, 32, null);
    game.board[0] = ChessPiece(PieceColor.red, 1, '兵', revealed: true);
    game.board[1] = ChessPiece(PieceColor.black, 7, '將', revealed: true);
    game.turnColor = PieceColor.red;
    expect(game.canMove(0, 1), isTrue);
    game.turnColor = PieceColor.black;
    expect(game.canMove(1, 0), isFalse);
  });
  test('cannon capture needs exactly one screen', () {
    final game = DarkChessModel(mode: GameMode.twoPlayers, random: Random(4));
    game.board.fillRange(0, 32, null);
    game.board[0] = ChessPiece(PieceColor.red, 2, '炮', revealed: true);
    game.board[1] = ChessPiece(PieceColor.red, 1, '兵');
    game.board[3] = ChessPiece(PieceColor.black, 7, '將', revealed: true);
    game.turnColor = PieceColor.red;
    expect(game.canMove(0, 3), isTrue);
    game.board[2] = ChessPiece(PieceColor.black, 1, '卒');
    expect(game.canMove(0, 3), isFalse);
  });

  test('network state can rebuild the same board', () {
    final host = DarkChessModel(mode: GameMode.twoPlayers, random: Random(5));
    host.tap(0);
    final client = DarkChessModel(mode: GameMode.twoPlayers, random: Random(6));
    client.applyNetworkMap(host.toNetworkMap());
    expect(client.board[0]!.label, host.board[0]!.label);
    expect(client.board[0]!.revealed, isTrue);
    expect(client.playerOneColor, host.playerOneColor);
    expect(client.turnColor, host.turnColor);
  });
}
