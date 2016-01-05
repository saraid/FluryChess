module Chess
  module Notation
    class FigurineAlgebraic < StandardAlgebraic
      PIECE_MAPPING = {
        '♔' => Chess::Piece::King,
        '♚' => Chess::Piece::King,
        '♕' => Chess::Piece::Queen,
        '♛' => Chess::Piece::Queen,
        '♖' => Chess::Piece::Rook,
        '♜' => Chess::Piece::Rook,
        '♗' => Chess::Piece::Bishop,
        '♝' => Chess::Piece::Bishop,
        '♘' => Chess::Piece::Knight,
        '♞' => Chess::Piece::Knight,
        '♙' => Chess::Piece::Pawn,
        '♟' => Chess::Piece::Pawn
      }
    end
  end
end
