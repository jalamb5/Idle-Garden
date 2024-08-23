# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/labels.rb'
require 'app/button.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Create a garden shed to store seeds and harvested plants
class Shed
  attr_accessor :harvested_plants, :open

  def initialize
    @open = false
    @frame = 0
    @harvested_plants = 0
    @labels = generate_labels
    @buttons = generate_buttons
  end

  def tick(args)
    args.state.game_state.block_click = true
    draw_shed(args)
    handle_labels(args)
    handle_buttons(args)
  end

  private

  def generate_labels
    { harvested: Labels.new(150, 200, 'Harvested:', @harvested_plants, 20, [255, 255, 255, 255]) }
  end

  def handle_labels(args)
    @labels.each do |key, label|
      label.display(args)
      label.update(key, args)
    end
  end

  def generate_buttons
    { shed: Button.new(:shed, [900, 400], 'Close', [100, 100]) }
  end

  def handle_buttons(args)
    @buttons.each_value { |button| button.display(args) && button.clicked?(args) }
  end

  def draw_shed(args)
    @frame += 2 unless @frame >= 1080
    args.outputs.primitives << { x: 100, y: 0, w: @frame, h: 520, r: 0, g: 0, b: 0, a: 155, primitive_marker: :solid }
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
