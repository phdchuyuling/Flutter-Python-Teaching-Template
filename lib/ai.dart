import 'dart:math';
import 'game.dart';

/// A very small AI for testing. Chooses moves based on a simple heuristic.
class SimpleAI {
  int difficulty = 3; // 1 (easiest) .. 5 (hardest)
  final Random _rnd = Random();

  void setDifficulty(int d) {
    difficulty = d.clamp(1, 5);
  }

  /// Choose a move for the current player in [g]. Returns -1 if no move.
  int chooseMove(Game g) {
    var moves = g.legalMoves(g.currentPlayer);
    if (moves.isEmpty) return -1;
    // difficulty 1: random; difficulty 5: pick move flipping most
    if (difficulty <= 2) {
      return moves[_rnd.nextInt(moves.length)];
    }
    // compute flips count
    int best = moves.first;
    int bestScore = -1;
    for (var m in moves) {
      int score = g.flipsForMove(m, g.currentPlayer).length;
      // minor randomization to avoid ties
      score = score * 10 + _rnd.nextInt(10);
      if (score > bestScore) {
        bestScore = score;
        best = m;
      }
    }
    return best;
  }
}
