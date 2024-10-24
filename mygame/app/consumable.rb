# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/spritesheet.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Handle consumables
class Consumable
  attr_reader :type, :spritesheet, :key_frame
  attr_accessor :quantity, :bonus

  SPRITESHEETS = {
    flower_red: {
      path: 'sprites/flower_red_64x64.png',
      w: 64,
      h: 64,
      frames: 56,
      key_frame: 30
    },
    flower_blue: {
      path: 'sprites/flower_blue_64x64.png',
      w: 64,
      h: 64,
      frames: 56,
      key_frame: 30
    },
    fertilizer: {
      path: 'sprites/fertilizer.png',
      w: 64,
      h: 64,
      frames: 1,
      key_frame: 0
    }
  }

  def initialize(type, quantity = 1)
    @type = type
    @spritesheet = Spritesheet.new(SPRITESHEETS[type][:path], SPRITESHEETS[type][:w], SPRITESHEETS[type][:h], SPRITESHEETS[type][:frames])
    @key_frame = SPRITESHEETS[type][:key_frame]
    @quantity = quantity
    @bonus = 0
  end

  def get_key_frame(location)
    @spritesheet.get(@key_frame, location[0], location[1], location[2], location[3])
  end
end
