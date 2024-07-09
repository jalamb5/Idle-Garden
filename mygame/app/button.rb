# frozen_string_literal: true

# Create buttons
class Button
  attr_accessor :entity, :var_name

  def initialize(name, x_coord, y_coord, text, args)
    @width = 100
    @height = 50
    @entity = {
      id: name,
      rect: { x: x_coord, y: y_coord, w: @width, h: @height }
    }

    @entity[:primitives] = [
      { x: x_coord, y: y_coord, w: @width, h: @height }.border!,
      { x: x_coord + 5, y: y_coord + 30, text: text, size_enum: -4 }.label!
    ]

    @var_name = "#{name}_button"

  end

  def display(args)
    args.outputs.primitives << args.state.@var_name[:primitives]
  end

  def update(new_value)
    @value = new_value
  end

  private

  # DragonRuby required methods
  def serialize
    { x: @x, y: @y, text: @text, value: @value, size_px: @size_px }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
