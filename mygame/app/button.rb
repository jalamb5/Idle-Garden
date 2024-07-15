# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/automation.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Create buttons
class Button
  attr_accessor :entity

  COLORS = {
    default: [88, 62, 35, 60],
    opaque: [255, 255, 204, 250]
  }

  def initialize(name, x_coord, y_coord, text, width = 100, height = 50, color = :default)
    @name = name
    @x = x_coord
    @y = y_coord
    @text = text
    @width = width
    @height = height
    @entity = {
      id: @name,
      rect: { x: @x, y: @y, w: @width, h: @height },
      primitives: [
        [ @x + 1, @y + 1, @width - 2, @height - 2, COLORS[color]].solid,
        { x: @x, y: @y, w: @width, h: @height }.border!,
        { x: @x + 5, y: @y + 30, text: @text, size_enum: -4 }.label!
      ]
    }
  end

  # show button on screen
  def display(args)
    args.outputs.primitives << @entity[:primitives]
  end

  # helper method for determining if a button was clicked
  def clicked?(args)
    return false unless args.inputs.mouse.click && args.inputs.mouse.point.inside_rect?(@entity[:rect])

    case @name
    when :sell
      sell(args)
    when :buy_seed
      buy_seed(args)
    when :auto_harvester
      buy_auto_harvester(args)
    when :auto_seller
      buy_auto_seller(args)
    when :auto_planter
      buy_auto_planter(args)
    when :start
      args.state.game_state.splash_state = false
    when :save
      save(args)
    else
      false
    end
  end

  private

  def sell(args)
    return if args.state.game_state.harvested_plants.negative?

    args.outputs.sounds << 'sounds/button_click.wav'
    args.state.game_state.cash += args.state.game_state.harvested_plants * args.state.game_state.price[:plant]
    args.state.game_state.harvested_plants = 0
  end

  def buy_seed(args)
    return if (args.state.game_state.cash - args.state.game_state.price[:seed]).negative?

    args.outputs.sounds << 'sounds/button_click.wav'
    args.state.game_state.seeds += 1
    args.state.game_state.cash -= args.state.game_state.price[:seed]
  end

  def buy_auto_harvester(args)
    return if (args.state.game_state.cash - args.state.game_state.price[:harvester]).negative?

    args.outputs.sounds << 'sounds/button_click.wav'
    args.state.game_state.auto_harvesters << Automation.new(:harvester)
    args.state.game_state.cash -= args.state.game_state.price[:harvester]
  end

  def buy_auto_seller(args)
    return if (args.state.game_state.cash - args.state.game_state.price[:seller]).negative?

    args.outputs.sounds << 'sounds/button_click.wav'
    args.state.game_state.auto_sellers << Automation.new(:seller)
    args.state.game_state.cash -= args.state.game_state.price[:seller]
  end

  def buy_auto_planter(args)
    return if (args.state.game_state.cash - args.state.game_state.price[:planter]).negative?

    args.outputs.sounds << 'sounds/button_click.wav'
    args.state.game_state.auto_planters << Automation.new(:planter)
    args.state.game_state.cash -= args.state.game_state.price[:planter]
  end

  # Saves the state of the game in a text file called game_state.txt
  def save(state)
    $gtk.serialize_state('game_state.txt', state)
  end

  # DragonRuby required methods
  def serialize
    { entity: @entity }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
