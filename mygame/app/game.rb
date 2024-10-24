# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/levels.rb'
require 'app/alert.rb'
require 'app/shed.rb'
require 'app/managers/ui_manager.rb'
require 'app/managers/automation_manager.rb'
require 'app/managers/plant_manager.rb'
require 'app/managers/soil_manager.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Handle game logic
class Game
  attr_accessor :plant_manager, :soil_manager, :cash, :price, :score, :level, :paused,
                :automations, :shed, :save_data

  def initialize
    @paused = false
    @cash = 5
    @price = { flower_red_seed: 5, flower_blue_seed: 10, fertilizer: 15,
               flower_red_harvested: 10, flower_blue_harvested: 15, planter: 150, harvester: 250, seller: 350 }
    @score = 0
    @level = Level.new
    @shed = Shed.new
    @automations = AutomationManager.new
    @plant_manager = PlantManager.new
    @soil_manager = SoilManager.new
    @save_data = {}
  end

  def tick(args)
    # args.state.load_state.load_save(args) if args.state.load_state.loaded_from_save == true

    standard_display(args)
    dev_mode(args)
  end

  private

  def standard_display(args)
    @soil_manager.tick(args)

    @automations.tick(args)

    @plant_manager.tick(args)

    @level.tick(args)

    debt_check(args.state.boot.ui_manager.game_ui.alerts)
    @block_click = false
  end

  def debt_check(alerts)
    return unless @cash <= 0 && @shed.inventory.all? { |_k, v| v.quantity.zero? } && @plant_manager.plants.length <= 0

    # If player has no money, no seeds, no plants, and no harvests, debt is accrued.
    @shed.inventory.flower_red_seed.quantity += 5
    @cash -= 30
    alerts << Alert.new('You have been given 5 seeds. You have incurred a debt of $30.', color: :pink)
  end

  # Enter dev mode if keys d & e are held while v is pressed
  def dev_mode(args)
    return unless args.inputs.keyboard.key_held.d && args.inputs.keyboard.key_held.e && args.inputs.keyboard.key_down.v

    args.state.boot.ui_manager.game_ui.alerts << Alert.new('Dev Mode Activated!')
    @cash += 1000
    @shed.inventory.flower_red_seed.quantity += 500
    @score += 9000
  end

  # DragonRuby required methods
  def serialize
    { plant_manager: @plant_manager,
      cash: @cash, score: @score,
      automations: @automations, shed: @shed, save_data: @save_data }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
