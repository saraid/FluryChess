require 'attr_extras'

module Chess
  class Square
    vattr_initialize :rank, :file
    attr_reader :occupant

    def occupied?
      !!@occupant
    end

    def occupy_with(piece)
      @occupant = piece
    end

    def to_s
      "#{file}#{rank}"
    end

    def to_fen
      @occupant.to_fen if @occupant.respond_to? :to_fen
    end
  end
end
