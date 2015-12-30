require 'spec_helper'

describe Chess::Piece::Pawn do
  describe '.move_list' do
    let(:game_state_fen) { ' w - - 0 1' }
    let(:game) { Chess::Game.from_fen(fen + game_state_fen) }
    let(:move_list) { pawn.move_list(game) }
    let(:moves_as_classes) { move_list.collect(&:class) }
    let(:captures) { move_list.select(&:capture?) }
    let(:destinations) { move_list.collect(&:destination).collect(&:to_s) }

    context 'when the pawn stands alone' do
      let(:fen) { '8/8/8/8/4P3/8/8/8 w - - 0 1' }
      let(:pawn) { game.board['e4'].occupant }

      it 'should have 1 move' do
        expect(move_list.size).to eq(1)
      end
    end

    context 'for captures' do
      let(:pawn) { game.board['e4'].occupant }

      context 'with one target' do
        let(:fen) { '8/8/8/3p4/4P3/8/8/8' }

        it 'should have 2 moves' do
          expect(move_list.size).to eq(2)
          expect(captures.size).to eq(1)
          expect(destinations).to include('e5') # Straight forward
          expect(destinations).to include('d5') # Capture
        end
      end

      context 'with two targets' do
        let(:fen) { '8/8/8/3p1p2/4P3/8/8/8' }

        it 'should have 3 moves' do
          expect(move_list.size).to eq(3)
          expect(captures.size).to eq(2)
          expect(destinations).to include('e5') # Straight forward
          expect(destinations).to include('d5') # Capture
          expect(destinations).to include('f5') # Capture
        end
      end

      context 'straight onto obstacle' do
        context 'that is friendly' do
          let(:fen) { '8/8/8/8/4p3/4P3/8/8' }

          it 'should have 0 moves' do
            expect(move_list.size).to eq(0)
          end
        end

        context 'that is hostile' do
          let(:fen) { '8/8/8/8/4p3/4p3/8/8' }

          it 'should have 0 moves' do
            expect(move_list.size).to eq(0)
          end
        end
      end
    end

    context 'for promotions' do
      let(:fen) { '8/4P3/8/8/8/8/8/8' }
      let(:pawn) { game.board['e7'].occupant }
      let(:all_promotions) do
        move_list.all? { |move_obj| Chess::Move::Promotion === move_obj }
      end
      let(:promotion_targets) { move_list.collect(&:options).pluck(:new_rank) }

      it 'should allow promotions' do
        expect(move_list.size).to eq(4)
        expect(all_promotions).to eq(true)
        expect(promotion_targets).to include(Chess::Piece::Queen)
        expect(promotion_targets).to include(Chess::Piece::Knight)
        expect(promotion_targets).to include(Chess::Piece::Rook)
        expect(promotion_targets).to include(Chess::Piece::Bishop)
      end

      context 'via capture' do
        let(:fen) { '3q1r1/4P3/8/8/8/8/8/8' }
        let(:pawn) { game.board['e7'].occupant }

        it 'should be allowed' do
          expect(move_list.size).to eq(12)
          expect(captures.size).to eq(8)
          expect(all_promotions).to eq(true)
          expect(destinations).to include('e8') # Straight forward
          expect(destinations).to include('d8') # Capture
          expect(destinations).to include('f8') # Capture
        end
      end

      context 'when taken' do
        let(:destination) { game.board['e8'] }

        def take_move
          move = move_list.detect { |pro| pro.options[:new_rank] == Chess::Piece::Queen }
          game.move_taken move
        end

        it 'should work' do
          take_move
          expect(destination.occupant).to be_a(Chess::Piece::Queen)
          expect(destination.occupant.side).to eq(pawn.side)
        end
      end
    end

    context 'for double advance' do
      # Testing black side for funsies.
      let(:game_state_fen) { ' b - - 0 1' }
      let(:fen) { Chess::Board::Configuration::Standard.as_fen }
      let(:pawn) { game.board['e7'].occupant }

      it 'should have 2 moves' do
        expect(move_list.size).to eq(2)
        expect(moves_as_classes).to include(Chess::Move::Base)
        expect(moves_as_classes).to include(Chess::Move::DoubleAdvance)
      end

      def take_move
        game.move_taken pawn.move_list(game).detect_by_class(Chess::Move::DoubleAdvance)
      end

      it 'should provoke an en passant' do
        expect(game.en_passant_target).to be_nil
        take_move
        expect(game.en_passant_target).to be_a(Chess::Square)
        expect(game.en_passant_target.to_s).to eq('e6')
      end
    end

    context 'for en passant' do
      let(:fen) { '8/8/8/3pP3/8/8/8/8 w KQkq d6 0 1' }
      let(:game) { Chess::Game.from_fen(fen) }
      let(:pawn) { game.board['e5'].occupant }

      it 'should allow an en passant' do
        expect(move_list.size).to eq(2)
        expect(moves_as_classes).to include(Chess::Move::Base)
        expect(moves_as_classes).to include(Chess::Move::EnPassant)
      end

      context 'when taken' do
        let(:game_before) { game }
        let(:game_after) { game }
        let(:target_pawn_before) { game_before.board['d5'] }
        let(:target_pawn_after) { game_before.board['d5'] }
        let(:target_square_before) { game_after.board['d6'] }
        let(:target_square_after) { game_after.board['d6'] }

        def take_move
          game.move_taken pawn.move_list(game).detect_by_class(Chess::Move::EnPassant)
        end

        it 'should work' do
          expect(target_pawn_before.occupied?).to eq(true)
          expect(target_square_before.occupied?).to eq(false)
          take_move
          expect(target_pawn_after.occupied?).to eq(false)
          expect(target_square_after.occupied?).to eq(true)
          expect(target_square_after.occupant).to be_a(Chess::Piece::Pawn)
        end
      end
    end
  end
end
