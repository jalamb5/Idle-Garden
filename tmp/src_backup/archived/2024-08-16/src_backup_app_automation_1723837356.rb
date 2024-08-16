# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/plant.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Create new automations for garden
class Automation
  attr_accessor :type, :cooldown, :sprite

  COOLDOWNS = { harvester: 300, planter: 200, seller: 500 }.freeze

  def initialize(type, args)
    @type = type
    @cooldown = COOLDOWNS[type]
    @location = [250, 50]
    @target = target_generator(args)
    @sprite = update_sprite(args)
    @frame = 0
    @counter = 0
  end

  def run(args)
    update_sprite(args)
    move_sprite if @cooldown <= 0
    update_frame(args) if @counter % 10 == 0
    @cooldown -= 1
    @counter += 1
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

  def update_sprite(args)
    @sprite = args.state.game_state.automations.spritesheets[@type].get(@frame, @location[0], @location[1], 32, 32)
  end

  def update_frame(args)
    @frame = @frame < args.state.game_state.automations.spritesheets[@type].num_tiles - 1 ? @frame + 1 : 0
  end

  def move_sprite
    return if @location == @target || @target.nil?

    @location.each_with_index do |coord, i|
      direction = (@target[i] - coord).negative? ? -1 : 1
      @location[i] += direction if coord != @target[i]
    end
  end

  def auto_harvester(args)
    @target = harvest_generator(args) if @target.nil?

    return unless @location == @target

    plant = args.state.game_state.plant_manager.plants.find { |i| i.x == @location[0] && i.y == @location[1] }
    plant.harvest(args, plant) unless plant.nil?
    @cooldown = rand(1000)
    @target = nil
  end

  def auto_planter(args)
    return unless @location == @target

    sheet = %i[flower_red flower_blue].sample
    plant = Plant.new(args, sheet, @location[0], @location[1])
    args.state.game_state.plant_manager.plants << plant
    args.state.game_state.plant_manager.seeds -= 1
    @cooldown = rand(1000)
    @target = coord_generator
  end

  def coord_generator
    # x 250-1200, y 50-650
    x = rand(1200)
    x += 250 if x < 250
    y = rand(650)
    y += 50 if y < 50
    [x, y]
  end

  def auto_seller(args)
    args.state.game_state.cash += args.state.game_state.harvested_plants * args.state.game_state.price[:plant]
    args.state.game_state.score += args.state.game_state.harvested_plants * 10
    args.state.game_state.harvested_plants = 0
    @cooldown = rand(10)
  end

  def harvest_generator(args)
    harvestable_plants = []
    args.state.game_state.plant_manager.plants.each do |plant|
      harvestable_plants << plant if plant.stage == :READY_TO_HARVEST || plant.stage == :WITHERED
    end
    if harvestable_plants.empty?
      nil
    else
      target_plant = harvestable_plants.sample
      [target_plant.x, target_plant.y]
    end
  end

  def target_generator(args)
    case @type
    when :harvester
      nil
    when :planter
      coord_generator
    when :seller
      harvested = args.state.game_state.ui.labels[:harvested]
      [harvested.x + 100, harvested.y - 30]
    end
  end

  # DragonRuby required methods
  def serialize
    { type: @type, cooldown: @cooldown, sprite: @sprite }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
