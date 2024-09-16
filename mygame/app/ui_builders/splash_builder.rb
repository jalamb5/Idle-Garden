# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/ui_helpers.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

class SplashBuilder
  def initialize
    @title_frame = 0
    @grass_data = UIHelpers.screen_grid_generator(50, 0...1280, 0...720, 0..11, 2)
  end

  def tick(args)
    display_grass_sprites(args)
    display_title_sprite(args)
  end

  private

  def display_grass_sprites(args)
    sprites = UIHelpers.construct_grid_sprites(@grass_data, args.state.boot.ui_manager.spritesheets.grass)
    sprites.each { |sprite| args.outputs.sprites << sprite }
    @grass_data = UIHelpers.animate_sprites(@grass_data, args.state.boot.ui_manager.frame, 100)
  end

  def display_title_sprite(args)
    # Animate sprite
    @title_frame = @title_frame.zero? ? 1 : 0 if (args.state.boot.ui_manager.frame % 100).zero?
    # Display sprite
    args.outputs.sprites << args.state.boot.ui_manager.spritesheets.title_sprites.get(@title_frame, 350, 500, 600, 200)
  end
end
