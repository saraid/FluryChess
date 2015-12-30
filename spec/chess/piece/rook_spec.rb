require 'spec_helper'

describe Chess::Piece::Rook do
  describe '.move_list' do
    let(:game) { Chess::Game.from_fen(fen) }
    let(:move_list) { rook.move_list(game) }
    let(:captures) { move_list.select(&:capture?) }
    let(:destinations) { move_list.collect(&:destination).collect(&:to_s) }

    context 'when the rook stands alone' do
      let(:fen) { '8/8/8/8/4R3/8/8/8 w - - 0 1' }
      let(:rook) { game.board['e4'].occupant }

      it 'should have 14 moves' do
        expect(rook).to be_a(Chess::Piece::Rook)
        expect(move_list.size).to eq(14)
      end
    end

    context 'when the rook is blocked by a friendly piece' do
      let(:fen) { '8/8/8/8/4R3/8/8/4R3 w - - 0 1' }
      let(:rook) { game.board['e4'].occupant }

      it 'should have 13 moves' do
        expect(rook).to be_a(Chess::Piece::Rook)
        expect(move_list.size).to eq(13)
        expect(captures.size).to eq(0)
      end
    end

    context 'when the rook is blocked by a hostile piece' do
      let(:fen) { '8/8/8/8/4R3/8/8/4r3 w - - 0 1' }
      let(:rook) { game.board['e4'].occupant }

      it 'should have 14 moves' do
        expect(rook).to be_a(Chess::Piece::Rook)
        expect(move_list.size).to eq(14)
        expect(captures.size).to eq(1)
      end
    end
  end
end

