# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/plant.rb'
require 'app/automation.rb'
require 'app/labels.rb'
require 'app/button.rb'
require 'app/game.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Area available for plants
def in_garden(args)
  garden = { x: 250, y: 50, w: 980, h: 620 }

  args.inputs.mouse.point.inside_rect? garden
end

def tick(args)
  # args.outputs.solids << [200, 0, 1280, 720, 138, 185, 54, 160] # grass background [x,y,w,h,r,g,b]
  # args.outputs.solids << [250, 50, 980, 620, 170, 129, 56] # dirt background
  # args.outputs.sprites << { x: 200, y: 0, w: 1080, h: 720, path: 'sprites/grass_background.png' }
  # args.outputs.sprites << { x: 250, y: 50, w: 980, h: 620, path: 'sprites/background.png' }
  args.state.plants ||= []
  # args.state.seeds ||= 500
  args.state.harvested_plants ||= 0
  # args.state.cash ||= 5
  # args.state.price = { seed: 5, plant: 10, harvester: 150, planter: 150, seller: 50 }
  # args.state.auto_planters ||= []
  # args.state.auto_harvesters ||= []
  # args.state.auto_sellers ||= []
  args.state.counter ||= 0

  args.state.counter += 1

  args.state.game_state ||= Game.new(args)
  args.state.game_state.tick(args)

  # Place or harvest plants in garden
  if args.inputs.mouse.click && in_garden(args)
    new_plant = Plant.new(args)

    if args.state.seeds.positive? && !new_plant.invalid
      args.state.plants << new_plant
      args.state.seeds -= 1
    end
  end

  # Remove invalid plants
  args.state.plants.reject!(&:invalid)

  # Grow plants
  args.state.plants.each(&:grow)

  # Run automations at regular intervals (2.5 seconds)
  if args.state.counter >= 30 * 2.5
    # Run auto harvesters
    args.state.auto_harvesters.each { |harvester| harvester.run(args) }

    # Run auto sellers
    args.state.auto_sellers.each { |seller| seller.run(args) }

    # Run auto planters
    args.state.auto_planters.each { |planter| planter.run(args) }

    # Reset counter
    args.state.counter = 0
  end

  # Render sprites
  args.outputs.sprites << [args.state.plants]

  # Display number of seeds
  args.state.seed_label ||= Labels.new(5, args.grid.h - 20, 'Seeds', args.state.game_state.seeds)
  args.state.seed_label.display(args)
  args.state.seed_label.update(args.state.game_state.seeds)

  # Display number of growing plants
  args.state.plant_label ||= Labels.new(5, args.grid.h - 40, 'Growing', args.state.game_state.plants.length)
  args.state.plant_label.display(args)
  args.state.plant_label.update(args.state.game_state.plants.length)

  # Display harvested plants
  args.state.harvested_label ||= Labels.new(5, args.grid.h - 60, 'Harvested', args.state.game_state.harvested_plants)
  args.state.harvested_label.display(args)
  args.state.harvested_label.update(args.state.game_state.harvested_plants)

  # Display cash
  args.state.cash_label ||= Labels.new(5, args.grid.h - 80, 'Cash', args.state.game_state.cash)
  args.state.cash_label.display(args)
  args.state.cash_label.update(args.state.game_state.cash)

  # Display auto harvesters
  args.state.auto_harvesters_label ||= Labels.new(5, args.grid.h - 100, 'Harvesters', args.state.game_state.auto_harvesters.length)
  args.state.auto_harvesters_label.display(args)
  args.state.auto_harvesters_label.update(args.state.game_state.auto_harvesters.length)

  # Display auto planters
  args.state.auto_planters_label ||= Labels.new(5, args.grid.h - 120, 'Planters', args.state.game_state.auto_planters.length)
  args.state.auto_planters_label.display(args)
  args.state.auto_planters_label.update(args.state.game_state.auto_planters.length)

  # Display auto sellers
  args.state.auto_sellers_label ||= Labels.new(5, args.grid.h - 140, 'Sellers', args.state.game_state.auto_sellers.length)
  args.state.auto_sellers_label.display(args)
  args.state.auto_sellers_label.update(args.state.game_state.auto_sellers.length)
end
