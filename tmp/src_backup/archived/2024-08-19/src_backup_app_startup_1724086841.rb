# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/game.rb'
require 'app/button.rb'
require 'app/managers/sound_manager.rb'
require 'app/labels.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Handle splash screen and start / load game
class Startup
  attr_accessor :splash_state, :sound_manager

  def initialize(args)
    @splash_state = true
    @tutorial = true
    @sound_manager = SoundManager.new
    @sound_manager.play_music(:garden_melody, args)
  end

  def tick(args)
    if @splash_state
      splash(args)
    else
      args.state.game_state ||= Game.new(args)
      args.state.game_state.tick(args)
      show_tutorial(args) if @tutorial
    end
  end

  private

  def splash(args)
    args.outputs.sprites << { x: 0, y: 0, w: 1280, h: 720, path: 'sprites/splash.png' }
    args.state.start_button ||= Button.new(:start, [540, 360], 'Start', [200, 50], :opaque)
    args.state.start_button.display(args)
    args.state.start_button.clicked?(args)
    args.state.load_save_button ||= Button.new(:load_save, [540, 260], 'Load Save', [200, 50], :opaque)
    args.state.load_save_button.display(args)
    args.state.load_save_button.clicked?(args)
  end

  def show_tutorial(args)
    labels = []
    coords = [350, 500]
    intro_message = ['Welcome to Idle Garden!',
                     'You have 5 seeds and 5 cash to start out.',
                     'Click in the soil to plant seeds.',
                     'When your seeds have matured you can click to harvest them.',
                     'Flowers can be sold for cash while withered plants may provide addtional seeds.',
                     'As you level up, you can hire helpers to manage your garden for you.',
                     'Happy Gardening!',
                     'Press SPACE to continue.']
    # Primitives render above solids
    args.outputs.primitives << { x: 100, y: 100, w: 1080, h: 520, r: 0, g: 0, b: 0, a: 155, primitive_marker: :solid, blend }
    intro_message.each do |message|
      labels << Labels.new(coords[0], coords[1], '', message, 20, [255, 255, 255, 255])
      coords[1] -= 40
    end
    labels.each { |label| label.display(args) }
    @tutorial = false if args.inputs.keyboard.key_down.space
  end

  # DragonRuby required methods
  def serialize
    { splash_state: @splash_state }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
