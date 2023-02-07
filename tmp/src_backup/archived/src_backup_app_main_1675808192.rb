def place_plant(args)
  {
    x: args.inputs.mouse.x - 15,
    y: args.inputs.mouse.y - 15,
    w: 20,
    h: 20,
    invalid: false,
    path: 'sprites/circle/yellow.png'
  }
end

def occupied(args, new_plant)
  args.state.plants.each do |plant|
    next unless args.geometry.intersect_rect?(plant, new_plant)

    new_plant.invalid = plant
  end
  new_plant
end

def in_bounds(args)
  args.inputs.mouse.x <= 1280 &&
    args.inputs.mouse.x >= 0 &&
    args.inputs.mouse.y <= 720 &&
    args.inputs.mouse.y >= 0
end

def tick(args)
  args.outputs.background_color = [50, 168, 82]
  args.outputs.static_borders << { x: 0, y: 0, w: 1280, h: 720 }
  args.outputs.static_borders << { x: 0, y: 1, w: 1280, h: 0 }
  args.state.plants ||= []
  args.state.seeds ||= 5
  args.state.harvested_plants ||= 0

  growth_rate = 0.1
  full_grown = 40

  # Place plants in garden
  if args.inputs.mouse.click && in_bounds(args)
    new_plant = occupied(args, place_plant(args))
    if new_plant.invalid
      # harvest plant
      plant_to_harvest = new_plant.invalid
      if plant_to_harvest.w >= full_grown && plant_to_harvest.h >= full_grown
        plant_to_harvest.invalid = true
        args.state.harvested_plants += 1
      end
    elsif args.state.seeds.positive?
      args.state.plants << new_plant
      args.state.seeds -= 1
    end
  end

  # Remove invalid plants
  args.state.plants.reject! { |p| p.invalid }

  # Grow plants
  args.state.plants.each do |plant|
    if plant.w <= full_grown && plant.h <= full_grown
      plant.w += growth_rate
      plant.h += growth_rate
    eslif plant.age
    else
      plant.path = 'sprites/circle/green.png'
    end
  end

  # Render sprites
  args.outputs.sprites << [args.state.plants]

  # Display number of plants
  args.outputs.labels << {
    x: 40,
    y: args.grid.h - 40,
    text: "Growing: #{args.state.plants.length}, Harvested: #{args.state.harvested_plants}",
    size_enum: 2
  }

  # Display number of seeds
  args.outputs.labels << {
    x: 1000,
    y: args.grid.h - 40,
    text: "Seeds: #{args.state.seeds}",
    size_enum: 2
  }
end
