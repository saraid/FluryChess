require 'json'

class Object
  def _getvar sym
    instance_variable_get sym
  end

  def _setvar sym, val
    instance_variable_set sym, val
  end
end

class Game
  def initialize
    @history = []
    @board = Board.new
    @sides = Side.list
    @turn = 0
  end

  attr_reader :board

  def move command
    src, dst = command.split('-')
    raise "No piece here..." unless @board[src].occupied?
    raise "Not your turn" unless @board[src].occupied_by? turn
    @history << @board[src].move_to!(dst)
    Side.list.each do |side| Side.find(side).pieces.each do |piece| piece.invalidate_move_list! end end
    @turn = @turn.succ
  end

  def turn
    @sides[@turn % 2]
  end

  def over?
    Side.find(turn).king.in_check? && Side.find(turn).pieces.none? { |piece| piece.can_move? }
  end

  def to_json
    @board.to_json
  end
end

class Side
  # FIXME: Side needs to stop using class variables. Seriously now.

  def self.register(side)
    @@sides = Hash.new unless defined? @@sides
    @@sides[side.name] = side
  end

  def self.find(name)
    @@sides = Hash.new unless defined? @@sides
    @@sides[name]
  end

  def self.create(*args)
    args.each { |name| Side.new(name) }
  end

  def self.list
    @@sides.keys
  end

  def initialize(name)
    @name = name
    @pieces = []
    Side.register(self)
  end

  attr_accessor :king, :queenside_rook, :kingside_rook

  def queenside_rook=(val)
    return if @queenside_rook
    @queenside_rook = val
  end

  def kingside_rook=(val)
    return if @kingside_rook
    @kingside_rook = val
  end

  attr_reader :name, :pieces

  def <<(piece)
    @pieces << piece unless @pieces.include? piece
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

  def to_json
    @square.to_json
  end
end

module BoardConfiguration
  class Standard
    def self.onto(board)
      Side.create('white', 'black')

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
end

class Square
  def initialize rank, file
    @rank = rank
    @file = file
    @square_color = ((rank + file) % 2 == 0) ? 'black' : 'white'
  end

  attr_reader :rank, :file

  def notation
    "#{('a'..'h').to_a[@file-1]}#{@rank}"
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

  def remove!
    piece = @piece
    @piece = nil
    return piece
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

  def to_json json, level
    occupied?() ? @piece.to_s : 'Empty'
  end
end

class Move
  class InvalidDestination < Exception; end

  def initialize(piece, destination)
    @piece = piece
    @original_position = @piece.location
    @destination = destination
    raise InvalidDestination if @destination.nil?
    @original_piece = @destination.occupant
  end

  attr_accessor :destination

  def must_capture!
    @must_capture = true
  end

  def cannot_capture!
    @cannot_capture = true
  end

  def possible?
    return false if @destination.nil?
    return false if @cannot_capture && @destination.occupied?
    return false if @destination.occupied_by?(@piece.side == 'white' ? 'white' : 'black')
    return false if @must_capture && (!@destination.occupied? \
                 || @destination.occupied_by?(@piece.side == 'white' ? 'white' : 'black'))
    return false if causes_check?
    return true
  end

  def causes_check?
    king = Side.find(@piece.side).king
    return false if king.nil?
    do!
    causes_check = king.in_check?
    reverse!
    return causes_check
  end

  def notation
    return @notation if @notation
    @notation = ''
    @notation << @piece.abbr
    @notation << @piece.location.notation
    @notation << 'x' if @destination.occupied?
    @notation << @destination.notation
  end

  def do!
    @piece.place_on @destination
    @piece.has_moved! if @piece.respond_to? :has_moved!
    @original_piece.remove! if @original_piece
  end

  def reverse!
    @piece.has_moved!(false) if @piece.respond_to? :has_moved!
    @piece.place_on @original_position
    @original_piece.place_on @destination if @original_piece
  end
end

class DoubleAdvance < Move
  def initialize(piece, destination, skipped)
    @skipped = skipped
    super(piece, destination)
  end

  def possible?
    return false unless super
    return false if @skipped.occupied?
    return true
  end

  def do!
    super
    @piece.passable!
  end

  def reverse!
    super
    @piece.passable!(false)
  end
end

class EnPassant < Move
  def initialize(piece, destination, passed)
    @passed = passed
    super(piece, destination)
  end

  def possible?
    cannot_capture!
    return false unless super
    return false unless @passed.occupied?
    return false unless @passed.side != @piece.side
    return false unless @passed.occupant.is_a? Pawn
    return true
  end

  def do!
    super
    @removed = @passed.remove!
  end

  def reverse!
    super
    @removed.place_on(@passed) if @removed
  end
