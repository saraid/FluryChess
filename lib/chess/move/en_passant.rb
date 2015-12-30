module Chess
  module Move
    class EnPassant < Base
      def capture?
        true
      end

      def take
        super do
          state_change[:board][position_of_pawn_to_capture.to_s].occupy_with nil
        end
      end

      def to_english
        memoize do
          parts = []
          parts << (piece_name = piece.class.to_s.split('::').last)
          parts << 'moves to'
          parts << destination.to_s + ','
          parts << 'capturing'
          parts << position_of_pawn_to_capture.to_s
          parts << 'en passant'
          parts.join(' ') + '.'
        end
      end

      private
      def position_of_pawn_to_capture
        memoize do
          target = game_state.en_passant_target
          state_change[:board].
            next_rank(target.rank, enemy_side).
            [](('a'..'h').to_a.index(target.file))
        end
      end

      def enemy_side
        case piece.side
        when :white then :black
        when :black then :white
        end
      end
    end
  end
end
