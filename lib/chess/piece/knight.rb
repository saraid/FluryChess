module Chess
  module Piece
    class Knight < Base
      def move_list(game, check_validity = true)
        super do
          adjustments = [
            { :rank =>  2, :file =>  1},
            { :rank =>  2, :file => -1},
            { :rank => -2, :file =>  1},
            { :rank => -2, :file => -1},
            { :rank =>  1, :file =>  2},
            { :rank =>  1, :file => -2},
            { :rank => -1, :file =>  2},
            { :rank => -1, :file => -2}
          ]
          moves = construct_move_set_from_adjustments(game, adjustments)
        end
      end
    end
  end
end
