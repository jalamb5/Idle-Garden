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
  attr_accessor :open, :frame, :spritesheet, :selection, :inventory

  def initialize
    @open = false
    @frame = 0
    @inventory = { flower_red_harvested: Consumable.new(:flower_red, 0),
                   flower_blue_harvested: Consumable.new(:flower_blue, 0),
                   flower_red_seed: Consumable.new(:flower_red, 5),
                   flower_blue_seed: Consumable.new(:flower_blue, 0),
                   fertilizer: Consumable.new(:fertilizer, 0) }
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

  # Return a total count of item quantity of specified type
  def inventory_count(type)
    count = 0
    @inventory.each do |key, value|
      count += value.quantity if key.include?(type)
    end
    count
  end

  # Return hash of items of specified type
  def inventory_search(type)
    items = {}
    @inventory.each do |key, value|
      items[key] = value if key.include?(type)
    end
    items
  end

  private

  Item_types = Struct.new(:harvested, :usable)
  def split_inventory
    harvested = {}
    usable = {}
    @inventory.each do |key, value|
      if key.include?('_harvested')
        harvested << { key => value }
      else
        usable << { key => value }
      end
    end
    Item_types.new(harvested, usable)
  end

  def generate_labels
    items = split_inventory

    labels = {}
    labels << build_labels(items.harvested, 'harvested')
    labels << build_labels(items.usable, 'usable')

    labels.merge(manual_labels)
  end

  def build_labels(items, type)
    labels = {}
    y = 500
    x = type == 'harvested' ? 250 : 450
    items.each do |key, value|
      labels["#{key}".to_sym] = Labels.new(x, y, '', value.quantity, 20, [255, 255, 255, 255])
      y -= 50
    end
    labels
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

  # TODO: split into multiple methods like labels
  def generate_buttons
    buttons = {}
    y = 470
    items = split_inventory
    items.harvested.each_key do |key|
      buttons["sell#{key}".to_sym] = Button.new(:sell, [300, y], 'Sell', [50, 40], :default, key)
      y -= 50
    end
    y = 470
    items.usable.each_key do |key|
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
    y = 480
    @inventory.each do |key, value|
      next if key.include?('_harvested')

      args.outputs.sprites << value.get_key_frame([215, y, 25, 25])
      y -= 50
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
