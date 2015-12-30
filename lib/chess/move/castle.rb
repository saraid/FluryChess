module Chess
  module Move
    class Castle < Base
      def destination
        case piece_to_move.side
        when :white
          case options[:type]
          when :kingside then board['g1']
          when :queenside then board['b1']
          end
        when :black
          case options[:type]
          when :kingside then board['g8']
          when :queenside then board['b8']
          end
        end
      end

      def valid?
        return false unless super
        return false if blocked?
        true
      end

      def take
        super do
          state_change[:board][rook_location].occupant.place_on(
            state_change[:board], rook_target
          )
        end
      end

      def to_english
        [ piece.side.to_s.capitalize,
          'King castles',
          options[:type]
        ].join(' ') + '.'
      end

      private
      def blocked?
        positions =
          case piece_to_move.side
          when :white
            case options[:type]
            when :kingside then %w(f1 g1)
            when :queenside then %w(b1 c1 d1)
            end
          when :black
            case options[:type]
            when :kingside then %w(f8 g8)
            when :queenside then %w(b8 c8 d8)
            end
          end
        positions.collect(&board.method(:[])).any?(&:occupied?)
      end

      def rook_location
        case piece_to_move.side
        when :white
          case options[:type]
          when :kingside then 'h1'
          when :queenside then 'a1'
          end
        when :black
          case options[:type]
          when :kingside then 'h8'
          when :queenside then 'a8'
          end
        end
      end

      def rook_target
        case piece_to_move.side
        when :white
          case options[:type]
          when :kingside then 'f1'
          when :queenside then 'c1'
          end
        when :black
          case options[:type]
          when :kingside then 'f8'
          when :queenside then 'c8'
          end
        end
      end
    end
  end
end
