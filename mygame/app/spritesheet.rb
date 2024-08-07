# frozen_string_literal: true

# Read spritesheets and split sprites
class Spritesheet

  attr_accessor :path, :index, :sprite_h, :sprite_w, :num_tiles, :tiles

  def initialize(path, width, height, num_tiles)
    @path = path
    @index = 0
    @sprite_h = height
    @sprite_w = width
    @num_tiles = num_tiles
    @tiles = {}
    split_tiles
  end

  def get(tile_num, x_coord, y_coord, width, height)
    {
      path: @path,
      source_w: @tiles[tile_num].w,
      source_h: @tiles[tile_num].h,
      source_x: @tiles[tile_num].x,
      source_y: @tiles[tile_num].y,
      x: x_coord,
      y: y_coord,
      w: width,
      h: height,
      a: 255
    }
  end

  private

  def split_tiles
    i = 0
    while @tiles.length < @num_tiles
      @tiles[i] = { x: i * @sprite_w, y: 0, w: @sprite_w, h: @sprite_h }
      i += 1
    end
    @tiles
  end

  # DragonRuby required methods
  def serialize
    { path: @path, index: @index, sprite_h: @sprite_h, sprite_w: @sprite_w, num_tiles: @num_tiles, tiles: @tiles }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
