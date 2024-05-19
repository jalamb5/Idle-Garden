# frozen_string_literal: true

# require 'app/button.rb'

def place_plant(args)
  {
    x: args.inputs.mouse.x - 15,
    y: args.inputs.mouse.y - 15,
    w: 20,
    h: 20,
    age: 0,
    invalid: false,
    path: 'sprites/circle/yellow.png',
    a: 255
  }
end

def occupied(args, new_plant)
  args.state.plants.each do |plant|
    next unless args.geometry.intersect_rect?(plant, new_plant)

    new_plant.invalid = plant
  end
  new_plant
end

# Total Interactive Area
def in_bounds(args)
  args.inputs.mouse.x <= 1280 &&
    args.inputs.mouse.x >= 0 &&
    args.inputs.mouse.y <= 720 &&
    args.inputs.mouse.y >= 0
end

# Area available for plants
def in_garden(args)
  args.inputs.mouse.x <= 1280 &&
    args.inputs.mouse.x >= 100 &&
    args.inputs.mouse.y <= 720 &&
    args.inputs.mouse.y >= 0
end

# helper method to create a button
def new_button(id, x, y, text)
  width = 100
  height = 50
  # create a hash ("entity") that has some metadata about what it represents
  entity = {
    id: id,
    rect: { x: x, y: y, w: width, h: height }
  }

  # for that entity, define the primitives that form it
  entity[:primitives] = [
    { x: x, y: y, w: width, h: height }.border,
    { x: x + 10, y: y + 30, text: text }.label
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
  args.outputs.solids << [100, 0, 1280, 720, 50, 168, 82]
  args.outputs.static_borders << { x: 0, y: 0, w: 1280, h: 720 }
  args.outputs.static_borders << { x: 0, y: 1, w: 1280, h: 0 }
  args.state.plants ||= []
  args.state.seeds ||= 5
  args.state.harvested_plants ||= 0
  args.state.cash ||= 5
  args.state.price = { seed: 5, plant: 10 }

  # Buy Seeds Button
  args.state.buy_seed_button ||= new_button :buy_seed, 0, 0, 'Buy'
  args.outputs.primitives << args.state.buy_seed_button[:primitives]

  # check if the click occurred and buys seeds if enough money
  if args.inputs.mouse.click && button_clicked?(args, args.state.buy_seed_button) && !(args.state.cash - args.state.price[:seed] < 0)
    #  args.gtk.notify! "click me button was clicked!"
    args.state.seeds += 1
    args.state.cash -= args.state.price[:seed]
  end

  # Sell Harvest Button
  args.state.sell_button ||= new_button :sell, 0, 50, 'Sell'
  args.outputs.primitives << args.state.sell_button[:primitives]

  # check if the click occurred and sells harvest
  if args.inputs.mouse.click && button_clicked?(args, args.state.sell_button) && !(args.state.harvested_plants.negative?)
    args.state.cash += args.state.harvested_plants * args.state.price[:plant]
    args.state.harvested_plants = 0
  end

  # Growth Stages & Rates
  growth_rate = 0.1
  full_grown = 40
  wither = 60 * 1.2
  wither_rate = 0.4
  death = 60 * 8

  # Place plants in garden
  if args.inputs.mouse.click && in_garden(args)
    new_plant = occupied(args, place_plant(args))
    if new_plant.invalid
      # Harvest plant
      plant_to_harvest = new_plant.invalid
      if plant_to_harvest.age.positive? && plant_to_harvest.age < wither
        plant_to_harvest.invalid = true
        args.state.harvested_plants += 1
      # Collect seeds from withered plant
      elsif plant_to_harvest.age >= wither
        plant_to_harvest.invalid = true
        args.state.seeds += rand(10)
      end
    elsif args.state.seeds.positive?
      args.state.plants << new_plant
      args.state.seeds -= 1
    end
  end

  # Remove invalid plants
  args.state.plants.reject!(&:invalid)

  # Grow plants
  args.state.plants.each do |plant|
    if plant.w <= full_grown && plant.h <= full_grown
      plant.w += growth_rate
      plant.h += growth_rate
    elsif plant.age >= wither && plant.age < death
      plant.path = 'sprites/circle/orange.png'
      plant.age += 1
      plant.a -= wither_rate
    elsif plant.age >= death
      plant.invalid = true
    else
      plant.path = 'sprites/circle/green.png'
      plant.age += 1
    end
  end

  # Render sprites
  args.outputs.sprites << [args.state.plants]

    # Display number of seeds
  args.outputs.labels << {
    x: 10,
    y: args.grid.h - 20,
    text: "Seeds: #{args.state.seeds}",
    size_px: 22
  }

  # Display number of plants
  args.outputs.labels << {
    x: 10,
    y: args.grid.h - 40,
    text: "Growing: #{args.state.plants.length}",
    size_px: 22
  }

  args.outputs.labels << {
    x: 10,
    y: args.grid.h - 60,
    text: "Harvested: #{args.state.harvested_plants}",
    size_px: 22
  }

  args.outputs.labels << {
    x: 10,
    y: args.grid.h - 80,
    text: "Cash: #{args.state.cash}",
    size_px: 22
  }


end
