module Chess
  class History
    def initialize(starting_state, moves = [])
      @history = []

      @history << HistoryEvent.new(nil, starting_state)
      moves.each do |movetext|
        move = Chess::Move.from_san(current_state, movetext)
        @history << HistoryEvent.new(move, move.take)
      end
    end

    def current_state
      @history.last.state
    end

    def last_move
      @history.last.move
    end

    def record(move)
      @history << HistoryEvent.new(move, move.take)
      @checkmated = true if move.checkmate?
    end

    class HistoryEvent
      rattr_initialize :move, :state
    end

    def over?
      checkmated? || draw?
    end

    def draw?
      false # TODO
    end

    def checkmated?
      !!@checkmated
    end

    def to_pgn
      moves = []
      @history[1..-1].each_slice(2) do |white, black|
        round = [
          "#{white.state.full_move_number}.",
          white.move.to_san ]
        round << black.move.to_san unless black.nil?
        moves << round.join(' ')
      end
      moves.join(' ')
    end
  end
end
