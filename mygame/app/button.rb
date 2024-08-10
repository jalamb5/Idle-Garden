# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/automation.rb'
require 'app/game.rb'
require 'app/labels.rb'
require 'app/alert.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Create buttons
class Button
  attr_accessor :entity

  COLORS = {
    default: [200, 213, 185, 250],
    opaque: [255, 255, 204, 250],
    clear: [0, 0, 0, 0]
  }.freeze

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
        [@x + 2, @y + 1, @width - 4, @height - 2, COLORS[color]].solid,
        { x: @x + 5, y: @y + 30, text: @text, size_enum: -4, alignment_enum: 0, vertical_alignment_enum: 1 }.label!,
        unless color == :clear
          { x: @x + 2, y: @y + 1, w: @width - 4, h: @height - 2, r: 0, g: 0, b: 0, a: 80 }.border!
        end
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
      play_button_sound(sell(args), args)
    when :buy_seed
      play_button_sound(buy_seed(args), args)
    when :auto_harvester
      play_button_sound(buy_auto_harvester(args), args)
    when :auto_seller
      play_button_sound(buy_auto_seller(args), args)
    when :auto_planter
      play_button_sound(buy_auto_planter(args), args)
    when :start
      args.state.startup.splash_state = false
      play_button_sound(true, args)
    when :save
      play_button_sound(save(args), args)
    when :load_save
      load_save(args)
      args.state.startup.splash_state = false
    when :pause
      pause_game(args)
    when :mute
      args.audio[:music][:gain] = args.audio[:music][:gain].zero? ? 0.25 : 0
    when :quit
      $gtk.request_quit
    else
      false
    end
  end

  # Display tooltips on hover
  def hover?(args)
    return false unless args.inputs.mouse.point.inside_rect?(@entity[:rect])

    tooltips = args.gtk.parse_json_file('data/tooltips.json')
    y_location = args.grid.h - 180
    tooltips[@name.to_s].each { |string| args.state.game_state.alerts << Alert.new(string, y_location, true) }
  end

  private

  def sell(args)
    return false if args.state.game_state.harvested_plants <= 0

    args.state.game_state.cash += args.state.game_state.harvested_plants * args.state.game_state.price[:plant]
    args.state.game_state.score += args.state.game_state.harvested_plants * 10
    args.state.game_state.harvested_plants = 0
    true
  end

  def buy_seed(args)
    return false if (args.state.game_state.cash - args.state.game_state.price[:seed]).negative?

    args.state.game_state.seeds += 1
    args.state.game_state.cash -= args.state.game_state.price[:seed]
    true
  end

  def buy_auto_harvester(args)
    return false if (args.state.game_state.cash - args.state.game_state.price[:harvester]).negative?

    args.state.game_state.auto_harvesters << Automation.new(:harvester)
    args.state.game_state.cash -= args.state.game_state.price[:harvester]
    true
  end

  def buy_auto_seller(args)
    return false if (args.state.game_state.cash - args.state.game_state.price[:seller]).negative?

    args.state.game_state.auto_sellers << Automation.new(:seller)
    args.state.game_state.cash -= args.state.game_state.price[:seller]
    true
  end

  def buy_auto_planter(args)
    return false if (args.state.game_state.cash - args.state.game_state.price[:planter]).negative?

    args.state.game_state.auto_planters << Automation.new(:planter)
    args.state.game_state.cash -= args.state.game_state.price[:planter]
    true
  end

  # Saves the state of the game in a text file called game_state.txt
  def save(args)
    $gtk.serialize_state('game_state.txt', args.state.game_state)
  end

  def load_save(args)
    # return nil unless File.exist?('game_state.txt')
    args.state.game_state = Game.new(args)
    data = $gtk.deserialize_state('game_state.txt')
    data.each_key { |key| args.state.game_state.send("#{key}=", data[key]) }
    args.state.game_state.send('loaded_from_save=', true)
    args.state.game_state.send('paused=', false)
  end

  def pause_game(args)
    args.state.game_state.paused == true ? (args.state.game_state.paused = false) : (args.state.game_state.paused = true)
  end

  def play_button_sound(type, args)
    args.outputs.sounds << (if type == true
                              { input: 'sounds/button_click.wav',
                                gain: 0.25 }
                            else
                              'sounds/button_reject.wav'
                            end)
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
