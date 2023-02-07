def place_plant(args)
  {
    x: args.inputs.mouse.x - 15,
    y: args.inputs.mouse.y - 15,
    w: 32,
    h: 32,
    path: 'sprites/circle/green.png'
  }
end

def tick(args)
  args.state.plants ||= []

  if args.inputs.mouse.click && args.inputs.mouse.x <= 1280 && args.inputs.mouse.y <= 720 && !args.geometry.intersect_rect?
    args.state.plants << place_plant(args)
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
