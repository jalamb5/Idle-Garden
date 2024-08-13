# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/plant.rb'
require 'app/spritesheet.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

class PlantManager
  attr_accessor :plants, :seeds
  def initialize
    @plants = []
    @spritesheets = build_spritesheets
    @garden = { x: 250, y: 50, w: 980, h: 620 }
    @seeds = 5
  end

  def tick(args)
    plant_harvest(args)
    manage_plants(args)
    display_plants(args)
  end

  private

  def build_spritesheets
    [Spritesheet.new('sprites/flower_red_64x64.png', 64, 64, 56),
     Spritesheet.new('sprites/flower_blue_64x64.png', 64, 64, 56)]
  end

  def plant_harvest(args)
    return unless args.inputs.mouse.click && args.inputs.mouse.point.inside_rect?(@garden)

    sheet = [0, 1].sample
    new_plant = Plant.new(args, sheet)

    return unless @seeds.positive? && !new_plant.invalid

    @plants << new_plant
    @seeds -= 1
  end

  def manage_plants(args)
    @plants.reject!(&:invalid)
    @plants.each { |plant| plant.grow(args) }
  end

  def display_plants(args)
    @plants.each do |plant|
      args.outputs.sprites << plant.sprite
    end
  end

  # DragonRuby required methods
  def serialize
    { plants: @plants }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
