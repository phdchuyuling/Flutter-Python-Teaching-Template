import 'dart:math';

enum Player { red, black }

enum PieceType { general, advisor, elephant, horse, chariot, cannon, soldier }

class Piece {
  final Player owner;
  final PieceType type;

  Piece(this.owner, this.type);

  String shortName() {
    switch (type) {
      case PieceType.general:
        return owner == Player.red ? '帥' : '將';
      case PieceType.advisor:
        return owner == Player.red ? '仕' : '士';
      case PieceType.elephant:
        return owner == Player.red ? '相' : '象';
      case PieceType.horse:
        return '馬';
      case PieceType.chariot:
        return '車';
      case PieceType.cannon:
        return '炮';
      case PieceType.soldier:
        return owner == Player.red ? '兵' : '卒';
    }
  }
}

class Move {
  final int fromRow, fromCol, toRow, toCol;
  final Piece? captured;

  Move(this.fromRow, this.fromCol, this.toRow, this.toCol, this.captured);

  @override
  String toString() => '(${fromRow},${fromCol})->(${toRow},${toCol})';
}

class XiangQiGame {
  static const int rows = 10;
  static const int cols = 9;

  List<List<Piece?>> board = List.generate(rows, (_) => List.filled(cols, null));
  Player turn = Player.red;
  List<Move> history = [];

  XiangQiGame() {
    reset();
  }

  void reset() {
    board = List.generate(rows, (_) => List.filled(cols, null));
    turn = Player.red;
    history = [];
    _setupBoard();
  }

  void _setupBoard() {
    board[0][0] = Piece(Player.black, PieceType.chariot);
    board[0][8] = Piece(Player.black, PieceType.chariot);
    board[9][0] = Piece(Player.red, PieceType.chariot);
    board[9][8] = Piece(Player.red, PieceType.chariot);
    board[0][1] = Piece(Player.black, PieceType.horse);
    board[0][7] = Piece(Player.black, PieceType.horse);
    board[9][1] = Piece(Player.red, PieceType.horse);
    board[9][7] = Piece(Player.red, PieceType.horse);
    board[0][2] = Piece(Player.black, PieceType.elephant);
    board[0][6] = Piece(Player.black, PieceType.elephant);
    board[9][2] = Piece(Player.red, PieceType.elephant);
    board[9][6] = Piece(Player.red, PieceType.elephant);
    board[0][3] = Piece(Player.black, PieceType.advisor);
    board[0][5] = Piece(Player.black, PieceType.advisor);
    board[9][3] = Piece(Player.red, PieceType.advisor);
    board[9][5] = Piece(Player.red, PieceType.advisor);
    board[0][4] = Piece(Player.black, PieceType.general);
    board[9][4] = Piece(Player.red, PieceType.general);
    board[2][1] = Piece(Player.black, PieceType.cannon);
    board[2][7] = Piece(Player.black, PieceType.cannon);
    board[7][1] = Piece(Player.red, PieceType.cannon);
    board[7][7] = Piece(Player.red, PieceType.cannon);
    for (int c = 0; c < 9; c += 2) {
      board[3][c] = Piece(Player.black, PieceType.soldier);
      board[6][c] = Piece(Player.red, PieceType.soldier);
    }
  }

  bool inBoard(int r, int c) => r >= 0 && r < rows && c >= 0 && c < cols;

