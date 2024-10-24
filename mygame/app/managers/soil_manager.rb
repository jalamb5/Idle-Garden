# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/ui_helpers.rb'
require 'app/soil.rb'
require 'app/spritesheet.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Construct and Manage soil plots
class SoilManager
  attr_accessor :spritesheets, :soil_plots

  def initialize
    @soil_plots = constuct_soil_plots
    @spritesheets = { soil: Spritesheet.new('sprites/soil_plot.png', 10, 10, 3),
                      fertilizer: Spritesheet.new('sprites/fertilizer.png', 64, 64, 1) }
  end

  def tick(args)
    return if args.state.game_state.shed.open || args.state.game_state.paused

    display_soil_plots(args)
    return unless args.inputs.mouse.click && args.state.game_state.shed.selection == :fertilizer

    apply_fertilizer(args, find_plot(args, args.inputs.mouse.x, args.inputs.mouse.y))
  end

  # rubocop:disable Naming/MethodParameterName
  # Return a soil plot if it intersects specified coordinates
  def find_plot(args, x, y)
    @soil_plots.each do |plot|
      next unless args.geometry.intersect_rect?(
        [plot.square.x, plot.square.y, plot.square.plot_size, plot.square.plot_size],
        [x, y, plot.square.plot_size, plot.square.plot_size]
      )

      return plot
    end
  end
  # rubocop:enable Naming/MethodParameterName

  def reconstruct(save_data)
    return unless save_data.soil_manager

    old_plots = save_data.soil_manager.soil_plots

    attributes = %i[tile]

    @soil_plots.each_with_index do |plot, i|
      attributes.each do |attr|
        plot.send("#{attr}=", old_plots[i].send(attr))
      end
      plot
    end
  end

  private

  def constuct_soil_plots
    plots = []
    soil_grid = UIHelpers.screen_grid_generator(10, 250...1230, 50...670, 0..1, 1)
    soil_grid.each { |square| plots << Soil.new(square) }
    plots
  end

  def display_soil_plots(args)
    @soil_plots.each do |plot|
      plot.update_sprite(args)
      args.outputs.sprites << plot.sprite
    end
  end

  def apply_fertilizer(args, plot)
    return if plot.nil? || args.state.game_state.shed.inventory[:fertilizer].quantity.zero?

    plot.improve
    args.state.game_state.shed.inventory[:fertilizer].quantity -= 1
  end
end
