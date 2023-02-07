def place_plant(args)
  {
    x: args.inputs.mouse.x - 15,
    y: args.inputs.mouse.y - 15,
    w: 32,
    h: 32,
    path: 'sprites/circle/green.png'
  }
end

def occupied(args)
  args.state.plants.each do |plant|
    new_plant = place_plant(args)
    next unless args.geometry.intersect_rect?(plant, new_plant)
  end
end

def tick(args)
  args.state.plants ||= []

  if args.inputs.mouse.click && args.inputs.mouse.x <= 1280 && args.inputs.mouse.y <= 720
    args.state.plants << occupied(args)
  end

  # Render sprites
  args.outputs.sprites << [args.state.plants]

  # Display score
  args.outputs.labels << {
    x: 40,
    y: args.grid.h - 40,
    text: "Plants: #{args.state.plants.length}",
    size_enum: 2
  }
end
