# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/plant.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Create new automations for garden
class Automation
  attr_accessor :type, :harvest_cooldown, :planter_cooldown, :seller_cooldown

  COOLDOWNS = { harvester: 3, planter: 2, seller: 5 }.freeze

  def initialize(type)
    @type = type
    @cooldown = COOLDOWNS[type]
  end

  def run(args)
    @cooldown -= 1
    case @type
    when :harvester
      auto_harvester(args) if @cooldown <= 0 && args.state.game_state.plant_manager.plants.length.positive?
    when :planter
      auto_planter(args) if @cooldown <= 0 && args.state.game_state.plant_manager.seeds.positive?
    when :seller
      auto_seller(args) if @cooldown <= 0 && args.state.game_state.harvested_plants.positive?
    end
  end

  private

  def auto_harvester(args)
    args.state.game_state.plant_manager.plants.each do |plant|
      next unless plant.stage == 'ready_to_harvest' || plant.stage == 'withered'

      plant.harvest(args, plant)
      @cooldown = rand(15)
      break
    end
  end

  def auto_planter(args)
    x, y = coord_generator
    sheet = %i[flower_red flower_blue].sample
    plant = Plant.new(args, sheet, x, y)
    args.state.game_state.plant_manager.plants << plant
    args.state.game_state.plant_manager.seeds -= 1
    @cooldown = rand(10)
  end

  def coord_generator
    # x 250-980, y 50-620
    x = rand(980)
    x += 250 if x < 250
    y = rand(620)
    y += 50 if y < 50
    [x, y]
  end

  def auto_seller(args)
    args.state.game_state.cash += args.state.game_state.harvested_plants * args.state.game_state.price[:plant]
    args.state.game_state.score += args.state.game_state.harvested_plants * 10
    args.state.game_state.harvested_plants = 0
    @cooldown = rand(10)
  end

  # DragonRuby required methods
  def serialize
    { type: @type, cooldown: @cooldown }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
