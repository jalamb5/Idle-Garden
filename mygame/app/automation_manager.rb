# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/automation.rb'
require 'app/spritesheet.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Handle running of automations
class AutomationManager
  attr_accessor :auto_planters, :auto_harvesters, :auto_sellers, :spritesheets

  def initialize
    @auto_planters = []
    @auto_harvesters = []
    @auto_sellers = []
    # @counter = 0
    @spritesheets = build_spritesheets
  end

  def tick(args)
    # @counter += 1
    # return if @counter % 75 != 0

    all_automations = @auto_planters + @auto_harvesters + @auto_sellers

    run_automations(args, all_automations)
    display_automations(args, all_automations)

    # @counter = 0
  end

  def run_automations(args, automations)
    automations.each { |automation| automation.run(args) }
  end

  def reconstruct
    all_automations = [@auto_harvesters, @auto_planters, @auto_sellers]
    attributes = %i[type harvest_cooldown planter_cooldown seller_cooldown]

    all_automations.each do |automations|
      automations.map! do |automation|
        new_automation = Automation.new(automation.type)
        attributes.each do |attr|
          new_automation.send("#{attr}=", automation.send(attr))
        end
        new_automation
      end
    end
  end

  private

  def build_spritesheets
    { harvester: Spritesheet.new('sprites/green.png', 64, 64, 3),
      planter: Spritesheet.new('sprites/planter_pink_32x32.png', 32, 32, 4),
      seller: Spritesheet.new('sprites/blue.png', 64, 64, 3) }
  end

  def display_automations(args, automations)
    automations.each do |automation|
      args.outputs.sprites << automation.sprite
    end
  end

  # DragonRuby required methods
  def serialize
    { auto_planters: @auto_planters, auto_harvesters: @auto_harvesters, auto_sellers: @auto_sellers }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
