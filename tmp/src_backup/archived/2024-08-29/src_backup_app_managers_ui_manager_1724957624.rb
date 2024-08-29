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
      { x: 200, y: 0, w: 1080, h: 720, path: 'sprites/grass_background.png' },
      { x: 250, y: 50, w: 980, h: 620, path: 'sprites/background.png' },
      { x: 170, y: args.grid.h - 30, w: 24, h: 24, path: 'sprites/pause_icon.png' },
      { x: 100, y: 175, w: 50, h: 50, path: 'sprites/selection_box.png' }
    ]
    @label_details = { score: ['Score:', args.state.game_state.score, 23, [240, 30, 30, 255]],
                       seed: ['Seeds:', args.state.game_state.plant_manager.seeds],
                       growing: ['Growing:', args.state.game_state.plant_manager.plants.length],
                       cash: ['Cash:', args.state.game_state.cash],
                       level: ['Level:', args.state.game_state.level.current_level] }
    @labels = generate_labels(args)
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

  def generate_buttons(args, game)
    {
      pause_game: Button.new(:pause_game, [170, args.grid.h - 30], '', [30, 30], :clear),
      # buy_seed: Button.new(:buy_seed, [0, 50], "Seed (#{game.price[:seed]})"),
      # sell: Button.new(:sell, [0, 0], 'Sell', [200, 50]),
      shed: Button.new(:shed, [0, 150], '', [100, 100], :clear)
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

  def display_images(args)
    plant_spritesheets = args.state.game_state.plant_manager.spritesheets
    @images.each { |image| args.outputs.sprites << image }
    args.outputs.sprites << plant_spritesheets[args.state.game_state.plant_manager.selection].get(30, 120, 180, 25, 25)
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
