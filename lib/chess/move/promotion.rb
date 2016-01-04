module Chess
  module Move
    class Promotion < Base
      class InvalidRankForPromotion < Chess::Error; end

      VALID_PROMOTION_RANKS = [
        Chess::Piece::Queen,
        Chess::Piece::Knight,
        Chess::Piece::Rook,
        Chess::Piece::Bishop
      ]

      def initialize(*args)
        super(*args)
        raise InvalidRankForPromotion unless VALID_PROMOTION_RANKS.include? options[:new_rank]
      end

      def take
        super do
          options[:new_rank].new(piece.side).place_on(state_change[:board], destination.to_s)
        end
      end

      def to_english
        [ super.sub(/\.$/, ''),
          'and promotes to',
          options[:new_rank].to_s.split('::').last
        ].join(' ') + '.'
      end
    end
  end
end
