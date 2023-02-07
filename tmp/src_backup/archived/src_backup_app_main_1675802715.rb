def tick(args)
  args.state.plants ||= []

  if args.inputs.mouse.click
    args.state.plants << {
      x: args.inputs.mouse.x - 15,
      y: args.inputs.mouse.y - 15,
      w: 32,
      h: 32,
      path: 'sprites/circle/green.png'
    }
  end

  # Render sprites
  args.outputs.sprites << [args.state.plants]

  # Display score
  args.outputs.labels << {
    x: 40,
    y: args.grid.h - 40,
    text: "",
    size_enum: 2
  }
end
