# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/labels.rb'
require 'app/button.rb'
require 'app/spritesheet.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Manage display and updating of UI elements
class UIManager
  attr_accessor :buttons, :unlocked_buttons, :labels, :alerts, :images

  def initialize(args, game)
    @buttons = generate_buttons(args, game)
    @unlocked_buttons = []
    @alerts = []
    @images = [
      { x: 170, y: args.grid.h - 30, w: 24, h: 24, path: 'sprites/pause_icon.png' },
      { x: 120, y: 175, w: 50, h: 50, path: 'sprites/selection_box.png' }
    ]
    @label_details = { score: ['Score:', args.state.game_state.score, 23, [240, 30, 30, 255]],
                       seed: ['Seeds:', args.state.game_state.plant_manager.seeds],
                       growing: ['Growing:', args.state.game_state.plant_manager.plants.length],
                       cash: ['Cash:', args.state.game_state.cash],
                       level: ['Level:', args.state.game_state.level.current_level] }
    @labels = generate_labels(args)
    @images << construct_soil_sprite
    @images << construct_sidebar_sprite
    @grass_data = generate_grass_data
    @frame = 0
  end

  def tick(args)
    display_images(args)

    unlock_buttons
    display_buttons(args)
    display_labels(args)

    monitor_buttons(args)
    update_labels(args)

    handle_alerts(args) if @alerts.any?
    display_shed(args)
    @frame += 1
  end

  private

  def generate_buttons(args, _game)
    {
      pause_game: Button.new(:pause_game, [170, args.grid.h - 30], '', [30, 30], :clear),
      shed: Button.new(:shed, [0, 170], '', [64, 50], :clear)
    }
  end

  def generate_labels(args)
    labels = {}
    coords = [5, args.grid.h]
    @label_details.each do |key, value|
      case value.length
      when 2
        labels[key] = Labels.new(coords[0], coords[1], value[0], value[1])
      when 3
        labels[key] = Labels.new(coords[0], coords[1], value[0], value[1], value[2])
      when 4
        labels[key] = Labels.new(coords[0], coords[1], value[0], value[1], value[2], value[3])
      end
      coords[1] -= 20
    end
    labels
  end

  # Add any unlocked buttons to the full button array and clear the unlocked array
  def unlock_buttons
    @unlocked_buttons.each { |button| @buttons << button unless @buttons.include?(button) }
    @unlocked_buttons.clear
  end

  def display_buttons(args)
    @buttons.each_value { |button| button.display(args) }
  end

  def monitor_buttons(args)
    @buttons.each_value do |button|
      button.clicked?(args)
      button.hover?(args)
    end
  end

  def display_labels(args)
    @labels.each_value { |label| label.display(args) }
  end

  def update_labels(args)
    @labels.each do |key, label|
      label.update(key, args)
    end
  end

  def handle_alerts(args)
    @alerts.each { |alert| alert.display(args) }
    # Remove expired alerts
    @alerts.reject! { |alert| alert.ttl.zero? }
  end

  def construct_soil_sprite
    spritesheet = Spritesheet.new('sprites/garden_soil.png', 15, 570, 3)
    [spritesheet.get(0, 250, 50, 15, 620),
     spritesheet.get(1, 265, 50, 950, 620),
     spritesheet.get(2, 1215, 50, 15, 620)]
  end

  def construct_sidebar_sprite
    spritesheet = Spritesheet.new('sprites/sidebar.png', 5, 720, 3)
    [spritesheet.get(0, 0, 0, 5, 720),
     spritesheet.get(1, 5, 0, 195, 720),
     spritesheet.get(2, 195, 0, 5, 720)]
  end

  # Create arrays for each 50x50 segment of grass with randomized spritesheet value
  def generate_grass_data
    data = []

    (200...1280).each do |x|
      next unless (x % 50).zero?

      (0...720).each do |y|
        next unless (y % 50).zero?

        data << [(0..5).select(&:even?).sample, x, y, 50, 50] unless (300...1200).include?(x) && (50...630).include?(y)
      end
    end

    data
  end

  # Use grass data to construct sprites from spritesheet. Adjust spritesheet value based on frame count.
  def construct_grass_sprite
    spritesheet = Spritesheet.new('sprites/garden_grass_simplified.png', 50, 50, 6)
    sprites = []
    @grass_data.each do |grass|
      sprites << spritesheet.get(grass[0], grass[1], grass[2], grass[3], grass[4])
      # shift image periodically to animate
      if (@frame % 100).zero?
        grass[0] = grass[0].even? ? grass[0] + 1 : grass[0] - 1
      end
    end
    sprites
  end

  def display_grass_sprites(args)
    sprites = construct_grass_sprite
    sprites.each { |sprite| args.outputs.sprites << sprite }
  end

  def display_selection(args)
    plant_manager = args.state.game_state.plant_manager
    args.outputs.sprites << plant_manager.spritesheets[plant_manager.selection].get(30, 130, 180, 25, 25)
  end

  def display_images(args)
    display_grass_sprites(args)
    display_selection(args)
    @images.each { |image| args.outputs.sprites << image }
  end

  def display_shed(args)
    shed = args.state.game_state.shed
    args.outputs.sprites << shed.spritesheet.get(0, 10, 175, 64, 64) unless shed.open
    # Don't tick if the shed is closed and the animation has completed
    return if !shed.open && shed.frame.zero?

    args.outputs.sprites << shed.spritesheet.get(1, 10, 175, 64, 64)
    shed.tick(args)
  end

  # DragonRuby required methods
  def serialize
    { buttons: @buttons, unlocked_buttons: @unlocked_buttons, labels: @labels, alerts: @alerts, images: @images }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
