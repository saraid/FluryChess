module Chess
  class Board
    module Configuration
      class Standard
        def self.as_fen
          # Correct FEN:
          #'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
          # Without game state annotations
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR'
        end
      end

      class Empty
        def self.as_fen
          '8/8/8/8/8/8/8/8'
        end
      end
    end

    def self.from_fen(fen)
      board = self.new
      rank_index = 8
      mapping = Chess::Notation::ForsytheEdwards::PIECE_MAPPING

      fen.
        sub(/\s.*$/, ''). # dump everything after first whitespace
        split('/').each do |rank|
        file_index = 'a'
        rank.split('').each do |file|
          case file.upcase
          when /[#{mapping.keys.join}]/
            color = /[A-Z]/ =~ file ? :white : :black
            mapping[file.upcase].new(color).
              place_on(board, "#{file_index}#{rank_index}")
            file_index = file_index.succ
          when /[1-8]/ # empty squares
            file.to_i.times { file_index = file_index.succ }
          end
        end
        rank_index -= 1
      end

      board
    end

    def initialize
      @squares = {}
      ('a'..'h').each do |file|
        (1..8).each do |rank|
          @squares["#{file}#{rank}"] = Square.new(rank, file)
        end
      end
    end

    def [](coord)
      @squares[coord]
    end

    def dup
      duplicate = super
      duplicate.instance_variable_set(:@squares, {})
      square_dup = duplicate.instance_variable_get(:@squares)
      @squares.each do |coord, square|
        square_dup[coord] = square.dup
        if square.occupied?
          square_dup[coord].occupy_with square.occupant.dup
        end
      end
      duplicate
    end

    def previous_rank(rank_index, perspective)
      rank(
        case perspective
        when :white
          [rank_index.to_i - 1, 1].max
        when :black
          [rank_index.to_i + 1, 8].min
        end
      )
    end

    def next_rank(rank_index, perspective)
      rank(
        case perspective
        when :white
          [rank_index.to_i + 1, 8].min
        when :black
          [rank_index.to_i - 1, 1].max
        end
      )
    end

    def rank(index)
      ('a'..'h').to_a.collect { |file| @squares["#{file}#{index}"] }
    end

    def file(index)
      (1..8).to_a.collect { |rank| @squares["#{index}#{rank}"] }
    end

    def all_pieces
      @squares.values.collect(&:occupant).compact
    end

    def king(side)
      all_pieces.detect do |piece|
        Chess::Piece::King === piece && piece.side == side
      end
    end

    def to_ascii(options = {})
      data = (1..8).collect do |rank|
        ('a'..'h').collect do |file|
          square = @squares["#{file}#{rank}"]
          if options[:highlight] == square.to_s
            'X'
          else
            if square.occupied?
              square.to_fen
            else
              '.'
            end
          end
        end.join
      end
      data.reverse! unless options[:perspective] == :black
      data.join($/)
    end

    def to_fen
      (1..8).collect do |rank|
        ('a'..'h').inject('') do |rank_fen, file|
          square = @squares["#{file}#{rank}"]
          if square.occupied?
            rank_fen << square.to_fen
          else
            if rank_fen[-1].nil? || !(/\d/ =~ rank_fen[-1])
              rank_fen << '1'
            else
              rank_fen[-1] = rank_fen[-1].succ
            end
          end
          rank_fen
        end
      end.reverse.join('/')
    end
  end
end
