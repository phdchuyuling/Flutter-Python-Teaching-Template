class Game {
  static const int size = 8;
  late List<int> board; // 0 empty, 1 black, -1 white
  int currentPlayer = 1;
  final List<_Snapshot> _history = [];

  Game() {
    reset();
  }

  void reset() {
    board = List.filled(size * size, 0);
    int m = size ~/ 2;
    // standard initial setup
    board[_idx(m - 1, m - 1)] = -1;
    board[_idx(m, m)] = -1;
    board[_idx(m - 1, m)] = 1;
    board[_idx(m, m - 1)] = 1;
    currentPlayer = 1;
    _history.clear();
  }

  int _idx(int x, int y) => y * size + x;

  bool makeMove(int idx, int player) {
    var flips = flipsForMove(idx, player);
    if (flips.isEmpty) return false;
    // snapshot before move
    _history.add(_Snapshot(List.from(board), currentPlayer));
    board[idx] = player;
    for (var f in flips) board[f] = player;
    currentPlayer = -player;
    return true;
  }

  List<int> legalMoves(int player) {
    List<int> moves = [];
    for (int i = 0; i < board.length; i++) {
      if (board[i] == 0 && flipsForMove(i, player).isNotEmpty) moves.add(i);
    }
    return moves;
  }

  List<int> flipsForMove(int idx, int player) {
    if (idx < 0 || idx >= board.length) return [];
    if (board[idx] != 0) return [];
    int x = idx % size;
    int y = idx ~/ size;
    List<int> result = [];
    const dirs = [
      [-1, -1],
      [0, -1],
      [1, -1],
      [-1, 0],
      [1, 0],
      [-1, 1],
      [0, 1],
      [1, 1]
    ];
    for (var d in dirs) {
      int dx = d[0], dy = d[1];
      int cx = x + dx, cy = y + dy;
      List<int> candidates = [];
      while (cx >= 0 && cx < size && cy >= 0 && cy < size) {
        int cidx = _idx(cx, cy);
        if (board[cidx] == 0) {
          candidates.clear();
          break;
        }
        if (board[cidx] == player) {
          // captured
          result.addAll(candidates);
          break;
        } else {
          candidates.add(cidx);
        }
        cx += dx;
        cy += dy;
      }
    }
    return result;
  }

  bool undoTwoMoves() {
    if (_history.length < 2) return false;
    // undo AI move
    var last = _history.removeLast();
    // undo human move
    var prev = _history.removeLast();
    board = List.from(prev.board);
    currentPlayer = prev.currentPlayer;
    return true;
  }

  bool isGameOver() {
    if (board.every((v) => v != 0)) return true;
    return legalMoves(1).isEmpty && legalMoves(-1).isEmpty;
  }

  Map<String, int> score() {
    int b = 0, w = 0;
    for (var v in board) {
      if (v == 1) b++;
      if (v == -1) w++;
    }
    return {'black': b, 'white': w};
  }
}

class _Snapshot {
  final List<int> board;
  final int currentPlayer;
  _Snapshot(this.board, this.currentPlayer);
}
