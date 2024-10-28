# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/button.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Manage pause menu
class Pause
  def tick(args)
    args.state.boot.ui_manager.boot_ui.splash_screen.tick(args)
    pause_buttons(args).each_value { |button| button.display(args) && button.clicked?(args) }
  end

  private

  def pause_buttons(args)
    {
      pause_game: Button.new(:pause_game, [400, 360], 'Return to Garden', [200, 50], :opaque),
      quit: Button.new(:quit, [700, 360], 'Quit Game', [200, 50], :opaque),
      mute_sfx: create_mute_button(:mute_sfx, 400, args.state.boot.sound_manager.sfx_gain, 'Unmute Sound Effects',
                                   'Mute Sound Effects'),
      mute_music: create_mute_button(:mute_music, 700, args.state.boot.sound_manager.music_gain, 'Unmute Music',
                                     'Mute Music')
      # Original Save and Quit for when Save/Load reimplemented.
      # save: Button.new(:save, [700, 360], 'Save', [200, 50], :opaque),
      # quit: Button.new(:quit, [540, 60], 'Quit Game', [200, 50], :opaque),
    }
  end

  def create_mute_button(type, x_coord, gain, unmute_label, mute_label)
    label = gain.zero? ? unmute_label : mute_label
    Button.new(type, [x_coord, 260], label, [200, 50], :opaque)
  end
end
