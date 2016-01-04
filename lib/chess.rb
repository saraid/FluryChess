require_relative 'refinements/enumerable'
require_relative 'refinements/try'
require_relative 'refinements/memoize'

module Chess
  class Error < StandardError; end
end

require_relative 'chess/move'
require_relative 'chess/piece'
require_relative 'chess/notation'

require_relative 'chess/square'
require_relative 'chess/board'
require_relative 'chess/game'
require_relative 'chess/history'
