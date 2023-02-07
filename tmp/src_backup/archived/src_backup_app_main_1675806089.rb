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

def tick(args)
  args.state.plants ||= []
  args.outputs.solids = [50, 168, 82]
  growth_rate = 0.1
  full_grown = 40

  # Place plants in garden
  if args.inputs.mouse.click && args.inputs.mouse.x <= 1280 && args.inputs.mouse.y <= 720
    new_plant = occupied(args, place_plant(args))
    if new_plant.invalid
      # harvest plant
      plant_to_harvest = new_plant.invalid
      plant_to_harvest.invalid = true if plant_to_harvest.w >= full_grown && plant_to_harvest.h >= full_grown
    else
      args.state.plants << new_plant
    end
  end

  # Remove invalid plants
  args.state.plants.reject! { |p| p.invalid }

  # Grow plants
  args.state.plants.each do |plant|
    if plant.w <= full_grown && plant.h <= full_grown
      plant.w += growth_rate
      plant.h += growth_rate
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
    text: "Plants: #{args.state.plants.length}",
    size_enum: 2
  }
end
