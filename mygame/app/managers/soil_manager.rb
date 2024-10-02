# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/ui_helpers.rb'
require 'app/soil.rb'
require 'app/spritesheet.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Construct and Manage soil plots
class SoilManager
  attr_accessor :spritesheet, :soil_plots

  def initialize
    @soil_plots = constuct_soil_plots
    @spritesheet = Spritesheet.new('sprites/soil_plot.png', 10, 10, 3)
  end

  def tick(args)
    display_soil_plots(args) unless args.state.game_state.shed.open || args.state.game_state.paused
  end

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
end
