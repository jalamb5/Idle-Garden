# frozen_string_literal: true

# Create new automations for garden
class Automation
  attr_accessor :type, :cooldown

  attr_sprite

  def initialize(type)
    @type = type
    @cooldown = 30
  end

  def run(args)
    @cooldown -= 1
    return unless @cooldown <= 0

    case @type
    when :harvester
      auto_harvester(args)
    when :planter
      auto_planter(args)
    when :seller
      auto_seller(args)
    end
  end

  private

  def auto_harvester(args)
    args.state.plants.each do |plant|
      next unless plant.stage == 'full_grown' || plant.stage == 'withered'

      plant.harvest(args, plant)
      @cooldown = 100 * rand(3)
      break
    end
  end

  def auto_planter(_args)
    false
  end

  def auto_seller(args)
    args.state.cash += args.state.harvested_plants * args.state.price[:plant]
    args.state.harvested_plants = 0
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
