module Chess
  module Piece
    class Queen < Base
      def move_list(game, check_validity = true)
        super do
          moves = []
          # Diagonals
          moves.concat(construct_vector_movements(game, { rank: -1, file: -1 }))
          moves.concat(construct_vector_movements(game, { rank: -1, file:  1 }))
          moves.concat(construct_vector_movements(game, { rank:  1, file: -1 }))
          moves.concat(construct_vector_movements(game, { rank:  1, file:  1 }))
          # Cardinals
          moves.concat(construct_vector_movements(game, { rank:  0, file: -1 }))
          moves.concat(construct_vector_movements(game, { rank:  0, file:  1 }))
          moves.concat(construct_vector_movements(game, { rank: -1, file:  0 }))
          moves.concat(construct_vector_movements(game, { rank:  1, file:  0 }))
        end
      end
    end
  end
end
