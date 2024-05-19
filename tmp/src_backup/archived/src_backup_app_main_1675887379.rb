# frozen_string_literal: true

def place_plant(args)
  {
    x: args.inputs.mouse.x - 15,
    y: args.inputs.mouse.y - 15,
    w: 20,
    h: 20,
    age: 0,
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

def create_button args, id:, row:, col:, text:;
  # args.layout.rect(row:, col:, w:, h:) is method that will
  # return a rectangle inside of a grid with 12 rows and 24 columns
  rect = args.layout.rect row: row, col: col, w: 3, h: 1

  # get senter of rect for label
  center = args.geometry.rect_center_point rect

  {
    id: id,
    x: rect.x,
    y: rect.y,
    w: rect.w,
    h: rect.h,
    primitives: [
      {
        x: rect.x,
        y: rect.y,
        w: rect.w,
        h: rect.h,
        primitive_marker: :border
      },
      {
        x: center.x,
        y: center.y,
        text: text,
        size_enum: -1,
        alignment_enum: 1,
        vertical_alignment_enum: 1,
        primitive_marker: :label
      }
    ]
  }
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
  wither = 60 * 10

   # create buttons
   args.state.buttons ||= [
    create_button(args, id: :button_1, row: 0, col: 2, text: "button 1"),
    create_button(args, id: :button_2, row: 1, col: 0, text: "button 2"),
    create_button(args, id: :clear,    row: 2, col: 0, text: "clear")
  ]

  # render button's border and label
  args.outputs.primitives << args.state.buttons.map do |b|
    b.primitives
  end

  # render center label if the text is set
  if args.state.center_label_text
    args.outputs.labels << { x: 640,
                             y: 360,
                             text: args.state.center_label_text,
                             alignment_enum: 1,
                             vertical_alignment_enum: 1 }
  end

  # if the mouse is clicked, see if the mouse click intersected
  # with a button
  if args.inputs.mouse.click
    button = args.state.buttons.find do |b|
      args.inputs.mouse.intersect_rect? b
    end

    # update the center label text based on button clicked
    case button.id
    when :button_1
      args.state.center_label_text = "button 1 was clicked"
    when :button_2
      args.state.center_label_text = "button 2 was clicked"
    when :clear
      args.state.center_label_text = nil
    end
  end

  # Place plants in garden
  if args.inputs.mouse.click && in_bounds(args)
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
    elsif plant.age >= wither
      plant.path = 'sprites/circle/orange.png'
    else
      plant.path = 'sprites/circle/green.png'
      plant.age += 1
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
