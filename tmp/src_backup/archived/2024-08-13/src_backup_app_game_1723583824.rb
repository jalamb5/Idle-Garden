# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/plant.rb'
require 'app/automation.rb'
require 'app/levels.rb'
require 'app/alert.rb'
require 'app/pause.rb'
require 'app/ui_manager.rb'
require 'app/automation_manager.rb'
require 'app/plant_manager.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Handle game logic
class Game
  attr_accessor :loaded_from_save, :plant_manager, :harvested_plants, :cash, :price, :score, :level, :paused,
                :ui, :automations

  def initialize(args)
    @loaded_from_save = false
    @paused = false
    @harvested_plants = 0
    @cash = 5
    @price = { seed: 5, plant: 10, planter: 150, harvester: 250, seller: 350 }
    @score = 0
    @level = Level.new
    @ui = UIManager.new(args, self)
    @automations = AutomationManager.new
    @plant_manager = PlantManager.new
  end

  def tick(args)
    return pause_menu(args) if args.state.game_state.paused == true

    args.state.load_state.

    standard_display(args)
    dev_mode(args)
  end

  private

  def standard_display(args)
    @ui.tick(args)

    @plant_manager.tick(args)

    @automations.tick(args)

    @level.tick(args)

    debt_check
  end

  def debt_check
    return unless @cash <= 0 && @harvested_plants <= 0 && @seeds <= 0 && @plants.length <= 0

    # If player has no money, no seeds, no plants, and no harvests, debt is accrued.
    @seeds += 5
    @cash -= 30
    @ui.alerts << Alert.new('You have been given 5 seeds. You have incurred a debt of $30.')
  end

  def pause_menu(args)
    pause_screen ||= Pause.new(args)
    pause_screen.tick(args)
  end

  # Load from save functions, reconstruct objects
  def reconstruct_objects(args)
    @unlock_buttons = {}
    @spritesheets = build_spritesheets
    @level = Level.new(@level.current_level) unless @level.instance_of?(Level)
    reconstruct_plants(args) unless @plants.empty?
    reconstruct_automations(:harvester) unless @auto_harvesters.empty?
    reconstruct_automations(:planter) unless @auto_planters.empty?
    reconstruct_automations(:seller) unless @auto_sellers.empty?

    @loaded_from_save = false
  end

  def reconstruct_plants(args)
    attributes = %i[x y w h age stage a frame sheet]

    @plants.map! do |plant|
      new_plant = Plant.new(args, 0, 0, 0)
      attributes.each do |attr|
        new_plant.send("#{attr}=", plant.send(attr))
      end
      new_plant
    end
  end

  def reconstruct_automations(automator)
    attributes = %i[type harvest_cooldown planter_cooldown seller_cooldown]
    types = { harvester: @auto_harvesters, planter: @auto_planters, seller: @auto_sellers }

    types[automator].map! do |automation|
      new_automation = Automation.new(automator)
      attributes.each do |attr|
        new_automation.send("#{attr}=", automation.send(attr))
      end
      new_automation
    end
  end

  # Enter dev mode if keys d & e are held while v is pressed
  def dev_mode(args)
    return unless args.inputs.keyboard.key_held.d && args.inputs.keyboard.key_held.e && args.inputs.keyboard.key_down.v

    @ui.alerts << Alert.new('Dev Mode Activated!')
    @cash += 1000
    @seeds += 500
    @score += 400
  end

  # DragonRuby required methods
  def serialize
    { loaded_from_save: @loaded_from_save, plant_manager: @plant_manager, harvested_plants: @harvested_plants,
      cash: @cash, price: @price, score: @score, level: @level, paused: @paused, ui: @ui,
      automations: @automations }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
