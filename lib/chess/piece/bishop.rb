module Chess
  module Piece
    class Bishop < Base
      def move_list(game, check_validity = true)
        super do
          moves = []
          moves.concat(construct_vector_movements(game, { rank: -1, file: -1 }))
          moves.concat(construct_vector_movements(game, { rank: -1, file:  1 }))
          moves.concat(construct_vector_movements(game, { rank:  1, file: -1 }))
          moves.concat(construct_vector_movements(game, { rank:  1, file:  1 }))
        end
      end

      def to_unicode
        case side
        when :white then '♗'
        when :black then '♝'
        end
      end
    end
  end
end
