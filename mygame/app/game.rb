# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/plant.rb'
require 'app/automation.rb'
require 'app/labels.rb'
require 'app/button.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Handle game logic
class Game
  attr_accessor :splash_state, :plants, :seeds, :harvested_plants, :cash, :price, :auto_planters, :auto_harvesters,
                :auto_sellers, :counter

  def initialize(args)
    @splash_state = true
    @garden = { x: 250, y: 50, w: 980, h: 620 }
    @plants = []
    @seeds = 500
    @harvested_plants = 0
    @cash = 5
    @price = { seed: 5, plant: 10, harvester: 150, planter: 150, seller: 50 }
    @auto_planters = []
    @auto_harvesters = []
    @auto_sellers = []
    @counter = 0
    @standard_buttons = generate_buttons(args)
    @standard_labels = generate_labels(args)
    play_music(args)
  end

  def tick(args)
    @counter += 1

    if @splash_state
      splash(args)
    else
      standard_display(args)
    end
  end

  private

  def splash(args)
    args.outputs.sprites << { x: 0, y: 0, w: 1280, h: 720, path: 'sprites/splash.png' }
    args.state.start_button ||= Button.new(:start, 540, 360, 'Start', 200, 50, :opaque)
    args.state.start_button.display(args)
    args.state.start_button.clicked?(args)
    args.state.load_save_button ||= Button.new(:load_save, 540, 260, 'Load Save', 200, 50, :opaque)
    args.state.load_save_button.display(args)
    args.state.load_save_button.clicked?(args)
  end

  def standard_display(args)
    args.outputs.sprites << { x: 200, y: 0, w: 1080, h: 720, path: 'sprites/grass_background.png' }
    args.outputs.sprites << { x: 250, y: 50, w: 980, h: 620, path: 'sprites/background.png' }

    display_buttons(args)
    monitor_buttons(args)

    display_labels(args)
    update_labels(args)

    plant_harvest(args)
    manage_plants(args)

    manage_automations(args)
  end

  def play_music(args)
    args.audio[:music] = {
      input: 'sounds/Garden_Melody.ogg',
      gain: 0.25,
      looping: true
    }
  end

  def generate_buttons(_args)
    {
      buy_seed: Button.new(:buy_seed, 100, 100, "Seed (#{@price[:seed]})"),
      sell: Button.new(:sell, 0, 0, 'Sell', 200),
      auto_harvester: Button.new(:auto_harvester, 0, 50, "Harvester (#{@price[:harvester]})"),
      auto_seller: Button.new(:auto_seller, 100, 50, "Seller (#{@price[:seller]})"),
      auto_planter: Button.new(:auto_planter, 0, 100, "Planter (#{@price[:planter]})"),
      save: Button.new(:save, 0, 150, 'Save')
    }
  end

  def display_buttons(args)
    @standard_buttons.each_value do |button|
      button.display(args)
    end
  end

  def monitor_buttons(args)
    @standard_buttons.each_value do |button|
      button.clicked?(args)
    end
  end

  def generate_labels(args)
    {
      seed: Labels.new(5, args.grid.h - 20, 'Seeds', @seeds),
      growing: Labels.new(5, args.grid.h - 40, 'Growing', @plants.length),
      harvested: Labels.new(5, args.grid.h - 60, 'Harvested', @harvested_plants),
      cash: Labels.new(5, args.grid.h - 80, 'Cash', @cash),
      auto_harvesters: Labels.new(5, args.grid.h - 100, 'Auto Harvesters', @auto_harvesters.length),
      auto_planters: Labels.new(5, args.grid.h - 120, 'Auto Planters', @auto_planters.length),
      auto_sellers: Labels.new(5, args.grid.h - 140, 'Auto Sellers', @auto_sellers.length)
    }
  end

  def display_labels(args)
    @standard_labels.each_value do |label|
      label.display(args)
    end
  end

  def update_labels(args)
    @standard_labels.each do |key, label|
      label.update(key, args)
    end
  end

  def plant_harvest(args)
    return unless args.inputs.mouse.click && args.inputs.mouse.point.inside_rect?(@garden)

    new_plant = Plant.new(args)

    return unless @seeds.positive? && !new_plant.invalid

    @plants << new_plant
    @seeds -= 1
  end

  def manage_plants(args)
    @plants.reject!(&:invalid)
    @plants.each(&:grow)
    args.outputs.sprites << @plants
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

  # DragonRuby required methods
  def serialize
    { splash_state: @splash_state, plants: @plants, seeds: @seeds, harvested_plants: @harvested_plants, cash: @cash,
      price: @price, auto_planters: @auto_planters, auto_harvesters: @auto_harvesters, auto_sellers: @auto_sellers, counter: @counter }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
