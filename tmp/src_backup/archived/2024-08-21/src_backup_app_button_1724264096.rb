# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/alert.rb'
require 'app/button_actions.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Create buttons
class Button
  attr_accessor :entity

  COLORS = {
    default: [200, 213, 185, 250],
    opaque: [255, 255, 204, 250],
    clear: [0, 0, 0, 0]
  }.freeze

  BUTTON_ACTIONS = {
    sell: ->(args) { ButtonActions.sell(args.state.game_state) },
    buy_seed: ->(args) { ButtonActions.buy_seed(args.state.game_state) },
    buy_auto_harvester: ->(args) { ButtonActions.buy_auto_harvester(args) },
    buy_auto_seller: ->(args) { ButtonActions.buy_auto_seller(args) },
    buy_auto_planter: ->(args) { ButtonActions.buy_auto_planter(args) },
    save: ->(args) { ButtonActions.save(args) },
    load_save: ->(args) { ButtonActions.load_save(args.state) },
    pause_game: ->(args) { ButtonActions.pause_game(args.state.game_state) },
    start: ->(args) { ButtonActions.start(args.state.startup) },
    mute_music: ->(args) { ButtonActions.mute_music(args) },
    mute_sfx: ->(args) { ButtonActions.mute_sfx(args.state.startup.sound_manager) },
    quit: ->(_args) { ButtonActions.quit }
  }.freeze

  def initialize(name, coords, text, size = [100, 50], color = :default)
    @name = name
    @x = coords[0]
    @y = coords[1]
    @text = text
    @width = size[0]
    @height = size[1]
    @color = COLORS[color]
    @border = true unless color == :clear
    @entity = construct_entity
  end

  # show button on screen
  def display(args)
    args.outputs.primitives << @entity[:primitives]
  end

  # helper method for determining if a button was clicked
  def clicked?(args)
    return false unless args.inputs.mouse.click && args.inputs.mouse.point.inside_rect?(@entity[:rect])

    result = BUTTON_ACTIONS[@name]&.call(args)
    play_button_sound(result, args)
  end

  # Display tooltips on hover
  def hover?(args)
    return false unless args.inputs.mouse.point.inside_rect?(@entity[:rect])

    tooltips = args.gtk.parse_json_file('data/tooltips.json')
    args.state.game_state.ui.alerts << Alert.new(tooltips[@name.to_s], y_coord: (args.grid.h - 180), hover: true)
  end

  private

  def construct_entity
    {
      id: @name,
      rect: { x: @x, y: @y, w: @width, h: @height },
      primitives: [
        [@x + 2, @y + 1, @width - 4, @height - 2, @color].solid,
        { x: @x + 5, y: @y + 30, text: @text, size_enum: -3, alignment_enum: 1, vertical_alignment_enum: 1, font: 'fonts/Tiny5.ttf' }.label!,
        ({ x: @x + 2, y: @y + 1, w: @width - 4, h: @height - 2, r: 0, g: 0, b: 0, a: 80 }.border! if @border)
      ]
    }
  end

  def play_button_sound(type, args)
    sound = type ? :button_click : :button_reject
    args.state.startup.sound_manager.play_effect(sound, args)
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
