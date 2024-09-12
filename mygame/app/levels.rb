# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/game.rb'
require 'app/button.rb'
require 'app/alert.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Manage levels
class Level
  attr_accessor :current_level

  def initialize(current_level = 1)
    @current_level = current_level
    @alerts = { planter: Alert.new('Planter is unlocked!', color: :purple),
                harvester: Alert.new('Harvester is unlocked!', color: :purple),
                seller: Alert.new('Seller is unlocked!', color: :purple) }
  end

  def tick(args)
    update(args)
    apply_unlocks(args)
  end

  private

  def update(args)
    @current_level = case args.state.game_state.score
                     when 0..100
                       1
                     when 101..400
                       2
                     when 401..800
                       3
                     when 801..1500
                       4
                     else
                       4
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
      args.state.boot.ui_manager.game_ui.unlocked_buttons <<
        { buy_auto_planter: Button.new(:buy_auto_planter, [10, 0],
                                       "Planter (#{args.state.game_state.price[:planter]})") }
      args.state.boot.ui_manager.game_ui.alerts << @alerts[:planter] if @alerts[:planter]
      @alerts[:planter] = false
    when 3
      args.state.boot.ui_manager.game_ui.unlocked_buttons <<
        { buy_auto_harvester: Button.new(:buy_auto_harvester, [10, 50],
                                         "Harvester (#{args.state.game_state.price[:harvester]})") }
      args.state.boot.ui_manager.game_ui.alerts << @alerts[:harvester] if @alerts[:harvester]
      @alerts[:harvester] = false
    when 4
      args.state.boot.ui_manager.game_ui.unlocked_buttons <<
        { buy_auto_seller: Button.new(:buy_auto_seller, [10, 100],
                                      "Seller (#{args.state.game_state.price[:seller]})") }
      args.state.boot.ui_manager.game_ui.alerts << @alerts[:seller] if @alerts[:seller]
      @alerts[:seller] = false
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
