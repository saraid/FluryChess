require 'goliath'
require 'json'
load 'board.rb'

class Server < Goliath::API
  use ::Rack::Reloader, 0
  use Goliath::Rack::Params

  def response(env)

    return [400, {}, 'No method entered'] if params['method'].nil?

    begin
      arguments = params.reject { |param| param == 'method' }
      response = send("server_method_#{params['method']}".to_sym, arguments)

      [200, {}, response]
    rescue NoMethodError
      [400, {}, 'No such method']
    end
  end

  def server_method_getSquare params
    game = Game.new
    square = game.board[params['spot']]
    if square && square.occupant
      "That square contains a #{square.occupant.to_s}."
    else
      "This square is empty."
    end
  end

  def server_method_gameState params
    Game.new.to_json
  end

  def server_method_submitMove params
    game = Game.new
    game.move params['move']
    game.to_json
  end
end
