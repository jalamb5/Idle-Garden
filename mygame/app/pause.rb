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
    args.outputs.solids << { x: 0, y: 0, w: 1280, h: 720, r: 200, g: 213, b: 185, a: 55 }
    @buttons.each_value { |button| button.display(args) && button.clicked?(args) }
  end

  def pause_buttons(_args)
    {
      unpause: Button.new(:pause, 540, 360, 'Close Menu', 200, 50, :opaque),
      save: Button.new(:save, 540, 260, 'Save', 200, 50, :opaque),
      mute: Button.new(:mute, 540, 160, 'Mute/Unmute Music', 200, 50, :opaque)
    }
  end
end
