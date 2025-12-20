import 'game.dart';

class SimpleAI {
  int difficulty = 3; // 1-5, higher = harder
  int speed = 3; // 1-5, higher = slower (for UX)

  void setDifficulty(int newDifficulty) {
    difficulty = newDifficulty.clamp(1, 5);
  }

  int findBestMove(Game game) {
    List<int> validMoves = game.legalMoves(-1);
    if (validMoves.isEmpty) return -1;

    if (difficulty <= 1) {
      return validMoves.first;
    }

    int bestMove = validMoves.first;
    int bestScore = -999999;

    for (int move in validMoves) {
      int score = evaluateMove(game, move);

      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    return bestMove;
  }

  int chooseMove(Game game) {
    return findBestMove(game);
  }

  int evaluateMove(Game game, int move) {
    // Create a copy of the board
    List<int> originalBoard = game.board;
    game.board = List<int>.from(game.board);
    int originalPlayer = game.currentPlayer;

    game.makeMove(move, -1);
    int aiScore = game.getScore(-1); // AI is white (-1)
    int opponentScore = game.getScore(1);

    // Restore original board
    game.board = originalBoard;
    game.currentPlayer = originalPlayer;

    int score = aiScore - opponentScore;

    // Strategy based on difficulty
    switch (difficulty) {
      case 1:
        return 0; // Random
      case 2:
        return score;
      case 3:
        return score + cornerBonus(move);
      case 4:
        return score * 2 + cornerBonus(move) * 2;
      case 5:
        return score * 3 + cornerBonus(move) * 3 + edgeBonus(move);
      default:
        return score;
    }
  }

  int cornerBonus(int move) {
    int row = move ~/ Game.boardSize;
    int col = move % Game.boardSize;
    const corners = [
      [0, 0],
      [0, 7],
      [7, 0],
      [7, 7],
    ];
    for (var corner in corners) {
      if (row == corner[0] && col == corner[1]) return 100;
    }
    return 0;
  }

  int edgeBonus(int move) {
    int row = move ~/ Game.boardSize;
    int col = move % Game.boardSize;
    if (row == 0 || row == 7 || col == 0 || col == 7) return 25;
    return 0;
  }
}