  List<Move> legalMovesFor(int r, int c) {
    final p = board[r][c];
    if (p == null) return [];
    if (p.owner != turn) return [];
    List<Move> moves = [];
    switch (p.type) {
      case PieceType.chariot:
        for (int rr = r - 1; rr >= 0; rr--) {
          if (board[rr][c] == null)
            moves.add(Move(r, c, rr, c, null));
          else {
            if (board[rr][c]!.owner != p.owner) moves.add(Move(r, c, rr, c, board[rr][c]));
            break;
          }
        }
        for (int rr = r + 1; rr < rows; rr++) {
          if (board[rr][c] == null)
            moves.add(Move(r, c, rr, c, null));
          else {
            if (board[rr][c]!.owner != p.owner) moves.add(Move(r, c, rr, c, board[rr][c]));
            break;
          }
        }
        for (int cc = c - 1; cc >= 0; cc--) {
          if (board[r][cc] == null)
            moves.add(Move(r, c, r, cc, null));
          else {
            if (board[r][cc]!.owner != p.owner) moves.add(Move(r, c, r, cc, board[r][cc]));
            break;
          }
        }
        for (int cc = c + 1; cc < cols; cc++) {
          if (board[r][cc] == null)
            moves.add(Move(r, c, r, cc, null));
          else {
            if (board[r][cc]!.owner != p.owner) moves.add(Move(r, c, r, cc, board[r][cc]));
            break;
          }
        }
        break;
      case PieceType.horse:
        final dirs = [
          [-2, -1],
          [-2, 1],
          [2, -1],
          [2, 1],
          [-1, -2],
          [1, -2],
          [-1, 2],
          [1, 2]
        ];
        for (var d in dirs) {
          int nr = r + d[0];
          int nc = c + d[1];
          if (inBoard(nr, nc)) {
            if (board[nr][nc] == null || board[nr][nc]!.owner != p.owner)
              moves.add(Move(r, c, nr, nc, board[nr][nc]));
          }
        }
        break;
      case PieceType.soldier:
        int dir = p.owner == Player.red ? -1 : 1;
        int nr = r + dir;
        if (inBoard(nr, c)) {
          if (board[nr][c] == null || board[nr][c]!.owner != p.owner) moves.add(Move(r, c, nr, c, board[nr][c]));
        }
        if ((p.owner == Player.red && r <= 4) || (p.owner == Player.black && r >= 5)) {
          for (int dc in [-1, 1]) {
            int nc = c + dc;
            if (inBoard(r, nc)) {
              if (board[r][nc] == null || board[r][nc]!.owner != p.owner) moves.add(Move(r, c, r, nc, board[r][nc]));
            }
          }
        }
        break;
      case PieceType.cannon:
        for (int rr = r - 1; rr >= 0; rr--) {
          if (board[rr][c] == null)
            moves.add(Move(r, c, rr, c, null));
          else
            break;
        }
        for (int rr = r + 1; rr < rows; rr++) {
          if (board[rr][c] == null)
            moves.add(Move(r, c, rr, c, null));
          else
            break;
        }
        for (int cc = c - 1; cc >= 0; cc--) {
          if (board[r][cc] == null)
            moves.add(Move(r, c, r, cc, null));
          else
            break;
        }
        for (int cc = c + 1; cc < cols; cc++) {
          if (board[r][cc] == null)
            moves.add(Move(r, c, r, cc, null));
          else
            break;
        }
        int cnt = 0;
        for (int rr = r - 1; rr >= 0; rr--) {
          if (board[rr][c] != null) cnt++;
          if (cnt == 2) {
            if (board[rr][c]!.owner != p.owner) moves.add(Move(r, c, rr, c, board[rr][c]));
            break;
          }
        }
        cnt = 0;
        for (int rr = r + 1; rr < rows; rr++) {
          if (board[rr][c] != null) cnt++;
          if (cnt == 2) {
            if (board[rr][c]!.owner != p.owner) moves.add(Move(r, c, rr, c, board[rr][c]));
            break;
          }
        }
        cnt = 0;
        for (int cc = c - 1; cc >= 0; cc--) {
          if (board[r][cc] != null) cnt++;
          if (cnt == 2) {
            if (board[r][cc]!.owner != p.owner) moves.add(Move(r, c, r, cc, board[r][cc]));
            break;
          }
        }
        cnt = 0;
        for (int cc = c + 1; cc < cols; cc++) {
          if (board[r][cc] != null) cnt++;
          if (cnt == 2) {
            if (board[r][cc]!.owner != p.owner) moves.add(Move(r, c, r, cc, board[r][cc]));
            break;
          }
        }
        break;
      case PieceType.general:
        final palaceCols = [3, 4, 5];
        final palaceRowsRed = [7, 8, 9];
        final palaceRowsBlack = [0, 1, 2];
        List<int> dr = [-1, 1, 0, 0];
        List<int> dc = [0, 0, -1, 1];
        for (int i = 0; i < 4; i++) {
          int nr = r + dr[i];
          int nc = c + dc[i];
          if (!inBoard(nr, nc)) continue;
          if (!palaceCols.contains(nc)) continue;
          if (p.owner == Player.red && !palaceRowsRed.contains(nr)) continue;
          if (p.owner == Player.black && !palaceRowsBlack.contains(nr)) continue;
          if (board[nr][nc] == null || board[nr][nc]!.owner != p.owner) moves.add(Move(r, c, nr, nc, board[nr][nc]));
        }
        break;
      default:
        break;
    }
    return moves;
  }

