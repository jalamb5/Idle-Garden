# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/plant.rb'
require 'app/automation.rb'
require 'app/labels.rb'
require 'app/button.rb'
require 'app/levels.rb'
require 'app/alert.rb'
require 'app/spritesheet.rb'
require 'app/pause.rb'
require 'app/uimanager.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Handle game logic
class Game
  attr_accessor :loaded_from_save, :plants, :seeds, :harvested_plants, :cash, :price, :auto_planters, :auto_harvesters,
                :auto_sellers, :counter, :score, :level, :unlock_buttons, :alerts, :paused, :spritesheets, :ui

  def initialize(args)
    @loaded_from_save = false
    @paused = false
    @garden = { x: 250, y: 50, w: 980, h: 620 }
    @spritesheets = build_spritesheets
    @plants = []
    @seeds = 5
    @harvested_plants = 0
    @cash = 5
    @price = { seed: 5, plant: 10, planter: 150, harvester: 250, seller: 350 }
    @auto_planters = []
    @auto_harvesters = []
    @auto_sellers = []
    @counter = 0
    @score = 0
    @level = Level.new
    @unlock_buttons = {}
    @alerts = []
    @ui = UIManager.new(args, self)
  end

  def tick(args)
    return pause_menu(args) if args.state.game_state.paused == true

    @counter += 1
    reconstruct_objects(args) if @loaded_from_save == true

    standard_display(args)
    dev_mode(args)
  end

  private

  def standard_display(args)
    @ui.tick(args)

    plant_harvest(args)
    manage_plants(args)
    display_plants(args)

    manage_automations(args)

    @level.tick(args)

    debt_check
  end

  def plant_harvest(args)
    return unless args.inputs.mouse.click && args.inputs.mouse.point.inside_rect?(@garden)

    sheet = [0, 1].sample
    new_plant = Plant.new(args, sheet)

    return unless @seeds.positive? && !new_plant.invalid

    @plants << new_plant
    @seeds -= 1
  end

  def manage_plants(args)
    @plants.reject!(&:invalid)
    @plants.each { |plant| plant.grow(args) }
  end

  def display_plants(args)
    @plants.each do |plant|
      args.outputs.sprites << plant.sprite
    end
  end

  def manage_automations(args)
    return if @counter % 75 != 0

    @auto_harvesters.each do |automation|
      automation.run(args)
    end
    @auto_planters.each do |automation|
      automation.run(args)
    end
    @auto_sellers.each do |automation|
      automation.run(args)
    end

    @counter = 0
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

  def build_spritesheets
    [Spritesheet.new('sprites/flower_red_64x64.png', 64, 64, 56),
     Spritesheet.new('sprites/flower_blue_64x64.png', 64, 64, 56)]
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
    { loaded_from_save: @loaded_from_save, plants: @plants, seeds: @seeds, harvested_plants: @harvested_plants, cash: @cash,
      price: @price, auto_planters: @auto_planters, auto_harvesters: @auto_harvesters, auto_sellers: @auto_sellers,
      counter: @counter, score: @score, level: @level, unlock_buttons: @unlock_buttons, paused: @paused, spritesheets: @spritesheets, ui: @ui }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
