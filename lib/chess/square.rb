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

    def to_unicode
      if @occupant.respond_to? :to_unicode
        @occupant.to_unicode
      else
        '▢'
      end
    end

    def method_missing(id, *args, &block)
      @occupant.send(id, *args, &block) if @occupant.respond_to? id
    end
  end
end
