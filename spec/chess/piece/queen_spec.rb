require 'spec_helper'

describe Chess::Piece::Queen do
  describe '.move_list' do
    let(:game) { Chess::Game.from_fen(fen) }
    let(:move_list) { queen.move_list(game) }
    let(:destinations) { move_list.collect(&:destination).collect(&:to_s) }

    context 'when the queen stands alone' do
      let(:fen) { '8/8/8/8/4Q3/8/8/8 w - - 0 1' }
      let(:queen) { game.board['e4'].occupant }

      it 'should have 27 moves' do
        expect(queen).to be_a(Chess::Piece::Queen)
        expect(move_list.size).to eq(27)
      end
    end
  end
end

