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

  # create an entity in state that represents the button
  args.state.click_me_button.border ||= { x: 10, y: 10, w: 100, h: 50 }
  args.state.click_me_button.label  ||= { x: 10, y: 10, text: "click me" }

  # render the button
  args.outputs.borders << args.state.click_me_button.border
  args.outputs.labels << args.state.click_me_button.label

  # determine if the button has been clicked
  if (args.inputs.mouse.click) &&
      (args.inputs.mouse.point.inside_rect? args.state.click_me_button.border)
    args.gtk.notify! "button was clicked"
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
