class Object
  def _getvar sym
    instance_variable_get sym
  end

  def _setvar sym, val
    instance_variable_set sym, val
  end
end

class Board
  def initialize(configure = BoardConfiguration::Standard)
    @square = {}
    ('a'..'h').each_with_index do |file, col|
      8.times do |rank|
        @square[file+rank.succ.to_s] = Square.new(rank.succ, col.succ)
      end
    end

    configure.onto(self)
  end

  def [](coord)
    @square[coord]
  end

  def square(rank, file)
    return nil unless (1..8).member?(rank) && (1..8).member?(file)
    @square["#{('a'..'h').to_a[file-1]}#{rank}"]
  end

  def rank index
    ('a'..'h').collect { |file| @square["#{file}#{index}"] }
  end

  def file index
    (1..8).collect { |rank| @square["#{index}#{rank}"] }
  end
end

module BoardConfiguration
  class Standard
    def self.onto(board)
      King.new('white').place_on(board, 'e1')
      Queen.new('white').place_on(board, 'd1')
      ['c', 'f'].each { |file| Bishop.new('white').place_on(board, "#{file}1") }
      ['b', 'g'].each { |file| Knight.new('white').place_on(board, "#{file}1") }
      ['a', 'h'].each { |file| Rook.new('white').place_on(board, "#{file}1") }
      ('a'..'h').each { |file| Pawn.new('white').place_on(board, "#{file}2") }

      King.new('black').place_on(board, 'e8')
      Queen.new('black').place_on(board, 'd8')
      ['c', 'f'].each { |file| Bishop.new('black').place_on(board, "#{file}8") }
      ['b', 'g'].each { |file| Knight.new('black').place_on(board, "#{file}8") }
      ['a', 'h'].each { |file| Rook.new('black').place_on(board, "#{file}8") }
      ('a'..'h').each { |file| Pawn.new('black').place_on(board, "#{file}7") }
    end
  end

  class TestEnPassant
    def self.onto(board)
      Pawn.new('white').place_on(board, "e5")
      Pawn.new('black').place_on(board, "f7")
    end
  end
end

class Square
  def initialize rank, file
    @rank = rank
    @file = file
    @square_color = ((rank + file) % 2 == 0) ? 'black' : 'white'
  end

  def occupy_with piece
    @piece = piece
  end

  def occupied?
    !@piece.nil?
  end

  def occupied_by? side
    return false unless @piece
    @piece.side == side
  end

  def occupant
    @piece
  end

  def method_missing id, *args, &block
    if Piece.instance_methods.include? id
      return @piece.send(id, *args, &block)
    end
    super
  end

  # Necessary?
  def to_array_indices
    { :row => 8 - @rank, :col => @file - 1 }
  end

  def to_hash
    { :rank => @rank, :file => @file }
  end
end

class Piece
  def initialize(side)
    @side = side
  end

  def name
    self.class.to_s
  end

  def side
    @side
  end

  def place_on(board, at)
    @board = board
    @square = at.respond_to?(:occupy_with) ? at : @board[at]
    @square.occupy_with(self)
  end

  def can_move_to? square
    square = square.respond_to?(:occupy_with) ? square : @board[square]
    generate_move_list unless @move_list
    @move_list.include? square
  end

  def to_s
    @side.capitalize + ' ' + name
  end

  def move_to! square
    square = square.respond_to?(:occupy_with) ? square : @board[square]
    raise "Can't move there" unless self.can_move_to? square
    self.place_on(@board, square)
  end

  def generate_move_list
    @move_list = []
  end

  def invalidate_move_list!
    @move_list = nil
  end

  def promote_to!; raise "This piece cannot be promoted."; end
end

class King < Piece; end
class Queen < Piece; end
class Bishop < Piece; end
class Knight < Piece
  def generate_move_list
    cur_pos = @square.to_hash
    @move_list = []

    [{ :rank =>  2, :file =>  1},
     { :rank =>  2, :file => -1},
     { :rank => -2, :file =>  1},
     { :rank => -2, :file => -1},
     { :rank =>  1, :file =>  2},
     { :rank =>  1, :file => -2},
     { :rank => -1, :file =>  2},
     { :rank => -1, :file => -2}].each do |adjustment|
      move = @board.square(cur_pos[:rank] + adjustment[:rank], cur_pos[:file] + adjustment[:file])
      unless move && move.occupied? && move.occupied_by?(@side == 'white' ? 'white' : 'black')
        @move_list.push move
      end
    end

    @move_list.compact!
  end
end
class Rook < Piece; end
class Pawn < Piece
  @@promotable_to = [Queen, Bishop, Knight, Rook]

  def initialize(side)
    @has_moved = false
    @passable = false
    super
  end

  def move_to! square
    square = square.respond_to?(:occupy_with) ? square : @board[square]
    @has_moved = true
    if square.to_hash[:rank] - @square.to_hash[:rank] == 2
      @passable = true
      # TODO: Enqueue a game event to set this to false.
    end
    super
  end

  def passable?
    @passable
  end

  def generate_move_list
    direction = @side == 'white' ? 1 : -1
    cur_pos = @square.to_hash
    @move_list = []

    # Normal
    move = @board.square(cur_pos[:rank] + (direction * 1), cur_pos[:file])
    @move_list.push move unless move && move.occupied?

    # Double advance
    unless @has_moved
      move = @board.square(cur_pos[:rank] + (direction * 2), cur_pos[:file])
      @move_list.push move unless move && move.occupied?
    end

    # Capture
    [{ :rank => 1, :file => -1},
     { :rank => 1, :file =>  1}].each do |adjustment|
      move = @board.square(cur_pos[:rank] + (direction * adjustment[:rank]),
                           cur_pos[:file] + adjustment[:file])
      @move_list.push move if move && move.occupied_by?(@side == 'white' ? 'black' : 'white')
    end

    # En passant
    [{ :rank => 0, :file => -1},
     { :rank => 0, :file =>  1}].each do |adjustment|
      move = @board.square(cur_pos[:rank] + (direction * adjustment[:rank]),
                           cur_pos[:file] + adjustment[:file])
      @move_list.push move if move && move.occupied_by?(@side == 'white' ? 'black' : 'white') \
                                   && move.occupant.passable?
    end
    
    @move_list.compact!
  end

  def promote_to! to
    promotion_class = @@promotable_to.detect { |piece| piece.to_s == to.capitalize }
    raise "Cannot promote to #{to}" unless promotion_class
    promotion_class.new(@side).place_on(@board, @square)

    @promoted = true
  end
end
