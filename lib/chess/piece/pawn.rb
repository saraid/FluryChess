module Chess
  module Piece
    class Pawn < Base
      def move_list(game, check_validity = true)
        super do
          moves = []
          board = game.board
          options = { origin: position }

          promotion = lambda do |destination|
            [ Chess::Piece::Queen,
              Chess::Piece::Knight,
              Chess::Piece::Rook,
              Chess::Piece::Bishop
            ].collect do |piece_klass|
              Chess::Move::Promotion.new(game,
                                         options.merge(
                                           destination: destination,
                                           new_rank: piece_klass
                                        ))
              end
          end

          # Straight Forward
          case position.rank
          when starting_rank
            moves << Chess::Move::Base.new(game,
              options.merge(destination: board["#{position.file}#{next_rank}"]))
            moves << Chess::Move::DoubleAdvance.new(game,
              options.merge(
                destination: board["#{position.file}#{next_rank(2)}"],
                en_passant_target: board["#{position.file}#{next_rank}"]
            ))
          when middle_ranks
            moves << Chess::Move::Base.new(game,
              options.merge(destination: board["#{position.file}#{next_rank}"]))
          when promotion_rank
            moves.concat(promotion.call(board["#{position.file}#{next_rank}"]))
          end

          moves.reject! { |move| move.destination.occupied? }

          # Captures
          file_indices = ('a'..'h').to_a
          captures = [
            file_indices.index(position.file) - 1,
            file_indices.index(position.file) + 1
          ].
            select { |index| (1..8).include? index.succ }.
            collect { |index| file_indices[index] }.
            collect { |file| board["#{file}#{next_rank}"] }.
            select do |square|
              [ square.occupied? && square.occupant.side != side,
                game.en_passant_target == square
              ].any?
            end.
            collect do |square|
              if game.en_passant_target == square
                Chess::Move::EnPassant.new(game, options.merge(destination: square))
              else
                case position.rank
                when middle_ranks
                  Chess::Move::Base.new(game, options.merge(destination: square))
                when promotion_rank
                  promotion.call(square)
                end
              end
            end.
            flatten.
            compact

          moves.concat(captures)
        end
      end

      private
      def starting_rank
        case side
        when :white then 2
        when :black then 7
        end
      end

      def promotion_rank
        case side
        when :white then 7
        when :black then 2
        end
      end

      def middle_ranks
        case side
        when :white then starting_rank...promotion_rank
        when :black then (promotion_rank.succ)..starting_rank
        end
      end

      def next_rank(amt = 1)
        case side
        when :white then position.rank + amt
        when :black then position.rank - amt
        end
      end
    end
  end
end
