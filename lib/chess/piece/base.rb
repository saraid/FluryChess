require 'attr_extras'

module Chess
  module Piece
    class Base
      rattr_initialize :side
      attr_reader :position

      def place_on(board, square)
        board[@position.to_s].occupy_with(nil) unless @position.nil?
        if square.nil?
          @position = nil
        else
          (@position = board[square]).occupy_with self
        end
      end

      def move_list(game, check_validity)
        @moves ||= {}
        raise NotImplementedError unless block_given?
        key = [game.to_fen, check_validity].join(' ')
        @moves[key] ||=
          begin
            moves = yield
            moves.select!(&:valid?) if check_validity
            moves
          end
      end

      def to_fen
        Chess::Notation::ForsytheEdwards::PIECE_MAPPING.invert[self.class].
          send(side == :white ? :upcase : :downcase)
      end

      def to_unicode
        raise NotImplementedError
      end

      protected
      def construct_move_set_from_adjustments(game, adjustments, extra_options = {})
        board = game.board
        file_indices = ('a'..'h').to_a

        adjustments.collect do |adjustment|
          file_index = file_indices.index(@position.file) + adjustment[:file]
          next unless (1..8).include? file_index.succ
          file = file_indices[file_index]

          rank = @position.rank + adjustment[:rank]
          next unless (1..8).include? rank

          destination = board["#{file}#{rank}"]
          options = extra_options.merge(origin: @position, destination: destination)
          Chess::Move::Base.new(game, options)
        end.
          compact
      end

      def construct_vector_movements(game, vector, extra_options = {})
        board = game.board
        file_indices = ('a'..'h').to_a

        walk_vector = lambda do |adjustments|
          obstacle_found = false
          adjustments.collect do |adjustment|
            next if obstacle_found

            file_index = file_indices.index(@position.file) + adjustment[:file]
            unless (1..8).include? file_index.succ
              obstacle_found = true
              next
            end
            file = file_indices[file_index]

            rank = @position.rank + adjustment[:rank]
            unless (1..8).include? rank
              obstacle_found = true
              next
            end

            destination = board["#{file}#{rank}"]
            if destination.occupied? 
              obstacle_found = true
              next if destination.occupant.side == side
            end
            options = extra_options.merge(origin: @position, destination: destination)
            Chess::Move::Base.new(game, options)
          end.compact
        end

        walk_vector.call(
          (1..8).to_a.
            collect { |scalar| { rank: vector[:rank] * scalar, file: vector[:file] * scalar } }
        )
      end
    end
  end
end
