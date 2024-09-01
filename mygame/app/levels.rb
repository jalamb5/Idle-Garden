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
    when 101..400
      @current_level = 2
    when 401..800
      @current_level = 3
    when 801..1500
      @current_level = 4
    else
      @current_level = 4
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
      args.state.game_state.ui.unlocked_buttons <<
        { buy_auto_planter: Button.new(:buy_auto_planter, [10, 0],
                                       "Planter (#{args.state.game_state.price[:planter]})") }
    when 3
      args.state.game_state.ui.unlocked_buttons <<
        { buy_auto_harvester: Button.new(:buy_auto_harvester, [10, 50],
                                         "Harvester (#{args.state.game_state.price[:harvester]})") }
    when 4
      args.state.game_state.ui.unlocked_buttons <<
        { buy_auto_seller: Button.new(:buy_auto_seller, [10, 100],
                                      "Seller (#{args.state.game_state.price[:seller]})") }
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
