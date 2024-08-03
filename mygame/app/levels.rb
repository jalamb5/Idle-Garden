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
    update(args)
    apply_unlocks(args)
  end

  private

  def update(args)
    case args.state.game_state.score
    when 0..100
      @current_level = 1
    when 101..200
      @current_level = 2
    end
  end

  # Apply unlock changes to all levels even if player leapfrogs a level
  def apply_unlocks(args)
    (1..@current_level).each do |level|
      unlock_level(args, level)
    end
  end

  def unlock_level(args, level)
    case level
    when 2
      args.state.game_state.unlock_buttons[:auto_planter] ||=
        Button.new(:auto_planter, 0, 100, "Planter (#{args.state.game_state.price[:planter]})")
    end
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
