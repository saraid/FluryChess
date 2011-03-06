require 'test/unit'
load 'board.rb'

module BoardConfiguration
  class TestDoubleAdvance
    def self.onto(board)
      Pawn.new('white').place_on(board, "e2")
      Pawn.new('white').place_on(board, "f2")
      Pawn.new('black').place_on(board, "e3")
    end
  end

  class TestEnPassant
    def self.onto(board)
      a = Pawn.new('white').place_on(board, "e5")
      a.has_moved!
      Pawn.new('black').place_on(board, "f7")
    end
  end

  class TestRookMovement
    def self.onto(board)
      Rook.new('white').place_on(board, 'e5')
      Pawn.new('black').place_on(board, 'e7')
      Pawn.new('white').place_on(board, 'h5')
    end
  end

  class TestBishopMovement
    def self.onto(board)
      Bishop.new('white').place_on(board, 'e5')
      Pawn.new('black').place_on(board, 'g7')
      Pawn.new('white').place_on(board, 'a1')
    end
  end

  class TestQueenMovement
    def self.onto(board)
      Queen.new('white').place_on(board, 'e5')
      Pawn.new('black').place_on(board, 'e7')
      Pawn.new('white').place_on(board, 'h5')
      Pawn.new('black').place_on(board, 'g7')
      Pawn.new('white').place_on(board, 'a1')
    end
  end

  class TestKingMovement
    def self.onto(board)
      King.new('white').place_on(board, 'e5')
    end
  end

  class TestCheckByPawn
    def self.onto(board)
      King.new('white').place_on(board, 'e5')
      Pawn.new('black').place_on(board, 'f6')
    end
  end

  class TestCheckByKnight
    def self.onto(board)
      King.new('white').place_on(board, 'e5')
      knight_pos = ['d3', 'f3', 'c4', 'g4', 'c6', 'g6', 'd7', 'f7']
      Knight.new('black').place_on(board, knight_pos[rand(8)])
    end
  end

  class TestCheckByBishop
    def self.onto(board)
      King.new('white').place_on(board, 'e5')
      bishop_pos = ['e7', 'h5', 'g7', 'a1']
      Bishop.new('black').place_on(board, bishop_pos[rand(4)])
    end
  end

  class TestCheckByRook
    def self.onto(board)
      King.new('white').place_on(board, 'e5')
      rook_pos = ['e1', 'b5', 'e7', 'f5']
      Rook.new('black').place_on(board, rook_pos[rand(4)])
    end
  end
end

class PawnMovements < Test::Unit::TestCase
  def test_step
    board = Board.new
    board['e2'].move_to! 'e3'
  end

  def test_double_advance
    board = Board.new(BoardConfiguration::TestDoubleAdvance)
    assert_raise(RuntimeError) { board['e2'].move_to! 'e4' }
    board['f2'].move_to! 'f4'
  end

  def test_en_passant
    board = Board.new(BoardConfiguration::TestEnPassant)
    board['f7'].move_to! 'f5'
    board['e5'].move_to! 'f6'
  end
end

class KnightMovements < Test::Unit::TestCase
  def test_openers
    board = Board.new
    board['b1'].move_to! 'a3'
    board['g1'].move_to! 'h3'
    board['b8'].move_to! 'a6'
    board['g8'].move_to! 'h6'
    board = Board.new
    board['b1'].move_to! 'c3'
    board['g1'].move_to! 'f3'
    board['b8'].move_to! 'c6'
    board['g8'].move_to! 'f6'
    board = Board.new
    assert_raise(RuntimeError) { board['b1'].move_to! 'b2' }
    assert_raise(RuntimeError) { board['b1'].move_to! 'd2' }
  end
end

class RookMovements < Test::Unit::TestCase
  def test_vector_movement
    board = Board.new(BoardConfiguration::TestRookMovement)
    board['e5'].move_to! 'e1'
    board = Board.new(BoardConfiguration::TestRookMovement)
    board['e5'].move_to! 'a5'
    board = Board.new(BoardConfiguration::TestRookMovement)
    board['e5'].move_to! 'e7'
    board = Board.new(BoardConfiguration::TestRookMovement)
    assert_raise(RuntimeError) { board['e5'].move_to! 'e8' }
    board = Board.new(BoardConfiguration::TestRookMovement)
    assert_raise(RuntimeError) { board['e5'].move_to! 'h5' }
  end
end

class BishopMovements < Test::Unit::TestCase
  def test_vector_movement
    board = Board.new(BoardConfiguration::TestBishopMovement)
    board['e5'].move_to! 'b8'
    board = Board.new(BoardConfiguration::TestBishopMovement)
    board['e5'].move_to! 'g7'
    board = Board.new(BoardConfiguration::TestBishopMovement)
    board['e5'].move_to! 'h2'
    board = Board.new(BoardConfiguration::TestBishopMovement)
    assert_raise(RuntimeError) { board['e5'].move_to! 'h8' }
    board = Board.new(BoardConfiguration::TestBishopMovement)
    assert_raise(RuntimeError) { board['e5'].move_to! 'a1' }
  end
end

class QueenMovements < Test::Unit::TestCase
  def test_vector_movement
    board = Board.new(BoardConfiguration::TestQueenMovement)
    board['e5'].move_to! 'e1'
    board = Board.new(BoardConfiguration::TestQueenMovement)
    board['e5'].move_to! 'a5'
    board = Board.new(BoardConfiguration::TestQueenMovement)
    board['e5'].move_to! 'e7'
    board = Board.new(BoardConfiguration::TestQueenMovement)
    assert_raise(RuntimeError) { board['e5'].move_to! 'e8' }
    board = Board.new(BoardConfiguration::TestQueenMovement)
    assert_raise(RuntimeError) { board['e5'].move_to! 'h5' }
    board = Board.new(BoardConfiguration::TestQueenMovement)
    board['e5'].move_to! 'b8'
    board = Board.new(BoardConfiguration::TestQueenMovement)
    board['e5'].move_to! 'g7'
    board = Board.new(BoardConfiguration::TestQueenMovement)
    board['e5'].move_to! 'h2'
    board = Board.new(BoardConfiguration::TestQueenMovement)
    assert_raise(RuntimeError) { board['e5'].move_to! 'h8' }
    board = Board.new(BoardConfiguration::TestQueenMovement)
    assert_raise(RuntimeError) { board['e5'].move_to! 'a1' }
  end
end

class KingMovements < Test::Unit::TestCase
  def test_step
    board = Board.new(BoardConfiguration::TestKingMovement)
    board['e5'].move_to! 'e6'
    board = Board.new(BoardConfiguration::TestKingMovement)
    board['e5'].move_to! 'f6'
  end

  def test_in_check
    board = Board.new(BoardConfiguration::TestCheckByPawn)
    assert(board['e5'].occupant.in_check?, "Pawn isn't checking correctly")
    board = Board.new(BoardConfiguration::TestCheckByKnight)
    assert(board['e5'].occupant.in_check?, "Knight isn't checking correctly")
    board = Board.new(BoardConfiguration::TestCheckByRook)
    assert(board['e5'].occupant.in_check?, "Rook isn't checking correctly")
    board = Board.new(BoardConfiguration::TestCheckByBishop)
    assert(board['e5'].occupant.in_check?, "Bishop isn't checking correctly")
  end
end
