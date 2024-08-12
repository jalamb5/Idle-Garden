# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/labels.rb'
require 'app/button.rb'
require 'app/alert.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Manage display and updating of UI elements
class UIManager
  attr_accessor :buttons, : :labels, :alerts, :images

  def initialize(args, game)
    @buttons = generate_buttons(args, game)
    @unlocked_buttons = []
    @labels = generate_labels(args, game)
    @alerts = []
    @images = [
      { x: 200, y: 0, w: 1080, h: 720, path: 'sprites/grass_background.png' },
      { x: 250, y: 50, w: 980, h: 620, path: 'sprites/background.png' },
      { x: 170, y: args.grid.h - 30, w: 24, h: 24, path: 'sprites/pause_icon.png' }
    ]
  end

  def tick(args)
    display_sprites(args)

    unlock_buttons
    display_buttons(args)
    display_labels(args)

    monitor_buttons(args)
    update_labels(args)

    handle_alerts(args) if @alerts.any?
  end

  private

  def generate_buttons(args, game)
    {
      pause: Button.new(:pause, 170, args.grid.h - 30, '', 30, 30, :clear),
      buy_seed: Button.new(:buy_seed, 0, 50, "Seed (#{game.price[:seed]})"),
      sell: Button.new(:sell, 0, 0, 'Sell', 200)
    }
  end

  def generate_labels(args, game)
    {
      score: Labels.new(5, args.grid.h, 'Score:', game.score, 23, [240, 30, 30, 255]),
      seed: Labels.new(5, args.grid.h - 20, 'Seeds:', game.seeds),
      growing: Labels.new(5, args.grid.h - 40, 'Growing:', game.plants.length),
      harvested: Labels.new(5, args.grid.h - 60, 'Harvested:', game.harvested_plants),
      cash: Labels.new(5, args.grid.h - 80, 'Cash:', game.cash),
      auto_harvesters: Labels.new(5, args.grid.h - 100, 'Auto Harvesters:', game.auto_harvesters.length),
      auto_planters: Labels.new(5, args.grid.h - 120, 'Auto Planters:', game.auto_planters.length),
      auto_sellers: Labels.new(5, args.grid.h - 140, 'Auto Sellers:', game.auto_sellers.length),
      level: Labels.new(5, args.grid.h - 160, 'Level:', game.level.current_level)
    }
  end

  # Add any unlocked buttons to the full button array and clear the unlocked array
  def unlock_buttons
    @unlocked_buttons.each { |button| @buttons << button }
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

  def display_sprites(args)
    @images.each { |image| args.outputs.sprites << image }
  end

  # DragonRuby required methods
  def serialize
    { buttons: @buttons, labels: @labels, alerts: @alerts, images: @images }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
