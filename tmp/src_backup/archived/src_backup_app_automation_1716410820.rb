# frozen_string_literal: true

# Create new automations for garden
class Automation
  attr_accessor :type

  attr_sprite

  def initialize(type)
    @type = type
    @cool_down = 20
  end

  def run(args)
    return unless @type == :harvest

    @cool_down -= 1

    return unless @cool_down <= 0

    args.state.plants.each do |plant|
      next unless plant.stage == 'full_grown' || plant.stage == 'withered'

      plant.harvest(args, plant)
      plant.invalid = true
      args.state.harvested_plants += 1
      @cool_down = 120
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
