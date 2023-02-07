def place_plant(args)
  {
    x: args.inputs.mouse.x - 15,
    y: args.inputs.mouse.y - 15,
    w: 32,
    h: 32,
    invalid: false,
    path: 'sprites/circle/green.png'
  }
end

def occupied(args, new_plant)
  args.state.plants.each do |plant|
    next unless args.geometry.intersect_rect?(plant, new_plant)

    new_plant.invalid = true
  end
  new_plant
end

def tick(args)
  args.state.plants ||= []

  # Place plants on board
  if args.inputs.mouse.click && args.inputs.mouse.x <= 1280 && args.inputs.mouse.y <= 720
    location = occupied(args, place_plant(args))
    if location.invalid
      # harvest plant
    else
      args.state.plants << location
    end
  end

  # Remove invalid plants
  args.state.plants.reject! { |p| p.invalid }

  # Grow plants
  args.state.plants.each do |plant|
    plant.w += 0.01 unless plant.w >= 40
    plant.h += 0.01 unless plant.h >= 40
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
