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
  test('tapping a hidden piece while selected only cancels selection', () {
    final game = DarkChessModel(mode: GameMode.twoPlayers, random: Random(11));
    game.board.fillRange(0, 32, null);
    game.board[0] = ChessPiece(PieceColor.red, 4, '俥', revealed: true);
    game.board[1] = ChessPiece(PieceColor.black, 3, '馬');
    game.turnColor = PieceColor.red;
    game.selected = 0;

    game.tap(1);

    expect(game.selected, isNull);
    expect(game.board[1]!.revealed, isFalse);
    expect(game.turnColor, PieceColor.red);
    expect(game.snapshot.value.message, contains('只有超級炮／包可以'));
    game.tap(1);
    expect(game.board[1]!.revealed, isTrue);
    expect(game.turnColor, PieceColor.black);
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

  test('captured pieces are recorded and synchronized', () {
    final host = DarkChessModel(mode: GameMode.twoPlayers, random: Random(9));
    host.board.fillRange(0, 32, null);
    host.board[0] = ChessPiece(PieceColor.red, 4, '俥', revealed: true);
    host.board[1] = ChessPiece(PieceColor.black, 3, '馬', revealed: true);
    host.board[2] = ChessPiece(PieceColor.black, 1, '卒', revealed: true);
    host.turnColor = PieceColor.red;
    host.selected = 0;
    host.tap(1);

    expect(host.capturedPieces.single.label, '馬');
    expect(host.capturedPieces.single.revealed, isTrue);

    final client = DarkChessModel(
      mode: GameMode.twoPlayers,
      random: Random(10),
    );
    client.applyNetworkMap(host.toNetworkMap());
    expect(client.capturedPieces.single.label, '馬');
  });

  test('computer avoids a valuable capture that is immediately lost', () {
    final game = DarkChessModel(mode: GameMode.computer, random: Random(8));
    game.board.fillRange(0, 32, null);
    game.playerOneColor = PieceColor.black;
    game.turnColor = PieceColor.red;
    game.board[0] = ChessPiece(PieceColor.red, 7, '帥', revealed: true);
    game.board[1] = ChessPiece(PieceColor.black, 4, '車', revealed: true);
    game.board[2] = ChessPiece(PieceColor.black, 7, '將', revealed: true);
    game.board[28] = ChessPiece(PieceColor.red, 3, '傌', revealed: true);
    game.board[29] = ChessPiece(PieceColor.black, 1, '卒', revealed: true);

    game.playComputerTurn();

    expect(game.board[29]!.label, '傌');
    expect(game.board[0]!.label, '帥');
  });

  group('super piece mode', () {
    DarkChessModel superGame(int rank) {
      final game = DarkChessModel(
        mode: GameMode.twoPlayers,
        ruleMode: RuleMode.superPieces,
        redSuperRank: rank,
        blackSuperRank: rank,
        random: Random(7),
      );
      game.board.fillRange(0, 32, null);
      game.turnColor = PieceColor.red;
      return game;
    }

    test('general cannon-jumps to capture a soldier', () {
      final game = superGame(7);
      game.board[0] = ChessPiece(PieceColor.red, 7, '帥', revealed: true);
      game.board[1] = ChessPiece(PieceColor.red, 3, '傌', revealed: true);
      game.board[3] = ChessPiece(PieceColor.black, 1, '卒', revealed: true);
      expect(game.canMove(0, 3), isTrue);
    });

    test('advisor captures twice with the same piece', () {
      final game = superGame(6);
      game.board[5] = ChessPiece(PieceColor.red, 6, '仕', revealed: true);
      game.board[6] = ChessPiece(PieceColor.black, 1, '卒', revealed: true);
      game.board[7] = ChessPiece(PieceColor.black, 2, '包', revealed: true);
      game.selected = 5;
      game.tap(6);
      expect(game.comboPiece, 6);
      expect(game.turnColor, PieceColor.red);
      game.tap(7);
      expect(game.comboPiece, isNull);
      expect(game.board[7]!.label, '仕');
    });

    test('elephant cannon-jumps diagonally', () {
      final game = superGame(5);
      game.board[0] = ChessPiece(PieceColor.red, 5, '相', revealed: true);
      game.board[5] = ChessPiece(PieceColor.red, 1, '兵');
      game.board[10] = ChessPiece(PieceColor.black, 7, '將', revealed: true);
      expect(game.canMove(0, 10), isTrue);
    });

    test('rook travels freely and cannon-jumps for captures', () {
      final game = superGame(4);
      game.board[0] = ChessPiece(PieceColor.red, 4, '俥', revealed: true);
      expect(game.canMove(0, 12), isTrue);
      game.board[12] = ChessPiece(PieceColor.black, 7, '將', revealed: true);
      expect(game.canMove(0, 12), isTrue);
      game.board[4] = ChessPiece(PieceColor.red, 1, '兵');
      expect(game.canMove(0, 12), isTrue);
    });

    test('horse moves diagonally but cannot capture a general', () {
      final game = superGame(3);
      game.board[0] = ChessPiece(PieceColor.red, 3, '傌', revealed: true);
      game.board[5] = ChessPiece(PieceColor.black, 4, '車', revealed: true);
      expect(game.canMove(0, 5), isTrue);
      game.board[5] = ChessPiece(PieceColor.black, 7, '將', revealed: true);
      expect(game.canMove(0, 5), isFalse);
    });

    test('cannon destroys face-down pieces until a revealed blocker', () {
      final game = superGame(2);
      game.board[0] = ChessPiece(PieceColor.red, 2, '炮', revealed: true);
      game.board[1] = ChessPiece(PieceColor.black, 1, '卒');
      game.board[3] = ChessPiece(PieceColor.red, 5, '相');
      expect(game.canMove(0, 3), isTrue);
      game.selected = 0;
      game.tap(3);
      expect(game.board[3]!.label, '炮');
      expect(game.capturedPieces.single.label, '相');

      game.board[0] = game.board[3];
      game.board[3] = ChessPiece(PieceColor.red, 5, '相');
      game.turnColor = PieceColor.red;
      game.board[2] = ChessPiece(PieceColor.black, 3, '馬', revealed: true);
      expect(game.canMove(0, 3), isFalse);
    });

    test(
      'cannon jumps any number of hidden pieces to capture a revealed one',
      () {
        final game = superGame(2);
        game.board[0] = ChessPiece(PieceColor.red, 2, '炮', revealed: true);
        game.board[1] = ChessPiece(PieceColor.red, 1, '兵');
        game.board[2] = ChessPiece(PieceColor.black, 5, '象');
        game.board[3] = ChessPiece(PieceColor.black, 7, '將', revealed: true);
        expect(game.canMove(0, 3), isTrue);

        game.board[2]!.revealed = true;
        expect(game.canMove(0, 3), isFalse);
      },
    );

    test('soldier captures every rank except advisor', () {
      final game = superGame(1);
      game.board[0] = ChessPiece(PieceColor.red, 1, '兵', revealed: true);
      game.board[1] = ChessPiece(PieceColor.black, 5, '象', revealed: true);
      expect(game.canMove(0, 1), isTrue);
      game.board[1] = ChessPiece(PieceColor.black, 6, '士', revealed: true);
      expect(game.canMove(0, 1), isFalse);
    });
  });

  test('player super choices follow players instead of colours', () {
    final game = DarkChessModel(
      mode: GameMode.twoPlayers,
      ruleMode: RuleMode.playerSuperPieces,
      playerOneSuperRank: 3,
      playerTwoSuperRank: 5,
      random: Random(12),
    );
    game.playerOneColor = PieceColor.black;

    expect(game.isSuper(ChessPiece(PieceColor.black, 3, '馬')), isTrue);
    expect(game.isSuper(ChessPiece(PieceColor.red, 5, '相')), isTrue);
    expect(game.isSuper(ChessPiece(PieceColor.red, 3, '傌')), isFalse);
  });

  test('computer chooses its own player super rank', () {
    final game = DarkChessModel(
      mode: GameMode.computer,
      ruleMode: RuleMode.playerSuperPieces,
      playerOneSuperRank: 2,
      playerTwoSuperRank: 99,
      random: Random(13),
    );
    expect(game.playerOneSuperRank, 2);
    expect(game.playerTwoSuperRank, inInclusiveRange(1, 7));
  });
}
