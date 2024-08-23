# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/automation.rb'
require 'app/spritesheet.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Handle running of automations
class AutomationManager
  attr_accessor :auto_planters, :auto_harvesters, :auto_sellers, :spritesheets, :register

  def initialize
    @auto_planters = []
    @auto_harvesters = []
    @auto_sellers = []
    @spritesheets = build_spritesheets
    # Hold automation names to prevent duplication
    @register = []
  end

  def tick(args)
    all_automations = @auto_planters + @auto_harvesters + @auto_sellers

    run_automations(args, all_automations)
    display_automations(args, all_automations) unless args.state.game_state.shed.open
    monitor_automations(args, all_automations)
  end

  def run_automations(args, automations)
    automations.each { |automation| automation.run(args) }
  end

  def reconstruct(args)
    all_automations = [@auto_harvesters, @auto_planters, @auto_sellers]
    attributes = %i[type name work_completed location target cooldown counter]

    all_automations.each do |automations|
      automations.map! do |automation|
        new_automation = Automation.new(automation.type, args)
        attributes.each do |attr|
          new_automation.send("#{attr}=", automation.send(attr))
        end
        new_automation
      end
    end
  end

  private

  def build_spritesheets
    { harvester: Spritesheet.new('sprites/harvester_blue_32x32.png', 32, 32, 4),
      planter: Spritesheet.new('sprites/planter_pink_32x32.png', 32, 32, 4),
      seller: Spritesheet.new('sprites/seller_purple_32x32.png', 32, 32, 4) }
  end

  def display_automations(args, automations)
    automations.each do |automation|
      args.outputs.sprites << automation.sprite
    end
  end

  def monitor_automations(args, automations)
    automations.each do |automation|
      automation.clicked?(args)
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
