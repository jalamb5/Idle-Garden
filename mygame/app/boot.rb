# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/game.rb'
require 'app/button.rb'
require 'app/managers/sound_manager.rb'
require 'app/managers/ui_manager.rb'
require 'app/labels.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Handle splash screen and start / load game
class Boot
  attr_accessor :splash_state, :sound_manager, :tutorial, :button_sprites, :ui_manager

  def initialize(args)
    args.state.game_state ||= Game.new
    @splash_state = true
    @tutorial = true
    @sound_manager = SoundManager.new
    @sound_manager.play_music(:garden_melody, args)
    @ui_manager = UIManager.new(args)
  end

  def tick(args)
    @ui_manager.tick(args)

    return if @splash_state

    args.state.game_state.tick(args)
    show_tutorial(args) if @tutorial
  end

  private

  def show_tutorial(args)
    args.state.game_state.plant_manager.block_plant = true
    labels = []
    coords = [350, 500]
    intro_message = ['Welcome to Idle Garden!',
                     'You have 5 seeds and 5 cash to start out.',
                     'Click in the soil to plant seeds.',
                     'When your seeds have matured you can click to harvest them.',
                     'Flowers can be sold for cash while withered plants may provide addtional seeds.',
                     'Use the shed to store seeds and harvested plants.',
                     'As you level up, you can hire helpers to manage your garden for you.',
                     'Happy Gardening!',
                     'Press SPACE to continue.']
    # Primitives render above solids
    args.outputs.primitives << { x: 100, y: 100, w: 1080, h: 520, r: 0, g: 0, b: 0, a: 155, primitive_marker: :solid }
    intro_message.each do |message|
      labels << Labels.new(coords[0], coords[1], '', message, 20, [255, 255, 255, 255])
      coords[1] -= 40
    end
    labels.each { |label| label.display(args) }
    @tutorial = false && args.state.game_state.save_data[:tutorial] = false if args.inputs.keyboard.key_down.space
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
