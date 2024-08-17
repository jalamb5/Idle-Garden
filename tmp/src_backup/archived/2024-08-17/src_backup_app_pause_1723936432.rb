# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/button.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Manage pause menu
class Pause
  def initialize(args)
    @standard_buttons = pause_buttons
    @mute_buttons = mute_buttons(args)
  end

  def tick(args)
    draw_screen(args)
  end

  private

  def draw_screen(args)
    args.outputs.sprites << { x: 0, y: 0, w: 1280, h: 720, path: 'sprites/splash.png' }
    @standard_buttons.each_value { |button| button.display(args) && button.clicked?(args) }
    @mute_buttons.each_value do |button|
      button.display(args)
      @mute_buttons = mute_buttons(args) if button.clicked?(args)
    end
  end

  def pause_buttons
    {
      unpause: Button.new(:pause, 540, 060, 'Return to Garden', 200, 50, :opaque),
      save: Button.new(:save, 540, 360, 'Save', 200, 50, :opaque),
      quit: Button.new(:quit, 540, 60, 'Quit Game', 200, 50, :opaque)
    }
  end

  def mute_buttons(args)
    {
      mute_sfx: create_mute_button(:mute_sfx, 160, args.state.startup.sound_manager.sfx_gain, 'Unmute Sound Effects',
                                   'Mute Sound Effects'),
      mute_music: create_mute_button(:mute_music, 260, args.state.startup.sound_manager.music_gain, 'Unmute Music',
                                     'Mute Music')
    }
  end

  def create_mute_button(type, y_coord, gain, unmute_label, mute_label)
    label = gain.zero? ? unmute_label : mute_label
    Button.new(type, 540, y_coord, label, 200, 50, :opaque)
  end
end
