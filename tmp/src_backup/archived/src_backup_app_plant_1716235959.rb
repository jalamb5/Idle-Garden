# frozen_string_literal: true

# Create new plants in garden
class Plant
  # attr_accessor :w, :h, :age, :invalid, :path, :a

  def initialize(args)
    @x = args.inputs.mouse.x - 15
    @y = args.inputs.mouse.y - 15
    @w = 20
    @h = 20
    @age = 0
    @invalid = false
    @path = 'sprites/stages/0seed.png'
    @a = 255
  end

  def serialize
    { w: @w, h: @h, x: @x, y: @y, age: @age, invalid: @invalid, path: @path, a: @a }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end

  def occupied(args, new_plant)
    args.state.plants.each do |plant|
      next unless args.geometry.intersect_rect?(plant, new_plant)

      new_plant.invalid = plant
    end
    new_plant
  end
end
