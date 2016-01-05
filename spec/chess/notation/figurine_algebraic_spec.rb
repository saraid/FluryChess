require 'spec_helper'

describe Chess::Notation::StandardAlgebraic do
  describe '.matcher' do
    let(:regex) { Chess::Notation::StandardAlgebraic.matcher }

    it 'should reject non-moves' do
      expect('e4lol').not_to match(regex)
    end

    it 'should understand a castling' do
      expect('O-O').to match(regex)
      expect('O-O-O').to match(regex)
    end

    it 'should understand a pawn move' do
      expect('e4').to match(regex)
    end

    it 'should understand a pawn promotion' do
      expect('e8=Q').to match(regex)
      expect('e8=N').to match(regex)
    end

    it 'should understand a disambiguated pawn promotion' do
      expect('7e8=Q').to match(regex)
      expect('8e8=N').to match(regex)
    end

    it 'should understand a standard capture' do
      expect('1xe5').to match(regex)
      expect('Nxe5').to match(regex)
    end

    it 'should understand a disambiguated move' do
      expect('N4xe5').to match(regex)
      expect('Ndxe5').to match(regex)
      expect('Nc4xe5').to match(regex)
    end

    it 'should understand a move that results in check' do
      expect('e5+').to match(regex)
      expect('e8=Q+').to match(regex)
      expect('1xe5+').to match(regex)
      expect('Nxe5+').to match(regex)
      expect('Ndxe5+').to match(regex)
      expect('Nc4xe5+').to match(regex)
    end

    it 'should understand a move that results in checkmate' do
      expect('e5#').to match(regex)
      expect('e8=Q#').to match(regex)
      expect('1xe5#').to match(regex)
      expect('Nxe5#').to match(regex)
      expect('Ndxe5#').to match(regex)
      expect('Nc4xe5#').to match(regex)
    end
  end

  context '.from_san' do
    context 'promotion' do
      let(:game_state_fen) { " #{side == :white ? 'w' : 'b'} - - 0 1" }
      let(:game) { Chess::Game.from_fen(fen + game_state_fen) }
      let(:move) { Chess::Move.from_san(game, movetext) }

      context 'that is valid' do
        # Black about to promote
        let(:fen) { '8/8/8/8/8/8/5p2/8' }
        let(:side) { :black }
        let(:movetext) { 'f1=Q' }

        it 'should create a move' do
          expect(move).to be_a(Chess::Move::Promotion)
          expect(move.options[:origin].occupant).to be_a(Chess::Piece::Pawn)
          expect(move.options[:origin].file).to eq('f')
          expect(move.options[:new_rank]).to eq(Chess::Piece::Queen)
        end
      end

      context 'where there are no pawns' do
        let(:fen) { '8/8/8/8/8/8/8/8' }
        let(:side) { :black }
        let(:movetext) { 'e8=Q' }

        it 'should raise an error' do
          expect { move }.to raise_error(Chess::Move::CouldNotFindPiece)
        end
      end

      context 'that is ambiguous' do
        let(:fen) { '8/8/8/8/8/8/5p1p/6R1' }
        let(:side) { :black }

        context 'ambiguous movetext' do
          let(:movetext) { 'f1=Q' }

          it 'should raise an error' do
            expect { move }.to raise_error(Chess::Move::AmbiguousPieceToMove)
          end
        end

        context 'disambiguated movetext' do
          let(:movetext) { 'ff1=Q' }

          it 'should create a move using correct candidate' do
            expect(move).to be_a(Chess::Move::Promotion)
            expect(move.options[:origin].occupant).to be_a(Chess::Piece::Pawn)
            expect(move.options[:origin].file).to eq('f')
            expect(move.options[:new_rank]).to eq(Chess::Piece::Queen)
          end
        end
      end
    end

    context 'basic move' do
      let(:game) { Chess::Game.new }
      let(:move) { Chess::Move.from_san(game, movetext) }
      let(:side) { :white }

      context 'standard opener' do
        let(:movetext) { 'e4' }

        it 'should be a double advance' do
          expect(move).to be_a(Chess::Move::DoubleAdvance)
        end
      end
    end
  end
end
