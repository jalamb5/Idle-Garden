# frozen_string_literal: true

# Create buttons
class Button
  attr_accessor :entity

  def initialize(name, x_coord, y_coord, text, args, width = 100, height = 50)
    @name = name
    @x = x_coord
    @y = y_coord
    @text = text
    @width = width
    @height = height
    @var_name = "#{@name}_button"
    @entity = {
      id: @name,
      rect: { x: @x, y: @y, w: @width, h: @height },
      primitives: [
        { x: @x, y: @y, w: @width, h: @height }.border!,
        { x: @x + 5, y: @y + 30, text: @text, size_enum: -4 }.label!,
        [ @x + 1, @y + 1, @width - 2, @height - 2, 88, 62, 35, 60].solid
      ]
    }
  end

  # show button on screen
  def display(args)
    args.outputs.primitives << @entity[:primitives]
  end

  # helper method for determining if a button was clicked
  def clicked?(args)
    return false unless args.inputs.mouse.click

    args.inputs.mouse.point.inside_rect? @entity[:rect]
    args.outputs.sounds << 'sounds/button_click.wav' if args.mouse.point.inside_rect?(@entity[:rect])
  end

  private

  # DragonRuby required methods
  def serialize
    { entity: @entity }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
