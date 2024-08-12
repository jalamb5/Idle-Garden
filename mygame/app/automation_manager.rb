# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/automation.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Handle running of automations
class AutomationManager
  attr_accessor :auto_planters, :auto_harvesters, :auto_sellers

  def initialize
    @auto_planters = []
    @auto_harvesters = []
    @auto_sellers = []
    @counter = 0
  end

  def tick(args)
    @counter += 1
    return if @counter % 75 != 0

    all_automations = @auto_planters + @auto_harvesters + @auto_sellers

    run_automations(all_automations, args)

    @counter = 0
  end

  def run_automations(automations, args)
    automations.each { |automation| automation.run(args) }
  end

  # def reconstruct_automations(type, automations)
  #   attributes = %i[type harvest_cooldown planter_cooldown seller_cooldown]

  #   automations.map! do |automation|
  #     new_automation = Automation.new(type)
  #     attributes.each do |attr|
  #       new_automation.send("#{attr}=", automation.send(attr))
  #     end
  #     new_automation
  #   end
  # end

  private

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
