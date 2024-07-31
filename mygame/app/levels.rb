# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/game.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Manage levels
class Levels
  attr_accessor :current_level

  def initialize(current_level = 1)
    @current_level = current_level
  end

  def update(level)
    @current_level = level
  end


  # DragonRuby required methods
  def serialize
    { current_level: @current_level }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
