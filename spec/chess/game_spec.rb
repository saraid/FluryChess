require 'spec_helper'

describe Chess::Game do
  describe '.from_pgn' do
    let(:pgn) { '[Foo "Bar"]' }
    let(:game) { Chess::Game.from_pgn(pgn) }

    it 'should read metadata correctly' do
      expect(game.metadata[:foo]).to eq('Bar')
    end

    describe 'Fischer–Myagmarsüren 1967' do
      pgn(:fischer1967)
      let(:final_fen) { '2r2qk1/r4p1Q/b3pBp1/n3P2P/p2p3R/P5P1/2p2PB1/R5K1 b - - 0 31' }

      it 'should play out' do
        expect(game.to_fen).to eq(final_fen)
      end
    end

    describe 'Fischer–Spassky 1992' do
      pgn(:fischer1992)
      let(:final_fen) { '8/8/4R1p1/2k3p1/1p4P1/1P1b1P2/3K1n2/8 b - - 2 43' }

      it 'should play out' do
        expect(game.to_fen).to eq(final_fen)
      end
    end
  end

  describe 'sample games' do
    let(:game) { Chess::Game.new }
    let(:play) { game.method(:play) }

    describe %(fool's mate) do
      it 'should play out quickly' do
        game.play 'f3'
        game.play 'e5'
        game.play 'g4'
        move = Chess::Move.from_san(game, 'Qh4')
        expect(move.checks_enemy_side?).to eq(true)
        expect(move.checkmate?).to eq(true)
        game.play 'Qh4'
        expect(game.over?).to eq(true)
      end
    end

    describe %(example of en passant) do
      let(:moves) do
        %w(e4 e5
           Nf3 Nf6
           d4 exd4
           e5 Ne4
           Qxd4 d5
           exd6
          )
      end

      it 'should play out successfully' do
        moves.each(&play)
      end
    end

    describe %(example of a castling) do
      let(:moves) do
        %w( e4 e6
            d3 d5
            Nd2 Nf6
            g3 c5
            Bg2 Nc6
            Ngf3 Be7
            0-0 0-0
          )
      end

      it 'should play out successfully' do
        moves.each(&play)
      end
    end
  end
end
