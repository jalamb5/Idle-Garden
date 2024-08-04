# frozen_string_literal: true

require 'app/plant.rb'

# Create new automations for garden
class Automation
  attr_accessor :type, :harvest_cooldown, :planter_cooldown, :seller_cooldown

  attr_sprite

  def initialize(type)
    @type = type
    @harvest_cooldown = 3
    @planter_cooldown = 2
    @seller_cooldown = 5
  end

  def run(args)
    reduce_cooldowns
    case @type
    when :harvester
      auto_harvester(args) if @harvest_cooldown <= 0 && args.state.game_state.plants.length.positive?
    when :planter
      auto_planter(args) if @planter_cooldown <= 0 && args.state.game_state.seeds.positive?
    when :seller
      auto_seller(args) if @seller_cooldown <= 0 && args.state.game_state.harvested_plants.positive?
    end
  end

  private

  def reduce_cooldowns
    @harvest_cooldown -= 1
    @planter_cooldown -= 1
    @seller_cooldown -= 1
  end

  def auto_harvester(args)
    args.state.game_state.plants.each do |plant|
      next unless plant.stage == 'ready_to_harvest' || plant.stage == 'withered'

      plant.harvest(args, plant)
      @harvest_cooldown = rand(15)
      break
    end
  end

  def auto_planter(args)
    x, y = coord_generator
    plant = Plant.new(args, x, y)
    args.state.game_state.plants << plant
    args.state.game_state.seeds -= 1
    @planter_cooldown = rand(10)
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
    @seller_cooldown = rand(10)
  end

  # DragonRuby required methods
  def serialize
    { type: @type, harvest_cooldown: @harvest_cooldown, planter_cooldown: @planter_cooldown,
      seller_cooldown: @seller_cooldown }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
