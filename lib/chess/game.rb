require_relative 'game/state'
require 'forwardable'

module Chess
  class Game
    extend Forwardable

    def_delegators :@current_state,
      :board, :en_passant_target, :can_castle?, :full_move_number, :active_color,
      :to_fen, :to_state

    def_delegators :@history,
      :over?, :checkmated?, :draw?,
      :to_pgn

    def self.from_pgn(pgn)
      options = { metadata: {} }

      movetext = []
      pgn.each_line do |line|
        case line
        when /^\[(?<name>\w+) "(?<value>.+)"\]$/
          options[:metadata][$~[:name].downcase.to_sym] = $~[:value]
        else
          movetext << line
        end
      end

      if options[:metadata][:fen]
        options[:board] = Board.from_fen(options[:metadata][:fen])
      else
        options[:board] = Board.from_fen(Board::Configuration::Standard.as_fen)
      end

      game = Game.new(options)

      # Parse movetext
      movetext.
        join.
        gsub(/{.*}/, ''). # strip comments
        gsub(/\d+\./, ''). # strip move numbering
        split(/\s+/).
        select { |move| move =~ Notation::StandardAlgebraic.matcher }.
        each { |move| game.play move }

      game
    end

    def self.from_fen(fen)
      md = fen.match Chess::Notation::ForsytheEdwards::REGEX
      options = { state: {} }

      options[:board] = Chess::Board.from_fen(md['placement_text'])
      [ :active_color,
        :castling_availability,
        :en_passant_target,
        :full_move_clock ].each do |state|
        case state
        when :en_passant_target
          options[:state][state] = options[:board][md[state]]
        when :active_color
          options[:state][state] = md[state] == 'w' ? :white : :black
        else
          options[:state][state] = md[state]
          options[:state][state] = options[:state][state].to_i if state == :full_move_clock
        end
      end

      Game.new(options)
    end

    def initialize(options = {})
      @metadata = options[:metadata] || {}
      starting_state = State.new({ board: options[:board] }.merge(options[:state] || {}))
      @history = History.new(starting_state, options[:moves] || [])
      @current_state = @history.current_state
    end
    attr_reader :metadata,  :history, :current_state
    alias :state :current_state

    def move_taken(move)
      @history.record(move)
      @current_state = @history.current_state
    end

    def play(movetext, notation = :san)
      move =
        if movetext.class.ancestors.include? Chess::Move::Base
          movetext
        else
          case notation
          when :san then Chess::Move.from_san(self, movetext)
          end
        end
      move_taken move
      [ move.to_english, to_fen ]
    end
  end
end
