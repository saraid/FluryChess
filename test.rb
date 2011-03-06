require 'test/unit'
load 'board.rb'

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
