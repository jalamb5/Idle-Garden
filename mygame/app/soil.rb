# frozen_string_literal: true

# Handle soil plots
class Soil
  attr_reader :sprite, :square
  attr_accessor :tile

  def initialize(data)
    @square = squarify(data)
    @sprite = nil
    @tile = 2 # 0 = low, 1 = med, 2 = high fertility
  end

  def update_sprite(args)
    @sprite = args.state.game_state.soil_manager.spritesheets.soil.get(@tile, @square.x, @square.y, @square.plot_size, @square.plot_size)
  end

  def degrade
    return if @tile.zero?

    @tile -= 1
  end

  def improve
    return false if @tile == 2

    @tile += 1
  end

  private

  # Transform square to Struct
  Square = Struct.new(:sheet, :x, :y, :plot_size)
  def squarify(data)
    Square.new(data[0], data[1], data[2], data[3])
  end

  # DragonRuby required methods
  def serialize
    { tile: @tile }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
