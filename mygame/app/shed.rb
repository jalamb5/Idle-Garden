# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/labels.rb'
require 'app/button.rb'
require 'app/spritesheet.rb'
require 'app/consumable.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Create a garden shed to store seeds and harvested plants
class Shed
  attr_accessor :harvested_plants, :open, :frame, :spritesheet, :selection, :inventory

  def initialize
    @open = false
    @frame = 0
    @harvested_plants = {
      flower_red: [],
      flower_blue: []
    }
    @inventory = { flower_red_seed: Consumable.new(:flower_red, 5), flower_blue_seed: Consumable.new(:flower_blue, 0) }
    @labels = generate_labels
    @buttons = generate_buttons
    @spritesheet = Spritesheet.new('sprites/shed_sheet.png', 64, 64, 2)
    @selection = :flower_red_seed
  end

  def tick(args)
    args.state.game_state.plant_manager.block_plant = true
    draw_shed(args)
    return unless @open

    handle_labels(args)
    handle_images(args)
    handle_buttons(args)
  end

  private

  def generate_labels
    labels = {}
    y = 500
    items = @inventory
    items.each do |key, value|
      if key.include?('_harvested')
        # Sellable inventory (eg. harvested plants)
        labels["#{key}_sellabe".to_sym] = Labels.new(250, y, '', value.quantity, 20, [255, 255, 255, 255])
      else
        # Usable inventory (eg. seeds)
        labels["#{key}_usable".to_sym] = Labels.new(450, y, '', value.quantity, 20, [255, 255, 255, 255])
      end
      y -= 50
    end
    labels.merge(manual_labels)
  end

  def manual_labels
    {
      title: Labels.new(650, 650, 'Garden Shed', '', 30, [255, 255, 255, 255]),
      inventory: Labels.new(250, 550, 'Inventory', '', 20, [255, 255, 255, 255]),
      shop: Labels.new(450, 550, 'Shop', '', 20, [255, 255, 255, 255])
    }
  end

  def handle_labels(args)
    @labels.each do |key, label|
      label.display(args)
      label.update(key, args)
    end
  end

  def generate_buttons
    buttons = {}
    y = 470
    @harvested_plants.each_key do |key|
      buttons["sell#{key}".to_sym] = Button.new(:sell, [300, y], 'Sell', [50, 40], :default, key)
      buttons["buy_#{key}".to_sym] = Button.new(:buy, [500, y], 'Buy', [50, 40], :default, key)
      buttons["select_#{key}".to_sym] = Button.new(:select, [550, y], 'Select', [50, 40], :default, key)
      y -= 50
    end
    buttons
  end

  def handle_buttons(args)
    @buttons.each_value do |button|
      button.display(args)
      button.clicked?(args)
      button.hover?(args)
    end
  end

  def draw_shed(args)
    animate_shed
    args.outputs.sprites << { x: 200, y: 0, w: @frame, h: 720, a: 240, path: 'sprites/shed_background.png' }
  end

  def animate_shed
    if @open && @frame <= 1000
      @frame += 100
    elsif !@open && @frame.positive?
      @frame -= 100
    end
  end

  def handle_images(args)
    plant_spritesheets = args.state.game_state.plant_manager.spritesheets
    coords = [215, 480]
    @harvested_plants.each_key do |key|
      if plant_spritesheets.include?(key)
        args.outputs.sprites << plant_spritesheets[key].get(30, coords[0], coords[1], 25,
                                                            25)
      end
      coords[1] -= 50
    end
  end

  # DragonRuby required methods
  def serialize
    { open: @open, frame: @frame, harvested_plants: @harvested_plants, selection: @selection }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
