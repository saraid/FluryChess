module Chess
  module Piece
    class King < Base
      def move_list(game, check_validity = true)
        super do
          moves = []
          adjustments = [
            { :rank =>  1, :file =>  1 },
            { :rank =>  1, :file =>  0 },
            { :rank =>  1, :file => -1 },
            { :rank => -1, :file =>  1 },
            { :rank => -1, :file =>  0 },
            { :rank => -1, :file => -1 },
            { :rank =>  0, :file =>  1 },
            { :rank =>  0, :file => -1 }
          ]
          moves.concat(
            construct_move_set_from_adjustments(game, adjustments)
          )

          [
            { side: side, type: :kingside },
            { side: side, type: :queenside }
          ].
            select(&game.method(:can_castle?)).
            each do |castling_options|
              options = { origin: position, type: castling_options[:type] }
              moves << Chess::Move::Castle.new(game, options)
          end

          moves
        end
      end
    end
  end
end
