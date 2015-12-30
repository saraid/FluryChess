require 'spec_helper'

describe Chess::Board do
  describe '.from_fen' do
    let(:board_fen) { Chess::Board::Configuration::Standard.as_fen }

    it 'should work' do
      expect(Chess::Board.from_fen(board_fen).to_fen).to eq(board_fen)
    end
  end

  describe '.dup' do
    let(:board) { Chess::Board.new }
    let(:board_dup) { board.dup }

    before(:each) do
      Chess::Piece::King.new(:white).place_on board, 'a1'
    end

    it 'should have different objects for squares' do
      expect(board['a1'].__id__).not_to eq(board_dup['a1'].__id__)
    end

    it 'should have different objects for pieces' do
      expect(board['a1'].occupant.__id__).not_to eq(board_dup['a1'].occupant.__id__)
    end
  end
end
