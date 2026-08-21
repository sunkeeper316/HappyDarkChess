import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Image;
import 'dark_chess_model.dart';

class DarkChessGame extends FlameGame {
  DarkChessGame(this.model, {this.onCellTap});
  final DarkChessModel model;
  final void Function(int index)? onCellTap;
  Rect boardRect = Rect.zero;
  double cellSize = 0;
  void handleTap(Offset point) {
    if (!boardRect.contains(point)) return;
    final col = ((point.dx - boardRect.left) / cellSize).floor();
    final row = ((point.dy - boardRect.top) / cellSize).floor();
    final index = row * 4 + col;
    if (onCellTap != null) {
      onCellTap!(index);
      return;
    }
    final changed = model.tap(index);
    if (changed && model.isComputerTurn && !model.gameOver) {
      model.aiThinking = true;
      Future<void>.delayed(const Duration(milliseconds: 650), () {
        model.aiThinking = false;
        model.playComputerTurn();
      });
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final bg = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF3A2418), Color(0xFF20150F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & Size(size.x, size.y));
    canvas.drawRect(Offset.zero & Size(size.x, size.y), bg);
    cellSize = _min(size.x / 4, size.y / 8);
    final width = cellSize * 4, height = cellSize * 8;
    boardRect = Rect.fromLTWH(
      (size.x - width) / 2,
      (size.y - height) / 2,
      width,
      height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect.inflate(5), const Radius.circular(13)),
      Paint()..color = const Color(0xFFD7A45F),
    );
    final linePaint = Paint()
      ..color = const Color(0xFF6F3F22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var i = 0; i < 32; i++) {
      final row = i ~/ 4, col = i % 4;
      final cell = Rect.fromLTWH(
        boardRect.left + col * cellSize,
        boardRect.top + row * cellSize,
        cellSize,
        cellSize,
      );
      canvas.drawRect(cell.deflate(2), linePaint);
      _drawPiece(canvas, i, cell.center, cellSize * .39);
    }
  }

  void _drawPiece(Canvas canvas, int index, Offset center, double radius) {
    final piece = model.board[index];
    if (piece == null) return;
    if (model.selected == index) {
      canvas.drawCircle(
        center,
        radius + 6,
        Paint()..color = const Color(0xFFFFD54F),
      );
    }
    canvas.drawCircle(
      center + const Offset(1.5, 3),
      radius,
      Paint()..color = const Color(0x66000000),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = piece.revealed
            ? const Color(0xFFFFE5B0)
            : const Color(0xFF5B2D20),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = piece.revealed
            ? const Color(0xFF8A552E)
            : const Color(0xFFD5A45B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    if (piece.revealed && model.isSuper(piece)) {
      canvas.drawCircle(
        center,
        radius + 3,
        Paint()
          ..color = const Color(0xFFFFD54F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      _text(
        canvas,
        '⚡',
        center + Offset(radius * .62, -radius * .62),
        radius * .48,
        const Color(0xFFFFD54F),
      );
    }
    if (!piece.revealed) {
      canvas.drawCircle(
        center,
        radius * .58,
        Paint()
          ..color = const Color(0xFFBA7B35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      _text(canvas, '暗', center, radius * .72, const Color(0xFFE9BE73));
    } else {
      _text(
        canvas,
        piece.label,
        center,
        radius * .95,
        piece.color == PieceColor.red
            ? const Color(0xFFC62828)
            : const Color(0xFF202020),
      );
    }
  }

  void _text(
    Canvas canvas,
    String value,
    Offset center,
    double fontSize,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          fontFamily: 'serif',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  double _min(double a, double b) => a < b ? a : b;
}