end

class Castle < Move
  def initialize(piece, board, type)
    cannot_capture!
    case type
      when 'kingside'
        destination = { :file => 2 }
      when 'queenside'
        destination = { :file => -2}
    end
    @cur_pos = piece.location.to_hash
    @board = board
    destination = @board.square(@cur_pos[:rank], @cur_pos[:file] + destination[:file])
    @type = type
    super(piece, destination)
    @rook = Side.find(@piece.side).send("#{@type}_rook".to_sym)
    @rook_origin = @rook.location if @rook
  end

  def notation
    return @notation if @notation
    @notation = case type
      when 'kingside'
        '0-0'
      when 'queenside'
        '0-0-0'
    end
  end

  def possible?
    return false unless @piece.castleable? && @rook && @rook.castleable?
    return false if @piece.in_check?

    adjustment = case @type
      when 'kingside';   1
      when 'queenside'; -1
    end
    @rook_dest = @board.square(@cur_pos[:rank], @cur_pos[:file] + adjustment)
    @rook_onto = @rook_dest.occupant

    return false unless super # check for occupancy and checking at last square
                              # must be after @rook_dest is set
    return false if @rook_dest.occupied?
    @piece.place_on @rook_dest
    cannot_move = @piece.in_check?
    @piece.place_on @original_position
    return false if cannot_move
    return true
  end

  def do!
    super
    @rook.place_on @rook_dest
    @rook.has_moved!
  end

  def reverse!
    super
    @rook.place_on @rook_origin
    @rook.has_moved!(false)
    @rook_onto.place_on @rook_dest if @rook_onto
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

  def location
    @square
  end

  def remove!
    @square = nil
  end

  def place_on(board = @board, square)
    @board = board
    Side.find(@side) << self
    @square.remove! if @square
    @square = square.respond_to?(:occupy_with) ? square : @board[square]
    @square.occupy_with(self)
  end

  def can_move_to? square
    return false if @square.nil?
    square = square.respond_to?(:occupy_with) ? square : @board[square]
    generate_move_list unless @move_list
    @move_list.detect {|move| move.destination == square }
  end

  def can_move?
    return false if @square.nil?
    generate_move_list unless @move_list
    @move_list.length > 0
  end

  def to_s
    @side.capitalize + ' ' + name
  end

  def move_to! square
    raise "Can't move there" unless (move = self.can_move_to? square)
    move.do!
    move
  end

  def invalidate_move_list!
    @move_list = nil
  end

  def promote_to!; raise "This piece cannot be promoted."; end
end

module VectorMovement
  def cur_pos(square = @square)
    square.to_hash
  end

  def generate_move_list_cardinally
    # North
    (cur_pos[:rank]+1..8).each do |rank|
      move = Move.new(self, @board.square(rank, cur_pos[:file]))
      @move_list.push move if move.possible?
      break if move.destination.occupied?
    end

    # East
    (cur_pos[:file]+1..8).each do |file|
      move = Move.new(self, @board.square(cur_pos[:rank], file))
      @move_list.push move if move.possible?
      break if move.destination.occupied?
    end

    # South
    (1..cur_pos[:rank]-1).to_a.reverse.each do |rank|
      move = Move.new(self, @board.square(rank, cur_pos[:file]))
      @move_list.push move if move.possible?
      break if move.destination.occupied?
    end

    # West
    (1..cur_pos[:file]).to_a.each do |file|
      move = Move.new(self, @board.square(cur_pos[:rank], file))
      @move_list.push move if move.possible?
      break if move.destination.occupied?
    end
  end

  def generate_move_list_diagonally
    # Northeast
    adjustment = 1
    begin
      move = Move.new(self, @board.square(cur_pos[:rank] + adjustment, cur_pos[:file] + adjustment))
      @move_list.push move if move.possible?
      break if move.destination.occupied?
      adjustment = adjustment.succ
    rescue Move::InvalidDestination
      break
    end until move.destination.nil?

    # Southeast
    adjustment = 1
    begin
      move = Move.new(self, @board.square(cur_pos[:rank] - adjustment, cur_pos[:file] + adjustment))
      @move_list.push move if move.possible?
      break if move.destination.occupied?
      adjustment = adjustment.succ
    rescue Move::InvalidDestination
      break
    end until move.destination.nil?

    # Southwest
    adjustment = 1
    begin
      move = Move.new(self, @board.square(cur_pos[:rank] - adjustment, cur_pos[:file] - adjustment))
      @move_list.push move if move.possible?
      break if move.destination.occupied?
      adjustment = adjustment.succ
    rescue Move::InvalidDestination
      break
    end until move.destination.nil?

    # Northwest
    adjustment = 1
    begin
      move = Move.new(self, @board.square(cur_pos[:rank] + adjustment, cur_pos[:file] - adjustment))
      @move_list.push move if move.possible?
      break if move.destination.occupied?
      adjustment = adjustment.succ
    rescue Move::InvalidDestination
      break
    end until move.destination.nil?
  end
