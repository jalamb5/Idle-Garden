# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/labels.rb'
require 'app/button.rb'
require 'app/ui_helpers.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Manage display and updating of UI elements for boot/splash screen
class BootUIBuilder

  def initialize
    @title_frame = 0
    @grass_data = UIHelpers.screen_grid_generator(50, 0...1280, 0...720, 0..11, 2)
    @frame = 0
  end

  def tick(args)
    splash(args)
    @frame += 1
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

  # Copied from UI Manager - TODO: Refactor


  # Use grass data to construct sprites from spritesheet. Adjust spritesheet value based on frame count.
  def construct_grass_sprite(args)
    spritesheet = args.state.boot.ui_manager.spritesheets.grass
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
    sprites = construct_grass_sprite(args)
    sprites.each { |sprite| args.outputs.sprites << sprite }
  end

  def display_title_sprite(args)
    # Animate sprite
    @title_frame = @title_frame.zero? ? 1 : 0 if (@frame % 100).zero?
    # Display sprite
    args.outputs.sprites << args.state.boot.ui_manager.spritesheets.title_sprites.get(@title_frame, 350, 500, 600, 200)
  end
end
