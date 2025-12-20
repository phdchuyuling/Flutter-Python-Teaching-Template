class Game {
  static const int boardSize = 8;
  static const int size = boardSize; // Alias for compatibility
  late List<int> board;
  int currentPlayer = 1; // 1 for black, -1 for white (AI)
  List<List<int>> history = [];

  Game() {
    initializeBoard();
  }

  void initializeBoard() {
    board = List<int>.filled(boardSize * boardSize, 0);
    
    // Initial setup: 4 pieces in the center
    // board[row * size + col]
    board[3 * boardSize + 3] = -1;
    board[3 * boardSize + 4] = 1;
    board[4 * boardSize + 3] = 1;
    board[4 * boardSize + 4] = -1;
  }

  void reset() {
    history.clear();
    currentPlayer = 1;
    initializeBoard();
  }

  List<int> getValidMoves() {
    List<int> validMoves = [];
    for (int idx = 0; idx < boardSize * boardSize; idx++) {
      int row = idx ~/ boardSize;
      int col = idx % boardSize;
      if (board[idx] == 0 && canMove(row, col, currentPlayer)) {
        validMoves.add(idx);
      }
    }
    return validMoves;
  }

  List<int> legalMoves(int player) {
    List<int> validMoves = [];
    for (int idx = 0; idx < boardSize * boardSize; idx++) {
      if (board[idx] == 0) {
        int row = idx ~/ boardSize;
        int col = idx % boardSize;
        if (canMove(row, col, player)) {
          validMoves.add(idx);
        }
      }
    }
    return validMoves;
  }

  bool canMove(int row, int col, int player) {
    if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) return false;
    if (board[row * boardSize + col] != 0) return false;

    // Check all 8 directions
    List<List<int>> directions = [
      [-1, -1],
      [-1, 0],
      [-1, 1],
      [0, -1],
      [0, 1],
      [1, -1],
      [1, 0],
      [1, 1],
    ];

    for (var dir in directions) {
      if (hasFlips(row, col, dir[0], dir[1], player)) {
        return true;
      }
    }
    return false;
  }

  bool hasFlips(int row, int col, int dr, int dc, int player) {
    int r = row + dr;
    int c = col + dc;
    int opponent = player == 1 ? -1 : 1;
    bool foundOpponent = false;

    while (r >= 0 && r < boardSize && c >= 0 && c < boardSize) {
      int piece = board[r * boardSize + c];
      if (piece == 0) return false;
      if (piece == player) return foundOpponent;
      foundOpponent = true;
      r += dr;
      c += dc;
    }
    return false;
  }

  Set<int> flipsForMove(int idx, int player) {
    int row = idx ~/ boardSize;
    int col = idx % boardSize;
    Set<int> flipped = {};

    if (!canMove(row, col, player)) return flipped;

    List<List<int>> directions = [
      [-1, -1],
      [-1, 0],
      [-1, 1],
      [0, -1],
      [0, 1],
      [1, -1],
      [1, 0],
      [1, 1],
    ];

    for (var dir in directions) {
      List<int> toFlip = _getFlipsInDirection(row, col, dir[0], dir[1], player);
      flipped.addAll(toFlip);
    }

    return flipped;
  }

  List<int> _getFlipsInDirection(int row, int col, int dr, int dc, int player) {
    List<int> toFlip = [];
    int r = row + dr;
    int c = col + dc;
    int opponent = player == 1 ? -1 : 1;

    while (r >= 0 && r < boardSize && c >= 0 && c < boardSize) {
      int piece = board[r * boardSize + c];
      if (piece == 0) return [];
      if (piece == player) return toFlip;
      toFlip.add(r * boardSize + c);
      r += dr;
      c += dc;
    }
    return [];
  }

  bool makeMove(int idx, int player) {
    int row = idx ~/ boardSize;
    int col = idx % boardSize;
    
    if (!canMove(row, col, player)) return false;

    // Save current board state
    history.add(List<int>.from(board));

    board[idx] = player;

    // Get and flip opponent pieces
    Set<int> flipped = flipsForMove(idx, player);
    for (int flipIdx in flipped) {
      board[flipIdx] = player;
    }

    // Switch player
    currentPlayer = currentPlayer == 1 ? -1 : 1;
    return true;
  }

  bool undoTwoMoves() {
    if (history.length < 2) return false;
    history.removeLast();
    history.removeLast();
    if (history.isNotEmpty) {
      board = List<int>.from(history.last);
    } else {
      initializeBoard();
    }
    currentPlayer = 1; // Reset to human's turn
    return true;
  }

  void undo() {
    if (history.isNotEmpty) {
      board = history.removeLast();
      currentPlayer = currentPlayer == 1 ? -1 : 1;
    }
  }

  bool isGameOver() {
    // Game is over if neither player can move
    bool player1CanMove = getValidMoves().isNotEmpty;
    
    // Check if AI can move
    int tempPlayer = currentPlayer;
    currentPlayer = -1;
    bool aiCanMove = legalMoves(-1).isNotEmpty;
    currentPlayer = tempPlayer;
    
    return !player1CanMove && !aiCanMove;
  }

  Map<String, int> score() {
    int blackCount = 0;
    int whiteCount = 0;
    for (int piece in board) {
      if (piece == 1) blackCount++;
      if (piece == -1) whiteCount++;
    }
    return {'black': blackCount, 'white': whiteCount};
  }

  int getScore(int player) {
    int count = 0;
    for (int piece in board) {
      if (piece == player) count++;
    }
    return count;
  }
}
