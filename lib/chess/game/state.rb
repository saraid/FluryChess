module Chess
  class Game
    class State
      def self.from_state(state, with_changes = {})
        options = state.to_hash
        options[:board] = with_changes[:board]
        options[:en_passant_target] = with_changes[:en_passant_target]
        options[:castling_availability] =
          state.castling_availability.without(with_changes[:castling_availability])
        options[:half_move_clock] = with_changes[:half_move] ? options[:half_move_clock] + 1 : 0
        options[:full_move_number] += 1 if state.active_color == :black
        options[:active_color] = state.next_color
        State.new(options)
      end

      class CastlingAvailability
        ENCODING = {
          'K'  => { :side => :white, :type => :kingside },
          'Q'  => { :side => :white, :type => :queenside },
          'k'  => { :side => :black, :type => :kingside },
          'q'  => { :side => :black, :type => :queenside },
          'KQ' => { :side => :white },
          'kq' => { :side => :black }
        }.invert

        rattr_initialize :fen_code

        def include?(options)
          fen_code.include? ENCODING[options]
        end

        def without(options)
          return fen_code if options.nil?
          raise ArgumentError, 'Must also define :side' unless options[:side]
          @fen_code.delete! ENCODING[options]
          @fen_code = '-' if @fen_code.empty?

          @fen_code
        end
      end

      def initialize(options)
        @board = options[:board] ||
          Chess::Board.from_fen(Chess::Board::Configuration::Standard.as_fen)
        @en_passant_target = options[:en_passant_target]
        @castling_availability = CastlingAvailability.new(
          options[:castling_availability] || 'KQkq'
        )
        @half_move_clock = options[:half_move_clock] || 0
        @full_move_number = options[:full_move_number] || 1
        @active_color = options[:active_color] || :white
      end
      attr_reader :board, :en_passant_target, :castling_availability,
        :half_move_clock, :full_move_number, :active_color

      def can_castle?(options)
        @castling_availability.include? options
      end

      def next_color
        case @active_color
        when :white then :black
        when :black then :white
        end
      end

      def state
        self
      end
      alias :current_state :state

      def to_fen
        [ board.to_fen,
          active_color == :white ? 'w' : 'b',
          @castling_availability.fen_code,
          @en_passant_target || '-',
          @half_move_clock,
          @full_move_number
        ].join(' ')
      end

      def to_hash
        hash = {}
        hash[:en_passant_target] = en_passant_target
        hash[:castling_availability] = castling_availability.fen_code
        hash[:half_move_clock] = half_move_clock
        hash[:full_move_number] = full_move_number
        hash[:active_color] = active_color
        hash
      end

      def to_state(with_changes)
        State.from_state(self, with_changes)
      end
    end
  end
end
