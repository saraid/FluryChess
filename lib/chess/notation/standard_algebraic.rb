module Chess
  module Notation
    class StandardAlgebraic
      def self.regexes(regex_keys = false)
        castle_char = '[O0]'
        castling = "(?<castle>#{castle_char}-#{castle_char}(?:-#{castle_char})?)"
        promotion = '=(?<new_rank>[QRNB])'
        any_piece = '(?<piece_moved>[KQRNB]?)'
        is_capture = 'x?'
        is_check = '[+#]?'
        disambiguation = '(?<disambiguation_file>[a-h])?(?<disambiguation_rank>[1-8])?'
        destination = '(?<file>[a-h])(?<rank>[1-8])'

        wrap_key =
          if regex_keys
            lambda { |key| Regexp.new key }
          else
            lambda { |key| key }
          end

        {
          wrap_key.call([castling, is_check].join) => Chess::Move::Castle,
          wrap_key.call([disambiguation, destination, promotion, is_check].join) => Chess::Move::Promotion,
          wrap_key.call([any_piece, disambiguation, is_capture, destination, is_check].join) => Chess::Move::Base
        }
      end

      def self.matcher
        wrap_in_non_matching_group = lambda { |regex| "(?:#{regex})" }
        /^\s*#{regexes.keys.collect(&wrap_in_non_matching_group).join('|')}\s*$/
      end

      PIECE_MAPPING = {
        Chess::Piece::King   => 'K',
        Chess::Piece::Queen  => 'Q',
        Chess::Piece::Rook   => 'R',
        Chess::Piece::Bishop => 'B',
        Chess::Piece::Knight => 'N',
        Chess::Piece::Pawn   => 'P'
      }

      module MoveParser
        def from_san(game, movetext)
          move = nil

          Chess::Notation::StandardAlgebraic.regexes(true).each do |regex, klass|
            next unless move.nil?
            next unless regex =~ movetext
            md = $~.dup

            case
            when klass == Chess::Move::Castle
              origin = game.board.king(game.active_color).position
              case md[:castle].gsub /[0]/, 'O'
              when 'O-O'
                move = klass.new(game, origin: origin, side: game.active_color, type: :kingside)
              when 'O-O-O'
                move = klass.new(game, origin: origin, side: game.active_color, type: :queenside)
              end
            when klass == Chess::Move::Promotion
              # Search previous rank for candidate pawns.
              candidate_pawns = game.board.
                previous_rank(md[:rank], game.active_color). #sigh
                select(&:occupied?).
                collect(&:occupant).
                select { |piece| Chess::Piece::Pawn === piece }
              pawn = candidate_pawns.first if candidate_pawns.length == 1

              # Disambiguate which pawn if there are two possibles.
              pawn ||=
                if candidate_pawns.length > 1
                  if md[:disambiguation_file].nil?
                    raise Chess::Move::AmbiguousPieceToMove
                  else
                    candidate_pawns.detect do |pawn|
                      pawn.position.file == md[:disambiguation_file]
                    end
                  end
                end
              raise Chess::Move::CouldNotFindPiece if pawn.nil?

              # Construct the Move object.
              new_rank = PIECE_MAPPING.invert[md[:new_rank]]
              move = pawn.move_list(game).detect do |move_obj|
                klass === move_obj && move_obj.options[:new_rank] == new_rank
              end
            when klass == Chess::Move::Base
              # Parse destination.
              destination = game.board["#{md[:file]}#{md[:rank]}"]

              # Determine piece class to narrow search parameters.
              piece_klass = PIECE_MAPPING.invert[md[:piece_moved]] || Chess::Piece::Pawn
              candidate_pieces = game.board.
                all_pieces.
                select { |piece| piece_klass === piece }.
                select { |piece| piece.side == game.active_color }

              # Determine which pieces could have moved there.
              candidate_pieces = candidate_pieces.
                # converts to Hash
                expand { |piece| piece.move_list(game) }.
                # destructive operation on the Hash
                keep_if do |piece, move_list|
                  move_list.detect { |move_obj| move_obj.destination == destination }
                end.
                # convert back to Array
                keys
              piece_to_move = candidate_pieces.first if candidate_pieces.length == 1

              # Disambiguate
              piece_to_move ||=
                if candidate_pieces.length > 1
                  if /[a-h]/ =~ md[:disambiguation_file]
                    candidate_pieces.select! do |piece|
                      piece.position.file == md[:disambiguation_file]
                    end
                  end
                  if /[1-8]/ =~ md[:disambiguation_rank]
                    candidate_pieces.select! do |piece|
                      piece.position.rank == md[:disambiguation_rank]
                    end
                  end

                  raise Chess::Move::AmbiguousPieceToMove if candidate_pieces.length > 1
                  candidate_pieces.first if candidate_pieces.length == 1
                end
              raise Chess::Move::CouldNotFindPiece if piece_to_move.nil?

              # Construct the Move object
              # • Disambiguate between any other possible basic moves.
              # • Every piece should only be able to move to any square in one way.
              move = piece_to_move.move_list(game).detect do |move_obj|
                move_obj.destination == destination
              end
            end
          end

          move
        end
      end

      module MoveSerializer
        def to_san
          if Chess::Move::Castle === self
            return case options[:type]
            when :kingside then 'O-O'
            when :queenside then 'O-O-O'
            end
          end
          is_pawn = Chess::Piece::Pawn === piece
          parts = []
          parts << PIECE_MAPPING[piece.class] unless is_pawn
          parts << destination.to_s

          disambiguation_phases = [ :only_file, :only_rank, :full_coord ]
          disambiguation_phase = 0
          disambiguation = []
          begin
            Chess::Move.from_san(game_state, parts.flatten.join)
          rescue Chess::Move::AmbiguousPieceToMove
            case disambiguation_phases[disambiguation_phase]
            when :only_file
              disambiguation = [ piece.position.file ]
              parts.insert 1, disambiguation
              disambiguation_phase = 0
              retry
            when :only_rank
              disambiguation = [ piece.position.rank ]
              parts[1] = disambiguation
              retry
            when :full_coord
              disambiguation = [ piece.position.file, piece.position.rank ]
              parts[1] = disambiguation
            end
          end
          parts.flatten!

          if capture?
            capture = []
            capture << piece.position.file if is_pawn && disambiguation.empty?
            capture << 'x'
            parts.insert(-2, capture)
            parts.flatten!
          end

          if checkmate?
            parts << '#'
          elsif checks_enemy_side?
            parts << '+'
          end

          parts.join
        end
      end
    end
  end
end
