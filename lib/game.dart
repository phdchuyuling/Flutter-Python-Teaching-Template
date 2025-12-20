// Minimal Reversi / Othello game logic to satisfy `main.dart` UI.
// Provides a simple Game class with board state, move generation, applying moves,
// undo support and scoring. This is intentionally compact but correct for 8x8.

class Game {
  static const int size = 8;

  /// board: 0 empty, 1 black, -1 white
  List<int> board = List<int>.filled(size * size, 0);

  /// current player: 1 (black), -1 (white)
  int currentPlayer = 1;

  // history of board snapshots (deep copies) to support undo
  final List<List<int>> _history = [];
  final List<int> _historyPlayer = [];

  Game() {
    reset();
  }

  void reset() {
    board = List<int>.filled(size * size, 0);
    int mid = size ~/ 2;
    // standard starting position
    board[(mid - 1) * size + (mid - 1)] = -1; // white
    board[(mid - 1) * size + mid] = 1; // black
    board[mid * size + (mid - 1)] = 1;
    board[mid * size + mid] = -1;
    currentPlayer = 1;
    _history.clear();
    _historyPlayer.clear();
    _pushHistory();
  }

  void _pushHistory() {
    _history.add(List<int>.from(board));
    _historyPlayer.add(currentPlayer);
  }

  /// Undo two moves (as UI expects undo of human+ai pair).
  /// Returns true if succeeded.
  bool undoTwoMoves() {
    if (_history.length < 3) return false;
    // pop last state (current state) and previous (after opponent's move)
    _history.removeLast();
    _history.removeLast();
    var last = _history.last;
    board = List<int>.from(last);
    currentPlayer = _historyPlayer.last;
    return true;
  }

  /// Returns list of legal move indices for player
  List<int> legalMoves(int player) {
    List<int> res = [];
    for (int i = 0; i < board.length; i++) {
      if (board[i] == 0 && flipsForMove(i, player).isNotEmpty) res.add(i);
    }
    return res;
  }

  /// Returns list of indices that would be flipped if player plays at idx
  List<int> flipsForMove(int idx, int player) {
    if (board[idx] != 0) return [];
    int r = idx ~/ size;
    int c = idx % size;
    List<int> flips = [];
    const directions = [
      [-1, -1],
      [-1, 0],
      [-1, 1],
      [0, -1],
      [0, 1],
      [1, -1],
      [1, 0],
      [1, 1]
    ];
    for (var d in directions) {
      int dr = d[0];
      int dc = d[1];
      int rr = r + dr;
      int cc = c + dc;
      List<int> temp = [];
      bool foundOpponent = false;
      while (rr >= 0 && rr < size && cc >= 0 && cc < size) {
        int v = board[rr * size + cc];
        if (v == -player) {
          foundOpponent = true;
          temp.add(rr * size + cc);
        } else if (v == player) {
          if (foundOpponent) flips.addAll(temp);
          break;
        } else {
          break;
        }
        rr += dr;
        cc += dc;
      }
    }
    return flips;
  }

  /// Make a move for [player] at [idx]. Returns true if applied.
  bool makeMove(int idx, int player) {
    var flips = flipsForMove(idx, player);
    if (flips.isEmpty) return false;
    // push current state for undo
    _pushHistory();
    board[idx] = player;
    for (var f in flips) board[f] = player;
    currentPlayer = -player;
    // if opponent has no moves, keep current to same player
    if (legalMoves(currentPlayer).isEmpty) {
      // if also no moves for player, game over, keep it as-is
      if (legalMoves(-currentPlayer).isNotEmpty) {
        currentPlayer = -currentPlayer; // revert
      }
    }
    _pushHistory();
    return true;
  }

  Map<String, int> score() {
    int black = 0, white = 0;
    for (var v in board) {
      if (v == 1) black++;
      if (v == -1) white++;
    }
    return {'black': black, 'white': white};
  }

  bool isGameOver() {
    return legalMoves(1).isEmpty && legalMoves(-1).isEmpty;
  }
}
