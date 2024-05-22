# frozen_string_literal: true

# Create new automations for garden
class Automation
  attr_accessor :type, :cooldown

  attr_sprite

  def initialize(type)
    @type = type
    @cooldown = 30 * 20
  end

  def run(args)
    @cooldown -= 1
    return unless @type == :harvest && @cooldown <= 0

    args.state.plants.each do |plant|
      next unless plant.stage == 'full_grown' || plant.stage == 'withered'

      plant.harvest(args, plant)
      @cooldown = 30 * 30
      break
    end
  end

  private

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
