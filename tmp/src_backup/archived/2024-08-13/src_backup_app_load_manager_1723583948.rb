# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/game.rb'
require 'app/ui_manager.rb'
require 'app/plant_manager.rb'
require 'app/automation_manager.rb'
require 'app/levels.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Reconstruct game objects from save data
class LoadManager
  attr_accessor :loaded_from_save
  def initialize
    @loaded_from_save = true
  end
  def load_save(args)
    args.state.game_state = Game.new(args)
    save_data = $gtk.deserialize_state('game_state.txt')
    # save_data.each_key { |key| args.state.game_state.send("#{key}=", data[key]) }
    # args.state.game_state.send('loaded_from_save=', true)
    # reconstruct_objects(args, args.state.game_state, save_data)
    # args.state.game_state.send('paused=', false)
  end

  private

  def reconstruct_objects(args, game_state, save_data)
    game_state.harvested_plants = save_data[:harvested_plants]
    game_state.cash = save_data[:cash]
    game_state.score = save_data[:score]
    game_state.automations.auto_harvesters = save_data[:automations][:auto_harvesters]
    game_state.automations.auto_planters = save_data[:automations][:auto_planters]
    game_state.automations.auto_sellers = save_data[:automations][:auto_sellers]
    game_state.automations.reconstruct
    game_state.plant_manager.plants = save_data[:plant_manager][:plants]
    game_state.plant_manager.seeds = save_data[:plant_manager][:seeds]
    game_state.plant_manager.reconstruct(args)

    @loaded_from_save = false
  end
end
