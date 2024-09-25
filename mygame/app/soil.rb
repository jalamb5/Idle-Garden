# frozen_string_literal: true

# Handle soil plots
class Soil
  attr_reader :sprite

  def initialize(square)
    # @sheet = square[0]
    @coords = [square[1], square[2]]
    @plot_size = square[3]
    @sprite = nil
    @fertility = 0
  end

  def update_sprite(args)
    @sprite = args.state.game_state.soil_manager.spritesheet.get(@fertility, @coords[0], @coords[1], @plot_size, @plot_size)
  end
end