end

class King < Piece
  def initialize(side)
    @has_moved = false
    super
  end

  def abbr
    'K'
  end

  def in_check?(square = @square)
    cur_pos = square.to_hash

    # Pawn check
    direction = @side == 'white' ? 1 : -1
    [{ :rank => 1, :file =>  1 },
     { :rank => 1, :file => -1 }].each do |adjustment|
      threat = @board.square(cur_pos[:rank] + (direction * adjustment[:rank]),
                             cur_pos[:file] + adjustment[:file])
      return true if threat && threat.occupant.is_a?(Pawn) \
                            && threat.occupied_by?(@side == 'white' ? 'black' : 'white')
    end

    # Knight check
    [{ :rank =>  2, :file =>  1},
     { :rank =>  2, :file => -1},
     { :rank => -2, :file =>  1},
     { :rank => -2, :file => -1},
     { :rank =>  1, :file =>  2},
     { :rank =>  1, :file => -2},
     { :rank => -1, :file =>  2},
     { :rank => -1, :file => -2}].each do |adjustment|
      threat = @board.square(cur_pos[:rank] + adjustment[:rank], cur_pos[:file] + adjustment[:file])
      return true if threat && threat.occupant.is_a?(Knight) \
                            && threat.occupied_by?(@side == 'white' ? 'black' : 'white')
    end

    # North check
    (cur_pos[:rank]+1..8).each do |rank|
      threat = @board.square(rank, cur_pos[:file])
      return true if threat && [Queen, Rook].any? { |type| threat.occupant.is_a? type } \
                            && threat.occupied_by?(@side == 'white' ? 'black' : 'white')
    end

    # East check
    (cur_pos[:file]+1..8).each do |file|
      threat = @board.square(cur_pos[:rank], file)
      return true if threat && [Queen, Rook].any? { |type| threat.occupant.is_a? type } \
                            && threat.occupied_by?(@side == 'white' ? 'black' : 'white')
    end

    # North check
    (1..cur_pos[:rank]-1).to_a.reverse.each do |rank|
      threat = @board.square(rank, cur_pos[:file])
      return true if threat && [Queen, Rook].any? { |type| threat.occupant.is_a? type } \
                            && threat.occupied_by?(@side == 'white' ? 'black' : 'white')
    end

    # West check
    (1..cur_pos[:rank]-1).to_a.reverse.each do |file|
      threat = @board.square(cur_pos[:rank], file)
      return true if threat && [Queen, Rook].any? { |type| threat.occupant.is_a? type } \
                            && threat.occupied_by?(@side == 'white' ? 'black' : 'white')
    end

    # Northeast
    adjustment = 1
    begin
      threat = @board.square(cur_pos[:rank] + adjustment, cur_pos[:file] + adjustment)
      return true if threat && [Queen, Bishop].any? { |type| threat.occupant.is_a? type } \
                            && threat.occupied_by?(@side == 'white' ? 'black' : 'white')
      break if threat.nil? || threat.occupied?
      adjustment = adjustment.succ
    end until threat.nil?

    # Southeast
    adjustment = 1
    begin
      threat = @board.square(cur_pos[:rank] - adjustment, cur_pos[:file] + adjustment)
      return true if threat && [Queen, Bishop].any? { |type| threat.occupant.is_a? type } \
                            && threat.occupied_by?(@side == 'white' ? 'black' : 'white')
      break if threat.nil? || threat.occupied?
      adjustment = adjustment.succ
    end until threat.nil?

    # Southwest
    adjustment = 1
    begin
      threat = @board.square(cur_pos[:rank] - adjustment, cur_pos[:file] - adjustment)
      return true if threat && [Queen, Bishop].any? { |type| threat.occupant.is_a? type } \
                            && threat.occupied_by?(@side == 'white' ? 'black' : 'white')
      break if threat.nil? || threat.occupied?
      adjustment = adjustment.succ
    end until threat.nil?

    # Northeast
    adjustment = 1
    begin
      threat = @board.square(cur_pos[:rank] + adjustment, cur_pos[:file] - adjustment)
      return true if threat && [Queen, Bishop].any? { |type| threat.occupant.is_a? type } \
                            && threat.occupied_by?(@side == 'white' ? 'black' : 'white')
      break if threat.nil? || threat.occupied?
      adjustment = adjustment.succ
    end until threat.nil?

    return false
  end

  def has_moved!(set = true)
    @has_moved = set
  end

  def castleable?
    !@has_moved
  end

  def place_on(board = @board, square)
    Side.find(@side).king = self
    super
  end

  def generate_move_list
    cur_pos = @square.to_hash
    @move_list = []

    [{ :rank =>  1, :file =>  1 },
     { :rank =>  1, :file =>  0 },
     { :rank =>  1, :file => -1 },
     { :rank => -1, :file =>  1 },
     { :rank => -1, :file =>  0 },
     { :rank => -1, :file => -1 },
     { :rank =>  0, :file =>  1 },
     { :rank =>  0, :file => -1 }].each do |adjustment|
      begin
        move = Move.new(self, @board.square(cur_pos[:rank] + adjustment[:rank], \
                                            cur_pos[:file] + adjustment[:file]))
        @move_list.push move if move.possible?
      rescue Move::InvalidDestination
      end
    end

    move = Castle.new(self, @board, 'kingside')
    @move_list.push move if move.possible?
    move = Castle.new(self, @board, 'queenside')
    @move_list.push move if move.possible?

  end
