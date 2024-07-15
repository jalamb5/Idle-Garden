# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/game.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Area available for plants
def in_garden(args)
  garden = { x: 250, y: 50, w: 980, h: 620 }

  args.inputs.mouse.point.inside_rect? garden
end

def tick(args)
  args.state.game_state ||= Game.new(args)
  args.state.game_state.tick(args)

  # # Place or harvest plants in garden
  # if args.inputs.mouse.click && in_garden(args)
  #   new_plant = Plant.new(args)

  #   if args.state.game_state.seeds.positive? && !new_plant.invalid
  #     args.state.game_state.plants << new_plant
  #     args.state.game_state.seeds -= 1
  #   end
  # end

  # # Remove invalid plants
  # args.state.game_state.plants.reject!(&:invalid)

  # # Grow plants
  # args.state.game_state.plants.each(&:grow)

  # # Run automations at regular intervals (2.5 seconds)
  # if args.state.game_state.counter >= 30 * 2.5
  #   # Run auto harvesters
  #   args.state.game_state.auto_harvesters.each { |harvester| harvester.run(args) }

  #   # Run auto sellers
  #   args.state.game_state.auto_sellers.each { |seller| seller.run(args) }

  #   # Run auto planters
  #   args.state.game_state.auto_planters.each { |planter| planter.run(args) }

  #   # Reset counter
  #   args.state.game_state.counter = 0
  # end

  # # Render sprites
  # args.outputs.sprites << [args.state.game_state.plants]
end
