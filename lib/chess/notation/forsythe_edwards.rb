module Chess
  module Notation
    class ForsytheEdwards
      REGEX = begin
        placement_regex = '[A-Za-z1-8]{1,8}'
        Regexp.new(%W(
          (?<placement_text>#{([placement_regex] * 8).join('/')})
          (?<active_color>[wb])
          (?<castling_availability>[KQkq]{1,4}|-)
          (?<en_passant_target>(?:[a-h][1-8])|-)
          (?<half_move_clock>\\d+)
          (?<full_move_clock>\\d+)
        ).join('\s+'))
      end

      PIECE_MAPPING = {
        'K' => Chess::Piece::King,
        'Q' => Chess::Piece::Queen,
        'R' => Chess::Piece::Rook,
        'B' => Chess::Piece::Bishop,
        'N' => Chess::Piece::Knight,
        'P' => Chess::Piece::Pawn
      }
    end
  end
end
