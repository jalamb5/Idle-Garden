# frozen_string_literal: true

# Read spritesheets and split sprites
class Spritesheet
  def initialize(path, height, width, num_tiles)
    @path = path
    @index = 0
    @sprite_h = height
    @sprite_w = width
    @num_tiles = num_tiles
    @tiles = split_tiles
  end

  def display(args, tile_num, x_coord, y_coord)
    args.outputs.sprites << {
      path: @path,
      tile_w: @tiles[tile_num].w,
      tile_h: @tiles[tile_num].h,
      tile_x: @tiles[tile_num].x,
      tile_y: @tiles[tile_num].y,
      x: x_coord,
      y: y_coord,
      w: @sprite_w,
      h: @sprite_h
    }
  end

  private

  def split_tiles
    tiles = {}
    i = 0
    while tiles.length < @num_tiles
      tiles[i] = { x: i * @sprite_w, y: 0, w: @sprite_w, h: @sprite_h }
      i += 1
    end
    tiles
  end
end