end
class Queen < Piece
  include VectorMovement

  def abbr
    'Q'
  end

  def generate_move_list
    @move_list = []

    generate_move_list_cardinally
    generate_move_list_diagonally
  end
end
class Bishop < Piece
  include VectorMovement

  def abbr
    'B'
  end

  def generate_move_list
    @move_list = []

    generate_move_list_diagonally
  end
end
class Knight < Piece
  def abbr
    'N'
  end

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
      begin
        move = Move.new(self, @board.square(cur_pos[:rank] + adjustment[:rank], \
                                            cur_pos[:file] + adjustment[:file]))
        @move_list.push move if move.possible?
      rescue Move::InvalidDestination
      end
    end

    @move_list.compact!
  end
end
class Rook < Piece
  include VectorMovement
  def initialize(side)
    @has_moved = false
    super
  end

  def abbr
    'R'
  end

  def place_on(board = @board, square)
    super
    Side.find(@side).send(:"#{@square.file == 1 ? :queenside : :kingside}_rook=", self)
  end

  def castleable?
    !@has_moved
  end

  def has_moved!(set = true)
    @has_moved = set
  end

  def generate_move_list
    @move_list = []

    generate_move_list_cardinally
  end
end
class Pawn < Piece
  @@promotable_to = [Queen, Bishop, Knight, Rook]

  def initialize(side)
    @has_moved = false
    @passable = false
    super
  end

  def abbr
    'P'
  end

  def has_moved!(set = true)
    @has_moved = set
  end

  def passable!(set = true)
    @passable = set
  end

  def passable?
    @passable
  end

  def generate_move_list
    direction = @side == 'white' ? 1 : -1
    cur_pos = @square.to_hash
    @move_list = []

    begin
      # Normal
      move = Move.new(self, @board.square(cur_pos[:rank] + (direction * 1), cur_pos[:file]))
      move.cannot_capture!
      @move_list.push move if move.possible?

      # Double advance
      unless @has_moved
        move = DoubleAdvance.new(self, @board.square(cur_pos[:rank] + (direction * 2), cur_pos[:file]),
                                       @board.square(cur_pos[:rank] + (direction * 1), cur_pos[:file]))
        move.cannot_capture!
        @move_list.push move if move.possible?
      end

      # Capture
      [{ :rank => 1, :file => -1},
       { :rank => 1, :file =>  1}].each do |adjustment|
        move = Move.new(self, @board.square(cur_pos[:rank] + (direction * adjustment[:rank]),
                                            cur_pos[:file] + adjustment[:file]))
        move.must_capture!
        @move_list.push move if move.possible?
      end

      # En passant
      [{ :rank => 1, :file => -1},
       { :rank => 1, :file =>  1}].each do |adjustment|
        move = EnPassant.new(self, @board.square(cur_pos[:rank] + (direction * adjustment[:rank]),
                                                 cur_pos[:file] + adjustment[:file]),
                                   @board.square(cur_pos[:rank], cur_pos[:file] + adjustment[:file]))
        @move_list.push move if move.possible?
      end
    rescue Move::InvalidDestination
    end

    @move_list
  end

  def promote_to! to
    promotion_class = @@promotable_to.detect { |piece| piece.to_s == to.capitalize }
    raise "Cannot promote to #{to}" unless promotion_class
    promotion_class.new(@side).place_on(@board, @square)

    @promoted = true
  end
end
