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

# Saves the state of the game in a text file called game_state.txt
def save(state)
  $gtk.serialize_state('game_state.txt', state)
end

def tick(args)
  # args.outputs.solids << [200, 0, 1280, 720, 138, 185, 54, 160] # grass background [x,y,w,h,r,g,b]
  # args.outputs.solids << [250, 50, 980, 620, 170, 129, 56] # dirt background
  # args.outputs.sprites << { x: 200, y: 0, w: 1080, h: 720, path: 'sprites/grass_background.png' }
  # args.outputs.sprites << { x: 250, y: 50, w: 980, h: 620, path: 'sprites/background.png' }
  # args.state.plants ||= []
  # args.state.seeds ||= 500
  # args.state.harvested_plants ||= 0
  # args.state.cash ||= 5
  # args.state.price = { seed: 5, plant: 10, harvester: 150, planter: 150, seller: 50 }
  # args.state.auto_planters ||= []
  # args.state.auto_harvesters ||= []
  # args.state.auto_sellers ||= []
  # args.state.counter ||= 0

  args.state.counter += 1

  args.state.game_state ||= Game.new(args)
  args.state.game_state.tick(args)

  # Buy Seeds Button
  # args.state.buy_seed_button ||= Button.new(:buy_seed, 100, 100, "Seed (#{args.state.price[:seed]})")
  # args.state.buy_seed_button.display(args)

  # check if the click occurred and buys seeds if enough money
  # if args.state.buy_seed_button.clicked?(args) && (args.state.cash - args.state.price[:seed] >= 0)
  #   args.state.seeds += 1
  #   args.state.cash -= args.state.price[:seed]
  # end

  # Sell Harvest Button
  # args.state.sell_button ||= Button.new(:sell, 0, 0, 'Sell', 200)
  # args.state.sell_button.display(args)

  # check if the click occurred and sells harvest
  # if args.state.sell_button.clicked?(args) && !args.state.harvested_plants.negative?
  #   args.state.cash += args.state.harvested_plants * args.state.price[:plant]
  #   args.state.harvested_plants = 0
  # end

  # Make Auto Harvester Button
  # args.state.auto_harvester_button ||= Button.new(:auto_harvester, 0, 50, "Harvester (#{args.state.price[:harvester]})")
  # args.state.auto_harvester_button.display(args)

  # check if the click occurred and creates auto harvester
  # if args.state.auto_harvester_button.clicked?(args) && (args.state.cash - args.state.price[:harvester] >= 0)
  #   args.state.auto_harvesters << Automation.new(:harvester)
  #   args.state.cash -= args.state.price[:harvester]
  # end

  # Make Auto Seller Button
  # args.state.auto_seller_button ||= Button.new(:auto_seller, 100, 50, "Seller (#{args.state.price[:seller]})")
  # args.state.auto_seller_button.display(args)

  # check if the click occurred and creates auto seller
  # if args.state.auto_seller_button.clicked?(args) && (args.state.cash - args.state.price[:seller] >= 0)
  #   args.state.auto_sellers << Automation.new(:seller)
  #   args.state.cash -= args.state.price[:seller]
  # end

  # Make Auto Planter Button
  # args.state.auto_planter_button ||= Button.new(:auto_planter, 0, 100, "Planter (#{args.state.price[:planter]})")
  # args.state.auto_planter_button.display(args)

  # check if the click occurred and creates auto planter
  # if args.state.auto_planter_button.clicked?(args) && (args.state.cash - args.state.price[:planter] >= 0)
  #   args.state.auto_planters << Automation.new(:planter)
  #   args.state.cash -= args.state.price[:planter]
  # end

  # Make Save button
  # args.state.save_button ||= Button.new(:save, 0, 150, 'Save')
  # args.state.save_button.display(args)

  # save(args.state) if args.state.save_button.clicked?(args)

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
  args.state.seed_label ||= Labels.new(5, args.grid.h - 20, 'Seeds', args.state.seeds)
  args.state.seed_label.display(args)
  args.state.seed_label.update(args.state.seeds)

  # Display number of growing plants
  args.state.plant_label ||= Labels.new(5, args.grid.h - 40, 'Growing', args.state.plants.length)
  args.state.plant_label.display(args)
  args.state.plant_label.update(args.state.plants.length)

  # Display harvested plants
  args.state.harvested_label ||= Labels.new(5, args.grid.h - 60, 'Harvested', args.state.harvested_plants)
  args.state.harvested_label.display(args)
  args.state.harvested_label.update(args.state.harvested_plants)

  # Display cash
  args.state.cash_label ||= Labels.new(5, args.grid.h - 80, 'Cash', args.state.cash)
  args.state.cash_label.display(args)
  args.state.cash_label.update(args.state.cash)

  # Display auto harvesters
  args.state.auto_harvesters_label ||= Labels.new(5, args.grid.h - 100, 'Harvesters', args.state.auto_harvesters.length)
  args.state.auto_harvesters_label.display(args)
  args.state.auto_harvesters_label.update(args.state.auto_harvesters.length)

  # Display auto planters
  args.state.auto_planters_label ||= Labels.new(5, args.grid.h - 120, 'Planters', args.state.auto_planters.length)
  args.state.auto_planters_label.display(args)
  args.state.auto_planters_label.update(args.state.auto_planters.length)

  # Display auto sellers
  args.state.auto_sellers_label ||= Labels.new(5, args.grid.h - 140, 'Sellers', args.state.auto_sellers.length)
  args.state.auto_sellers_label.display(args)
  args.state.auto_sellers_label.update(args.state.auto_sellers.length)
end
