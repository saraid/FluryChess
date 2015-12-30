module Chess
  module Piece
    class Rook < Base
      def move_list(game, check_validity = true)
        super do
          moves = []
          moves.concat(construct_vector_movements(game, { rank:  0, file: -1 }))
          moves.concat(construct_vector_movements(game, { rank:  0, file:  1 }))
          moves.concat(construct_vector_movements(game, { rank: -1, file:  0 }))
          moves.concat(construct_vector_movements(game, { rank:  1, file:  0 }))
        end
      end
    end
  end
end
