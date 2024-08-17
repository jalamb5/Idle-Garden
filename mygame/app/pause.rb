# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/button.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Manage pause menu
class Pause
  def initialize(args)
    @buttons = pause_buttons(args)
  end

  def tick(args)
    draw_screen(args)
  end

  private

  def draw_screen(args)
    args.outputs.sprites << { x: 0, y: 0, w: 1280, h: 720, path: 'sprites/splash.png' }
    @buttons.each_value { |button| button.display(args) && button.clicked?(args) }
  end

  def pause_buttons(_args)
    {
      unpause: Button.new(:pause, 540, 360, 'Return to Garden', 200, 50, :opaque),
      save: Button.new(:save, 540, 260, 'Save', 200, 50, :opaque),
      mute_music: Button.new(:mute_music, 540, 160, 'Mute/Unmute Music', 200, 50, :opaque),
      mute_sfx: Button.new(:mute_sfx, 540, 60, 'Mute/Unmute Effects', 200, 50, :opaque),
      quit: Button.new(:quit, 740, 60, 'Quit Game', 200, 50, :opaque)
    }
  end
end
