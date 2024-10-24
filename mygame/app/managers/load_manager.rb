# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/game.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Reconstruct game objects from save data
class LoadManager
  attr_accessor :loaded_from_save

  def initialize
    @loaded_from_save = true
  end

  def load_save(args)
    args.state.game_state = Game.new
    saved_state = $gtk.deserialize_state('game_state.txt')
    reconstruct_objects(args, args.state.game_state, saved_state)
  end

  private

  def reconstruct_objects(args, game_state, saved_state)
    set_volume(args, saved_state)
    args.state.boot.tutorial = saved_state.save_data.tutorial
    game_state.cash = saved_state[:cash]
    game_state.score = saved_state[:score]
    game_state.soil_manager.reconstruct(saved_state)
    set_harvested_plants(game_state, saved_state[:harvested_plants])
    reconstruct_automations(args, game_state, saved_state)
    reconstruct_plants(args, game_state, saved_state)

    @loaded_from_save = false
  end

  def set_volume(args, saved_state)
    args.state.boot.sound_manager.sfx_gain = saved_state.save_data.sfx_gain
    args.state.boot.sound_manager.music_gain = saved_state.save_data.music_gain
    args.audio[:music][:gain] = saved_state.save_data.music_gain
  end

  def set_harvested_plants(game_state, harvested_plants)
    return if harvested_plants.nil?

    harvested_plants.each do |key, value|
      game_state.shed.harvested_plants[key] = value
    end
  end

  def reconstruct_automations(args, game_state, saved_state)
    game_state.automations.auto_harvesters = saved_state[:automations][:auto_harvesters]
    game_state.automations.auto_planters = saved_state[:automations][:auto_planters]
    game_state.automations.auto_sellers = saved_state[:automations][:auto_sellers]
    game_state.automations.reconstruct(args)
  end

  def reconstruct_plants(args, game_state, saved_state)
    game_state.plant_manager.plants = saved_state[:plant_manager][:plants]
    game_state.plant_manager.seeds = saved_state[:plant_manager][:seeds]
    game_state.plant_manager.reconstruct(args)
  end
end
