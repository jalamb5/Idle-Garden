# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/labels.rb'
require 'app/button.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Create a garden shed to store seeds and harvested plants
class Shed
  attr_accessor :harvested_plants, :open, :frame

  def initialize
    @open = false
    @frame = 0
    @harvested_plants = {
      Harvest: '',
      flower_red: 0,
      flower_blue: 0
    }
    @labels = generate_labels
    @buttons = generate_buttons
  end

  def tick(args)
    args.state.game_state.block_click = true
    draw_shed(args)
    if @open
      handle_labels(args)
      handle_images(args)
    end
    # handle_labels(args) if @open
    # handle_buttons(args)
  end

  private

  def generate_labels
    labels = {}
    y = 450
    @harvested_plants.each do |key, value|
      labels[key] = Labels.new(150, y, key.to_s, value, 20, [255, 255, 255, 255])
      y -= 50
    end
    labels
  end

  def handle_labels(args)
    @labels.each do |key, label|
      label.display(args)
      label.value = @harvested_plants[key]
    end
  end

  def generate_buttons
    { shed: Button.new(:shed, [900, 400], 'Close', [100, 100]) }
  end

  def handle_buttons(args)
    @buttons.each_value { |button| button.display(args) && button.clicked?(args) }
  end

  def draw_shed(args)
    animate_shed
    args.outputs.primitives << { x: 100, y: 0, w: @frame, h: 520, r: 0, g: 0, b: 0, a: 155, primitive_marker: :solid }
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
    coords = [115, 425]
    @harvested_plants.each_key do |key|
      sprite = plant_spritesheets[key].get(30, coords[0], coords[1], 25, 25) if plant_spritesheets.include?(key)
      sprite[blend]
      args.outputs.sprites << plant_spritesheets[key].get(30, coords[0], coords[1], 25, 25) if plant_spritesheets.include?(key)
      coords[1] -= 50
    end
  end

  # DragonRuby required methods
  def serialize
    { open: @open, frame: @frame, harvested_plants: @harvested_plants }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end