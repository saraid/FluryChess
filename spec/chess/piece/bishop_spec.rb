require 'spec_helper'

describe Chess::Piece::Bishop do
  describe '.move_list' do
    let(:game) { Chess::Game.from_fen(fen) }
    let(:move_list) { bishop.move_list(game) }
    let(:destinations) { move_list.collect(&:destination).collect(&:to_s) }

    context 'when the bishop stands alone' do
      let(:fen) { '8/8/8/8/4B3/8/8/8 w - - 0 1' }
      let(:bishop) { game.board['e4'].occupant }

      it 'should have 13 moves' do
        expect(bishop).to be_a(Chess::Piece::Bishop)
        expect(move_list.size).to eq(13)
      end
    end
  end
end
