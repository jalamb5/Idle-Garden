# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/spritesheet.rb'
require 'app/ui_builders/pause_builder.rb'
require 'app/ui_builders/game_ui_builder.rb'
require 'app/ui_builders/boot_ui_builder.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Manage display and updating of UI elements
class UIManager
  attr_accessor :game_ui, :boot_ui, :spritesheets, :frame

  def initialize(args)
    @boot_ui = BootUIBuilder.new
    @game_ui = GameUIBuilder.new(args)
    @pause_ui = Pause.new
    @frame = 0
    @spritesheets = {
      button_sprites: Spritesheet.new('sprites/button.png', 5, 64, 3),
      title_sprites: Spritesheet.new('sprites/title.png', 600, 200, 2),
      grass: Spritesheet.new('sprites/garden_grass_simplified.png', 50, 50, 12),
      soil: Spritesheet.new('sprites/garden_soil.png', 15, 570, 3),
      sidebar: Spritesheet.new('sprites/sidebar.png', 5, 720, 3)
    }
  end

  def tick(args)
    @frame >= 1000 ? @frame = 0 : @frame += 1

    if args.state.boot.splash_state
      # show startup splash screen
      @boot_ui.tick(args)
    elsif args.state.game_state.paused
      # show pause screen
      @pause_ui.tick(args)
    else
      @game_ui.tick(args)
    end
  end

  private

  # DragonRuby required methods
  def serialize
    { buttons: @buttons, unlocked_buttons: @unlocked_buttons, labels: @labels, alerts: @alerts, images: @images }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
