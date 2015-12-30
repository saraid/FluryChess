require_relative '../notation'

module Chess
  module Move
    class Base
      include Chess::Notation::StandardAlgebraic::MoveSerializer
      include MemoizableMethods

      # Not implemented yet
      #include Chess::Notation::LongAlgebraic::MoveSerializer
      #include Chess::Notation::ReversibleAlgebraic::MoveSerializer
      #include Chess::Notation::ConciseReversibleAlgebraic::MoveSerializer
      #include Chess::Notation::Smith::MoveSerializer
      #include Chess::Notation::ICCFNumeric::MoveSerializer
      #include Chess::Notation::Coordinate::MoveSerializer

      def initialize(game_state, options)
        @game_state = game_state.dup
        @options = options
      end
      attr_reader :game_state, :options

      def inspect
        to_san
      end

      def board
        game_state.board
      end

      def piece_to_move
        options[:origin].occupant
      end
      alias :piece :piece_to_move

      def destination
        options[:destination]
      end

      def valid?
        return false if game_state.active_color != piece_to_move.side
        return false if destination.occupied? && !capture?
        return false if destination.occupant.try(:side) == piece_to_move.side
        return false if checks_own_side?
        true
      end

      def capture?
        destination.occupied? && destination.occupant.try(:side) != piece_to_move.side
      end

      def half_move?
        !capture? && !(Chess::Piece::Pawn === piece)
      end

      def state_change
        @state_change ||= {}
      end

      # returns new game state
      def take
        state_change[:board] = game_state.board.dup
        copied_piece = state_change[:board][piece.position.to_s].occupant
        if copied_piece.nil?
          puts state_change[:board].to_ascii
          raise to_san 
        end
        copied_piece.place_on(state_change[:board], destination.to_s)
        yield if block_given?
        state_change[:castling_availability] = castling_change
        state_change[:half_move] = half_move?
        game_state.to_state(state_change.delete_if { |_, v| v.nil? })
      end

      def checks_enemy_side?
        memoize do
          new_state = take
          enemy_king = new_state.board.king(other_side).position rescue nil
          return false if enemy_king.nil? # TODO: Test design failure.
          new_state.board.all_pieces.
            select { |piece_obj| piece_obj.side == piece.side }.
            any? do |piece_obj|
              piece_obj.move_list(new_state, false).collect(&:destination).include? enemy_king
            end
        end
      end

      def checkmate?
        memoize do
          if checks_enemy_side?
            new_state = take
            enemy_king = new_state.board.king(other_side)
            enemy_king.move_list(new_state).empty?
          end
        end
      end

      def checks_own_side?
        memoize do
          new_state = take
          own_king = new_state.board.king(piece.side).position rescue nil
          return false if own_king.nil? # TODO: Test design failure.
          new_state.board.all_pieces.
            select { |piece_obj| piece_obj.side == other_side }.
            any? do |piece_obj|
              piece_obj.move_list(new_state, false).collect(&:destination).include? own_king
            end
        end
      end

      def to_english
        memoize do
          parts = []
          parts << (piece_name = piece.class.to_s.split('::').last)
          parts <<
            if capture?
              [ 'captures',
                destination.occupant.side.to_s,
                destination.occupant.class.to_s.split('::').last.downcase,
                'on' ]
            else
              'moves to'
            end
          parts << destination.to_s
          parts.join(' ') + '.'
        end
      end

      private
      def other_side
        case piece.side
        when :white then :black
        when :black then :white
        end
      end

      def castling_change
        case piece
        when Chess::Piece::King
          { side: piece_to_move.side }
        when Chess::Piece::Rook
          type = case piece.position.file
          when 'a' then :queenside
          when 'h' then :kingside
          end
          { side: piece_to_move.side, type: type } unless type.nil?
        end
      end
    end
  end
end
