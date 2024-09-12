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
end
