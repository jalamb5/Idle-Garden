# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/labels.rb'
require 'app/button.rb'
require 'app/spritesheet.rb'
require 'app/ui_helpers.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Manage display and updating of UI elements for standard game screen
class GameUIBuilder
  attr_accessor :buttons, :unlocked_buttons, :labels, :alerts, :images

  def initialize(args)
    @buttons = generate_buttons(args)
    @unlocked_buttons = []
    @alerts = []
    @images = [
      { x: 170, y: args.grid.h - 30, w: 24, h: 24, path: 'sprites/pause_icon.png' },
      { x: 120, y: 175, w: 50, h: 50, path: 'sprites/selection_box.png' }
    ]
    @label_details = { score: ['Score:', args.state.game_state.score, 23, [240, 30, 30, 255]],
                       growing: ['Growing:', args.state.game_state.plant_manager.plants.length],
                       cash: ['Cash:', args.state.game_state.cash],
                       level: ['Level:', args.state.game_state.level.current_level] }
    @labels = generate_labels(args)
    @grass_data = UIHelpers.screen_grid_generator(50, 200...1280, 0...720, 0..11, 2)
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
  end

  private

  def generate_buttons(args)
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

  def construct_soil_sprite(args, spritesheet)
    sprites = [spritesheet.get(0, 250, 50, 15, 620),
               spritesheet.get(1, 265, 50, 950, 620),
               spritesheet.get(2, 1215, 50, 15, 620)]
    sprites.each { |sprite| args.outputs.sprites << sprite }
  end

  def construct_sidebar_sprite(args, spritesheet)
    sprites = [spritesheet.get(0, 0, 0, 5, 720),
               spritesheet.get(1, 5, 0, 195, 720),
               spritesheet.get(2, 195, 0, 5, 720)]
    sprites.each { |sprite| args.outputs.sprites << sprite }
  end

  # Use grass data to construct sprites from spritesheet. Adjust spritesheet value based on frame count.
  def display_grass_sprites(args)
    sprites = UIHelpers.construct_grid_sprites(@grass_data, args.state.boot.ui_manager.spritesheets.grass, (300...1200), (50...630))
    sprites.each { |sprite| args.outputs.sprites << sprite }
    @grass_data = UIHelpers.animate_sprites(@grass_data, args.state.boot.ui_manager.frame, 100)
  end

  def display_selection(args)
    shed = args.state.game_state.shed
    args.outputs.sprites << shed.inventory[shed.selection].get_key_frame([130, 180, 25, 25])
  end

  def display_images(args)
    display_grass_sprites(args)
    construct_soil_sprite(args, args.state.boot.ui_manager.spritesheets.soil)
    construct_sidebar_sprite(args, args.state.boot.ui_manager.spritesheets.sidebar)
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