  List<Move> allLegalMoves() {
    List<Move> res = [];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final p = board[r][c];
        if (p != null && p.owner == turn) {
          res.addAll(legalMovesFor(r, c));
        }
      }
    }
    return res;
  }

  void makeMove(Move m) {
    final p = board[m.fromRow][m.fromCol];
    if (p == null) return;
    history.add(Move(m.fromRow, m.fromCol, m.toRow, m.toCol, board[m.toRow][m.toCol]));
    board[m.toRow][m.toCol] = p;
    board[m.fromRow][m.fromCol] = null;
    turn = turn == Player.red ? Player.black : Player.red;
  }

  void undo() {
    if (history.isEmpty) return;
    final m = history.removeLast();
    final p = board[m.toRow][m.toCol];
    board[m.fromRow][m.fromCol] = p;
    board[m.toRow][m.toCol] = m.captured;
    turn = turn == Player.red ? Player.black : Player.red;
  }

  bool isGameOver() {
    bool hasRedGeneral = false;
    bool hasBlackGeneral = false;
    for (var row in board) {
      for (var p in row) {
        if (p != null && p.type == PieceType.general) {
          if (p.owner == Player.red) hasRedGeneral = true;
          if (p.owner == Player.black) hasBlackGeneral = true;
        }
      }
    }
    return !(hasRedGeneral && hasBlackGeneral);
  }

  int evaluateBoard(Player forPlayer) {
    int score = 0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final p = board[r][c];
        if (p == null) continue;
        int val = 0;
        switch (p.type) {
          case PieceType.general:
            val = 10000;
            break;
          case PieceType.chariot:
            val = 900;
            break;
          case PieceType.horse:
            val = 450;
            break;
          case PieceType.cannon:
            val = 400;
            break;
          case PieceType.elephant:
            val = 250;
            break;
          case PieceType.advisor:
            val = 250;
            break;
          case PieceType.soldier:
            val = 100;
            break;
        }
        score += (p.owner == forPlayer) ? val : -val;
      }
    }
    return score;
  }

  String boardString() {
    StringBuffer sb = StringBuffer();
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final p = board[r][c];
        sb.write(p?.shortName() ?? '．');
      }
      sb.writeln();
    }
    return sb.toString();
  }
}

class AiPlayer {
  final int depth;
  final Random rnd = Random();

  AiPlayer(this.depth);

  Move? findBestMove(XiangQiGame g) {
    var moves = g.allLegalMoves();
    if (moves.isEmpty) return null;
    Move? best;
    int bestScore = -99999999;
    for (var m in moves) {
      XiangQiGame copy = _copyGame(g);
      copy.makeMove(m);
      int sc = -_negamax(copy, depth - 1, -99999999, 99999999, g.turn);
      if (sc > bestScore || (sc == bestScore && rnd.nextBool())) {
        bestScore = sc;
        best = m;
      }
    }
    return best;
  }

  int _negamax(XiangQiGame g, int depth, int alpha, int beta, Player original) {
    if (g.isGameOver() || depth == 0) {
      return g.evaluateBoard(original);
    }
    int maxEval = -99999999;
    var moves = g.allLegalMoves();
    if (moves.isEmpty) return g.evaluateBoard(original);
    for (var m in moves) {
      XiangQiGame copy = _copyGame(g);
      copy.makeMove(m);
      int eval = -_negamax(copy, depth - 1, -beta, -alpha, original);
      if (eval > maxEval) maxEval = eval;
      if (eval > alpha) alpha = eval;
      if (alpha >= beta) break;
    }
    return maxEval;
  }

  XiangQiGame _copyGame(XiangQiGame g) {
    XiangQiGame c = XiangQiGame();
    c.board = List.generate(XiangQiGame.rows, (r) => List.generate(XiangQiGame.cols, (c2) => g.board[r][c2] == null ? null : Piece(g.board[r][c2]!.owner, g.board[r][c2]!.type)));
    c.turn = g.turn;
    c.history = List.from(g.history);
    return c;
  }
}

void main(List<String> args) {
  int depthRed = 3;
  int depthBlack = 3;
  int maxMoves = 200;

  for (var a in args) {
    if (a.startsWith('--depth-red=')) depthRed = int.parse(a.split('=')[1]);
    if (a.startsWith('--depth-black=')) depthBlack = int.parse(a.split('=')[1]);
    if (a.startsWith('--max-moves=')) maxMoves = int.parse(a.split('=')[1]);
  }

  print('Starting AI vs AI: red depth=$depthRed vs black depth=$depthBlack');
  XiangQiGame g = XiangQiGame();
  AiPlayer aiRed = AiPlayer(depthRed);
  AiPlayer aiBlack = AiPlayer(depthBlack);

  print(g.boardString());

  int moveCount = 0;
  while (!g.isGameOver() && moveCount < maxMoves) {
    AiPlayer ai = g.turn == Player.red ? aiRed : aiBlack;
    Move? m = ai.findBestMove(g);
    if (m == null) {
      print('No moves available for ${g.turn}');
      break;
    }
    final p = g.board[m.fromRow][m.fromCol];
    print('${++moveCount}. ${g.turn == Player.red ? 'Red' : 'Black'} ${p?.shortName() ?? '?'} ${m}');
    g.makeMove(m);
    print(g.boardString());
  }

  print('Game over? ${g.isGameOver()} Moves: $moveCount');
  print('Winner: ${g.isGameOver() ? (g.turn == Player.red ? 'Black' : 'Red') : 'None'}');
  print('Final evaluation for Red: ${g.evaluateBoard(Player.red)}');
}
