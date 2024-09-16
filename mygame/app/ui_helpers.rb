# frozen_string_literal: true

# Functions for building out UI elements
module UIHelpers
  def self.screen_grid_generator(square_size, x_range, y_range, sprite_range, sprite_step)
    grid = []
    starting_sprites = sprite_range.to_a.each_slice(sprite_step).map(&:first)

    x_range.each do |x|
      next unless (x % square_size).zero?

      y_range.each do |y|
        next unless (y % square_size).zero?

        grid << [starting_sprites.sample, x, y, square_size, square_size]
      end
    end
    grid
  end

  def self.construct_grid_sprites(grid, spritesheet, x_limit = [], y_limit = [])
    sprites = []
    grid.each do |square|
      unless x_limit.include?(square[1]) && y_limit.include?(square[2])
        sprites << spritesheet.get(square[0], square[1], square[2], square[3], square[4])
      end
    end
    sprites
  end

  def self.animate_sprites(grid, frame, rate)
    return grid unless (frame % rate).zero?

    grid.each { |square| square[0] = square[0].even? ? square[0] + 1 : square[0] - 1 }
    grid
  end
end
