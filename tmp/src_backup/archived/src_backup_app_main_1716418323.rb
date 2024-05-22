# frozen_string_literal: true

require 'app/plant.rb'
require 'app/automation.rb'

# Total Interactive Area
def in_bounds(args)
  args.inputs.mouse.x <= 1280 &&
    args.inputs.mouse.x >= 0 &&
    args.inputs.mouse.y <= 720 &&
    args.inputs.mouse.y >= 0
end

# Area available for plants
def in_garden(args)
  args.inputs.mouse.x <= 980 &&
    args.inputs.mouse.x >= 250 &&
    args.inputs.mouse.y <= 620 &&
    args.inputs.mouse.y >= 50
end

# helper method to create a button
def new_button(id, x, y, text)
  width = 100
  height = 50
  entity = {
    id: id,
    rect: { x: x, y: y, w: width, h: height }
  }

  entity[:primitives] = [
    { x: x, y: y, w: width, h: height }.border!,
    { x: x + 10, y: y + 30, text: text, size_enum: -4 }.label!
  ]
  entity
end

# helper method for determining if a button was clicked
def button_clicked?(args, button)
  return false unless args.inputs.mouse.click

  args.inputs.mouse.point.inside_rect? button[:rect]
end

def tick(args)
  # args.outputs.background_color = [50, 168, 82]
  args.outputs.solids << [200, 0, 1280, 720, 138, 185, 54] # grass background [x,y,w,h,r,g,b]
  args.outputs.solids << [250, 50, 980, 620, 170, 129, 56] # dirt background
  args.outputs.static_borders << { x: 0, y: 0, w: 1280, h: 720 }
  args.outputs.static_borders << { x: 0, y: 1, w: 1280, h: 0 }
  args.state.plants ||= []
  args.state.seeds ||= 5
  args.state.harvested_plants ||= 0
  args.state.cash ||= 5
  args.state.price = { seed: 5, plant: 10, harvester: 150, planter: 150, seller: 50 }
  args.state.auto_planters ||= []
  args.state.auto_harvesters ||= []
  args.state.auto_sellers ||= []
  args.state.counter ||= 0

  args.state.counter += 1

  # Buy Seeds Button
  args.state.buy_seed_button ||= new_button :buy_seed, 0, 0, 'Buy'
  args.outputs.primitives << args.state.buy_seed_button[:primitives]

  # check if the click occurred and buys seeds if enough money
  if args.inputs.mouse.click && button_clicked?(args, args.state.buy_seed_button) && !(args.state.cash - args.state.price[:seed] < 0)
    args.state.seeds += 1
    args.state.cash -= args.state.price[:seed]
  end

  # Sell Harvest Button
  args.state.sell_button ||= new_button :sell, 100, 0, 'Sell'
  args.outputs.primitives << args.state.sell_button[:primitives]

  # check if the click occurred and sells harvest
  if args.inputs.mouse.click && button_clicked?(args, args.state.sell_button) && !(args.state.harvested_plants.negative?)
    args.state.cash += args.state.harvested_plants * args.state.price[:plant]
    args.state.harvested_plants = 0
  end

  # Make Auto Harvester Button
  args.state.auto_harvester_button ||= new_button :auto_harvester, 0, 50, 'Auto Harvester'
  args.outputs.primitives << args.state.auto_harvester_button[:primitives]

  # check if the click occurred and creates auto harvester
  if args.inputs.mouse.click && button_clicked?(args, args.state.auto_harvester_button)
    args.state.auto_harvesters << Automation.new(:harvester)
  end

  # Make Auto Seller Button
  args.state.auto_seller_button ||= new_button :auto_seller, 100, 50, 'Auto Seller'
  args.outputs.primitives << args.state.auto_seller_button[:primitives]

  # check if the click occurred and creates auto seller
  if args.inputs.mouse.click && button_clicked?(args, args.state.auto_seller_button)
    args.state.auto_sellers << Automation.new(:seller)
  end

  # Make Auto Planter Button
  args.state.auto_planter_button ||= new_button :auto_planter, 0, 100, 'Auto Planter'
  args.outputs.primitives << args.state.auto_planter_button[:primitives]

  # check if the click occurred and creates auto planter
  if args.inputs.mouse.click && button_clicked?(args, args.state.auto_planter_button)
    args.state.auto_planters << Automation.new(:planter)
  end

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
  args.outputs.labels << {
    x: 5,
    y: args.grid.h - 20,
    text: "Seeds: #{args.state.seeds}",
    size_px: 22
  }

  # Display number of plants
  args.outputs.labels << {
    x: 5,
    y: args.grid.h - 40,
    text: "Growing: #{args.state.plants.length}",
    size_px: 22
  }

  # Display harvested plants
  args.outputs.labels << {
    x: 5,
    y: args.grid.h - 60,
    text: "Harvested: #{args.state.harvested_plants}",
    size_px: 22
  }

  # Display cash
  args.outputs.labels << {
    x: 5,
    y: args.grid.h - 80,
    text: "Cash: #{args.state.cash}",
    size_px: 22
  }

  # Display auto harvesters
  args.outputs.labels << {
    x: 5,
    y: args.grid.h - 100,
    text: "Harvesters: #{args.state.auto_harvesters.length}",
    size_px: 22
  }
end
