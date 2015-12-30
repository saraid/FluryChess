require 'spec_helper'

describe Chess::Piece::Knight do
  describe '.move_list' do
    let(:game_state_fen) { ' w - - 0 1' }
    let(:game) { Chess::Game.from_fen(fen + game_state_fen) }
    let(:move_list) { knight.move_list(game) }

    context 'when the knight stands alone' do
      let(:fen) { '8/8/8/8/4N3/8/8/8 w - - 0 1' }
      let(:knight) { game.board['e4'].occupant }

      it 'should have 8 moves' do
        expect(move_list.size).to eq(8)
      end
    end

    context 'for openers' do
      let(:fen) { Chess::Board::Configuration::Standard.as_fen }
      let(:destinations) { move_list.collect(&:destination).collect(&:to_s) }

      context 'for white' do
        context 'on left' do
          let(:knight) { game.board['b1'].occupant }

          it 'should have 2 moves' do
            expect(move_list.size).to eq(2)
            expect(destinations).to include('a3')
            expect(destinations).to include('c3')
          end
        end

        context 'on right' do
          let(:knight) { game.board['g1'].occupant }

          it 'should have 2 moves' do
            expect(move_list.size).to eq(2)
            expect(destinations).to include('f3')
            expect(destinations).to include('h3')
          end
        end
      end

      context 'for black' do
        let(:game_state_fen) { ' b - - 0 1' }

        context 'on left' do
          let(:knight) { game.board['b8'].occupant }

          it 'should have 2 moves' do
            expect(move_list.size).to eq(2)
            expect(destinations).to include('a6')
            expect(destinations).to include('c6')
          end
        end

        context 'on right' do
          let(:knight) { game.board['g8'].occupant }

          it 'should have 2 moves' do
            expect(move_list.size).to eq(2)
            expect(destinations).to include('f6')
            expect(destinations).to include('h6')
          end
        end
      end
    end
  end
end
