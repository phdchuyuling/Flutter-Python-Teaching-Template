import 'dart:math';
import 'game.dart';

class SimpleAI {
  int difficulty = 3; // 1..5

  void setDifficulty(int d) {
    difficulty = d.clamp(1, 5);
  }

  int chooseMove(Game game) {
    var moves = game.legalMoves(-1);
    if (moves.isEmpty) return -1;
    // difficulty affects strategy: higher -> choose max flips, lower -> random
    if (difficulty <= 2) {
      // random quick move
      return moves[Random().nextInt(moves.length)];
    }
    // evaluate by number of flips (simple heuristic)
    moves.sort((a, b) => game.flipsForMove(b, -1).length - game.flipsForMove(a, -1).length);
    // for medium difficulty pick first, for very high sometimes pick among top 2
    if (difficulty >= 5 && moves.length > 1 && Random().nextDouble() < 0.25) {
      return moves[Random().nextInt(min(2, moves.length))];
    }
    return moves.first;
  }
}
