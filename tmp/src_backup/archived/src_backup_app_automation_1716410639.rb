# frozen_string_literal: true

# Create new automations for garden
class Automation
  attr_accessor :type

  attr_sprite

  def initialize(type)
    @type = type
    @cool_down = 12000
  end

  def run(args)
    return unless @type == :harvest

    @cool_down -= 0.001

    args.state.plants.each do |plant|
      next unless plant.stage == 'full_grown' || plant.stage == 'withered' && @cool_down <= 0

      plant.harvest(args, plant)
      plant.invalid = true
      args.state.harvested_plants += 1
      @cool_down = 12000
      break
    end
  end

  private

  # DragonRuby required methods
  def serialize
    { type: @type }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
