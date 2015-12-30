require 'spec_helper'

describe Chess::Piece::King do
  describe '.move_list' do
    let(:game) { Chess::Game.from_fen(fen) }

    context 'when the king stands alone' do
      let(:fen) { '8/8/8/8/4K3/8/8/8 w - - 0 1' }
      let(:king) { game.board['e4'].occupant }

      it 'should have 8 moves' do
        expect(king).to be_a(Chess::Piece::King)
        expect(king.move_list(game).size).to eq(8)
      end
    end

    context 'when the king is blocked by a piece' do
      let(:king) { game.board['e4'].occupant }
      let(:move_list) { king.move_list(game) }

      context 'that is friendly' do
        let(:fen) { '8/8/8/8/4KQ2/8/8/8 w - - 0 1' }
        let(:obstacle) { game.board['f4'] }

        it 'should have 7 moves' do
          expect(king).to be_a(Chess::Piece::King)
          expect(move_list.size).to eq(7)
        end

        it 'should not be able to collide' do
          invalid = move_list.find { |move| move.destination == obstacle }
          expect(invalid).to be_nil
        end
      end

      context 'that is hostile' do
        let(:fen) { '8/8/8/8/4Kn2/8/8/8 w - - 0 1' }

        it 'should have 6 moves' do
          expect(king).to be_a(Chess::Piece::King)
          expect(move_list.size).to eq(6)
        end
      end
    end

    context 'when we fake castling availability' do
      let(:fen) { '8/8/8/8/8/8/8/R3K2R w KQ - 0 1' }
      let(:king) { game.board['e1'].occupant }
      let(:move_list) { king.move_list(game) }
      let(:castling_moves) { move_list.select_by_class(Chess::Move::Castle) }

      it 'should have 7 moves' do
        expect(king).to be_a(Chess::Piece::King)
        expect(move_list.size).to eq(7)
        expect(castling_moves.size).to eq(2)
      end
    end
  end

  def can_castle?
    [ game.can_castle?(side: color, type: :kingside),
      game.can_castle?(side: color, type: :queenside)
    ].any?
  end

  context 'when castling is blocked' do
    let(:game) { Chess::Game.from_fen(fen) }
    let(:color) { :white }
    let(:fen) { '8/8/8/8/8/8/8/R3KB1R w KQkq - 0 1' }
    let(:king) { game.board['e1'].occupant }
    let(:move_list) { king.move_list(game) }
    let(:castling_moves) { move_list.select_by_class(Chess::Move::Castle) }

    it 'should not be able to castle' do
      expect(castling_moves.size).to eq(1)
      expect(castling_moves.first.destination.to_s).to eq('b1')
    end
  end

  context 'loses castling availability if it moves' do
    let(:game) { Chess::Game.from_fen(fen) }
    let(:can_castle_before) { can_castle? }
    let(:can_castle_after) { can_castle? }

    def take_move
      game.move_taken king.move_list(game).detect_by_class(Chess::Move::Base)
    end

    context 'when white' do
      let(:fen) { '8/8/8/8/8/8/8/R3K2R w KQkq - 0 1' }
      let(:color) { :white }
      let(:king) { game.board['e1'].occupant }

      it 'should deny castling' do
        expect(can_castle_before).to eq(true)
        take_move
        expect(can_castle_after).to eq(false)
      end
    end

    context 'when black' do
      let(:fen) { 'r3k2r/8/8/8/8/8/8/8 b KQkq - 0 1' }
      let(:color) { :black }
      let(:king) { game.board['e8'].occupant }

      it 'should deny castling' do
        expect(can_castle_before).to eq(true)
        take_move
        expect(can_castle_after).to eq(false)
      end
    end
  end

  context 'when castling' do
    let(:game) { Chess::Game.from_fen(fen) }

    def king
      game.board.king(color)
    end

    def take_move
      castling = king.move_list(game).detect do |move|
        Chess::Move::Castle === move && move.options[:type] == type
      end
      game.move_taken castling
    end

    before(:each) do
      take_move
    end

    context 'white queenside' do
      let(:fen) { '8/8/8/8/8/8/8/R3K2R w KQkq - 0 1' }
      let(:color) { :white }
      let(:type) { :queenside }

      it 'should work' do
        expect(king.position.to_s).to eq('b1')
        expect(game.board.to_fen).to eq('8/8/8/8/8/8/8/1KR4R')
      end
    end

    context 'white kingside' do
      let(:fen) { '8/8/8/8/8/8/8/R3K2R w KQkq - 0 1' }
      let(:color) { :white }
      let(:type) { :kingside }

      it 'should work' do
        expect(king.position.to_s).to eq('g1')
        expect(game.board.to_fen).to eq('8/8/8/8/8/8/8/R4RK1')
      end
    end

    context 'black queenside' do
      let(:fen) { 'r3k2r/8/8/8/8/8/8/8 b KQkq - 0 1' }
      let(:color) { :black }
      let(:type) { :queenside }

      it 'should work' do
        expect(king.position.to_s).to eq('b8')
        expect(game.board.to_fen).to eq('1kr4r/8/8/8/8/8/8/8')
      end
    end

    context 'black kingside' do
      let(:fen) { 'r3k2r/8/8/8/8/8/8/8 b KQkq - 0 1' }
      let(:color) { :black }
      let(:type) { :kingside }

      it 'should work' do
        expect(king.position.to_s).to eq('g8')
        expect(game.board.to_fen).to eq('r4rk1/8/8/8/8/8/8/8')
      end
    end
  end
end
