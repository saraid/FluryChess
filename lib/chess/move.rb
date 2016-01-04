require_relative 'notation'

require_relative 'move/base'
require_relative 'move/castle'
require_relative 'move/double_advance'
require_relative 'move/en_passant'
require_relative 'move/promotion'

module Chess
  # A move is a transform between two board states.
  module Move
    class ImpossibleMoveForBoardState < Chess::Error; end
    class AmbiguousPieceToMove < Chess::Error; end
    class CouldNotFindPiece < Chess::Error; end

    extend Chess::Notation::StandardAlgebraic::MoveParser

    # Not implemented yet
    #extend Chess::Notation::LongAlgebraic::MoveParser
    #extend Chess::Notation::ReversibleAlgebraic::MoveParser
    #extend Chess::Notation::ConciseReversibleAlgebraic::MoveParser
    #extend Chess::Notation::Smith::MoveParser
    #extend Chess::Notation::ICCFNumeric::MoveParser
    #extend Chess::Notation::Coordinate::MoveParser
  end
end
