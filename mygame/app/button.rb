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
    sell: ->(args, type) { ButtonActions.sell(args, type) },
    buy: ->(args, type) { ButtonActions.buy(args.state.game_state, type) },
    select: ->(args, type) { ButtonActions.select(args.state.game_state, type) },
    buy_auto_harvester: ->(args, _type) { ButtonActions.buy_auto_harvester(args) },
    buy_auto_seller: ->(args, _type) { ButtonActions.buy_auto_seller(args) },
    buy_auto_planter: ->(args, _type) { ButtonActions.buy_auto_planter(args) },
    shed: ->(args, _type) { ButtonActions.shed(args) },
    save: ->(args, _type) { ButtonActions.save(args) },
    load_save: ->(args, _type) { ButtonActions.load_save(args.state) },
    pause_game: ->(args, _type) { ButtonActions.pause_game(args.state.game_state) },
    start: ->(args, _type) { ButtonActions.start(args.state.boot) },
    mute_music: ->(args, _type) { ButtonActions.mute_music(args) },
    mute_sfx: ->(args, _type) { ButtonActions.mute_sfx(args.state.boot.sound_manager) },
    quit: ->(_args, _type) { ButtonActions.quit }
  }.freeze

  def initialize(name, coords, text, size = [100, 50], color = :default, type = nil)
    @name = name
    @x = coords[0]
    @y = coords[1]
    @text = text
    @width = size[0]
    @height = size[1]
    @color = COLORS[color]
    @type = type
    @border = true unless color == :clear
    @entity = construct_entity
  end

  # show button on screen
  def display(args)
    args.outputs.primitives << @entity[:primitives]
    button_sprites = construct_button_sprite(args) unless @color == COLORS[:clear]
    button_sprites&.each { |sprite| args.outputs.sprites << sprite }
  end

  # helper method for determining if a button was clicked
  def clicked?(args)
    return false unless args.inputs.mouse.click && args.inputs.mouse.point.inside_rect?(@entity[:rect])

    result = BUTTON_ACTIONS[@name]&.call(args, @type)
    play_button_sound(result, args)
  end

  # Display tooltips on hover
  def hover?(args)
    return false unless args.inputs.mouse.point.inside_rect?(@entity[:rect])

    tooltips = args.gtk.parse_json_file('data/tooltips.json')
    key = "#{@name}#{@type}"
    args.state.boot.ui_manager.game_ui.alerts << Alert.new(tooltips[key], hover: true)
  end

  private

  def construct_entity
    {
      id: @name,
      rect: { x: @x, y: @y, w: @width, h: @height },
      primitives: [
        { x: @x + 5, y: @y + 30, text: @text, size_enum: -4, alignment_enum: 0, vertical_alignment_enum: 2,
          font: 'fonts/Tiny5.ttf' }.label!
      ]
    }
  end

  def construct_button_sprite(args)
    # Determine width of text label
    w, _h = args.gtk.calcstringbox(@text, -4, 'fonts/Tiny5.ttf')

    # Round label width to the nearest multiple of 30 to standardize button sizes
    middle = ((w.to_i + 5) / 30.0).ceil * 30
    spritesheet = args.state.boot.ui_manager.spritesheets.button_sprites
    [spritesheet.get(0, @x, @y, 5, @height),
     spritesheet.get(1, @x + 5, @y, middle, @height),
     spritesheet.get(2, @x + middle + 5, @y, 5, @height)]
  end

  def play_button_sound(type, args)
    sound = type ? :button_click : :button_reject
    args.state.boot.sound_manager.play_effect(sound, args)
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
