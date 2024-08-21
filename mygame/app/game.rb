# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/levels.rb'
require 'app/alert.rb'
require 'app/pause.rb'
require 'app/managers/ui_manager.rb'
require 'app/managers/automation_manager.rb'
require 'app/managers/plant_manager.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Handle game logic
class Game
  attr_accessor :plant_manager, :harvested_plants, :cash, :price, :score, :level, :paused,
                :ui, :automations, :block_click, :save_data

  def initialize(args)
    @paused = false
    @block_click = false
    @harvested_plants = 0
    @cash = 5
    @price = { seed: 5, plant: 10, planter: 150, harvester: 250, seller: 350 }
    @score = 0
    @level = Level.new
    @ui = UIManager.new(args, self)
    @automations = AutomationManager.new
    @plant_manager = PlantManager.new
    @save_data = {}
  end

  def tick(args)
    return pause_menu(args) if args.state.game_state.paused == true

    args.state.load_state.load_save(args) if args.state.load_state.loaded_from_save == true

    standard_display(args)
    dev_mode(args)
  end

  private

  def standard_display(args)
    @ui.tick(args)

    @automations.tick(args)

    @plant_manager.tick(args)

    @level.tick(args)

    debt_check
    @block_click = false
  end

  def debt_check
    return unless @cash <= 0 && @harvested_plants <= 0 && @plant_manager.seeds <= 0 && @plant_manager.plants.length <= 0

    # If player has no money, no seeds, no plants, and no harvests, debt is accrued.
    @plant_manager.seeds += 5
    @cash -= 30
    @ui.alerts << Alert.new('You have been given 5 seeds. You have incurred a debt of $30.', color: :pink)
  end

  def pause_menu(args)
    pause_screen ||= Pause.new(args)
    pause_screen.tick(args)
  end

  # Enter dev mode if keys d & e are held while v is pressed
  def dev_mode(args)
    return unless args.inputs.keyboard.key_held.d && args.inputs.keyboard.key_held.e && args.inputs.keyboard.key_down.v

    @ui.alerts << Alert.new('Dev Mode Activated!')
    @cash += 1000
    @plant_manager.seeds += 500
    @score += 9000
  end

  # DragonRuby required methods
  def serialize
    { plant_manager: @plant_manager, harvested_plants: @harvested_plants,
      cash: @cash, score: @score, ui: @ui,
      automations: @automations, save_data: @save_data }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
