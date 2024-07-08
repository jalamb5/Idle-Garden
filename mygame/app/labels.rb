# frozen_string_literal: true

# Create labels to display information
class Labels
  attr_accessor :x, :y, :text, :value, :size_px

  def initialize(x_coord, y_coord, text, value, size_px = 22)
    @x = x_coord
    @y = y_coord
    @text = text
    @value = value
    @size_px = size_px
  end

  def display(args)
    args.outputs.labels << { x: @x, y: @y, text: "#{@text}: #{@value}", size_px: @size_px }
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
