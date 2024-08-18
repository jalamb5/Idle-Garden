# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/game.rb'
require 'app/button.rb'
require 'app/managers/sound_manager.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Handle splash screen and start / load game
class Startup
  attr_accessor :splash_state, :sound_manager

  def initialize(args)
    @splash_state = true
    @sound_manager = SoundManager.new
    @sound_manager.play_music(:garden_melody, args)
  end

  def tick(args)
    if @splash_state
      splash(args)
    else
      args.state.game_state ||= Game.new(args)
      args.state.game_state.tick(args)
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
