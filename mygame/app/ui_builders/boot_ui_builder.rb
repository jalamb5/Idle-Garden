# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/button.rb'
require 'app/ui_builders/splash_builder.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Manage display and updating of UI elements for boot/splash screen
class BootUIBuilder
  attr_reader :splash_screen

  def initialize
    @splash_screen = SplashBuilder.new
    @buttons = [Button.new(:start, [540, 360], 'Start', [200, 50], :opaque),
                Button.new(:load_save, [540, 260], 'Load Save', [200, 50], :opaque)]
  end

  def tick(args)
    args.state.game_state.plant_manager.block_plant = true
    @splash_screen.tick(args)
    @buttons.each { |button| button.display(args) && button.clicked?(args) }
  end
end
