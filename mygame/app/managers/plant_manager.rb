# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/plant.rb'
require 'app/spritesheet.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Manage growth and placement of plants
class PlantManager
  attr_accessor :plants, :seeds, :spritesheets, :selection, :block_plant

  def initialize
    @plants = []
    @spritesheets = build_spritesheets
    @garden = { x: 250, y: 50, w: 980, h: 620 }
    @seeds = { flower_red: 5, flower_blue: 0 }
    @selection = :flower_red
    @block_plant = false
  end

  def tick(args)
    plant_harvest(args)
    manage_plants(args)
    display_plants(args) unless args.state.game_state.shed.open || args.state.game_state.paused
  end

  def reconstruct(args)
    return if @plants.empty?

    attributes = %i[x y w h age stage a frame sheet]

    @plants.map! do |plant|
      new_plant = Plant.new(args, :flower_red, 0, 0)
      attributes.each do |attr|
        new_plant.send("#{attr}=", plant.send(attr))
      end
      new_plant
    end
  end

  private

  def build_spritesheets
    { flower_red: Spritesheet.new('sprites/flower_red_64x64.png', 64, 64, 56),
      flower_blue: Spritesheet.new('sprites/flower_blue_64x64.png', 64, 64, 56) }
  end

  def plant_harvest(args)
    return unless args.inputs.mouse.click && args.inputs.mouse.point.inside_rect?(@garden)

    # Randomly select plant type
    # sheet = %i[flower_red flower_blue].sample
    new_plant = Plant.new(args, @selection, args.inputs.mouse.x, args.inputs.mouse.y)

    return unless @seeds[@selection].positive? && !new_plant.invalid

    @plants << new_plant
    @seeds[@selection] -= 1
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
    { plants: @plants, seeds: @seeds, selection: @selection }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
