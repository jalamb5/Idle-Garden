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
  attr_accessor :splash_state, :sound_manager, :tutorial, :button_sprites

  def initialize(args)
    @splash_state = true
    @tutorial = true
    @sound_manager = SoundManager.new
    @sound_manager.play_music(:garden_melody, args)
    @button_sprites = Spritesheet.new('sprites/button.png', 5, 64, 3)
    @title_sprites = Spritesheet.new('sprites/title.png', 600, 200, 2)
    @title_frame = 0
    @grass_data = generate_grass_data
    @frame = 0
  end

  def tick(args)
    if @splash_state
      splash(args)
      @frame += 1
    else
      args.state.game_state ||= Game.new(args)
      args.state.game_state.tick(args)
      show_tutorial(args) if @tutorial
    end
  end

  private

  def splash(args)
    display_grass_sprites(args)
    display_title_sprite(args)
    args.state.start_button ||= Button.new(:start, [540, 360], 'Start', [200, 50], :opaque)
    args.state.start_button.display(args)
    args.state.start_button.clicked?(args)
    args.state.load_save_button ||= Button.new(:load_save, [540, 260], 'Load Save', [200, 50], :opaque)
    args.state.load_save_button.display(args)
    args.state.load_save_button.clicked?(args)
  end

  def show_tutorial(args)
    args.state.game_state.block_click = true
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

  # Copied from UI Manager - TODO: Refactor

  # Create arrays for each 50x50 segment of grass with randomized spritesheet value
  def generate_grass_data
    data = []

    (0...1280).each do |x|
      next unless (x % 50).zero?

      (0...720).each do |y|
        next unless (y % 50).zero?

        data << [(0..11).select(&:even?).sample, x, y, 50, 50]
      end
    end

    data
  end

  # Use grass data to construct sprites from spritesheet. Adjust spritesheet value based on frame count.
  def construct_grass_sprite
    spritesheet = Spritesheet.new('sprites/garden_grass_simplified.png', 50, 50, 12)
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

  def display_title_sprite(args)
    # Animate sprite
    @title_frame = @title_frame.zero? ? 1 : 0 if (@frame % 100).zero?
    # Display sprite
    args.outputs.sprites << @title_sprites.get(@title_frame, 350, 500, 600, 200)
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
