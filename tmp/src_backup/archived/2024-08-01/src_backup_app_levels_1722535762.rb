# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/game.rb'
require 'app/button.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Manage levels
class Level
  attr_accessor :current_level

  def initialize(current_level = 1)
    @current_level = current_level
  end

  def tick(args)
    case args.state.game_state.score
    when 0..100
      @current_level = 1
    when 101..200
      @current_level = 2
      args.state.game_state.unlock_buttons[:auto_planter] = Button.new(:auto_planter, 0, 100, "Planter (#{args.state.game_state.price[:planter]})")
    end
  end
  def update(level)
    @current_level = level
  end


  # DragonRuby required methods
  def serialize
    { current_level: @current_level }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
