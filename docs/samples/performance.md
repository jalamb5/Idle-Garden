### Sprites As Hash - main.rb
```ruby
  # ./samples/09_performance/01_sprites_as_hash/app/main.rb

  # Sprites represented as Hashes using the queue ~args.outputs.sprites~
  # code up, but are the "slowest" to render.
  # The reason for this is the access of the key in the Hash and also
  # because the data args.outputs.sprites is cleared every tick.
  def random_x args
    (args.grid.w.randomize :ratio) * -1
  end

  def random_y args
    (args.grid.h.randomize :ratio) * -1
  end

  def random_speed
    1 + (4.randomize :ratio)
  end

  def new_star args
    {
      x: (random_x args),
      y: (random_y args),
      w: 4, h: 4, path: 'sprites/tiny-star.png',
      s: random_speed
    }
  end

  def move_star args, star
    star.x += star[:s]
    star.y += star[:s]
    if star.x > args.grid.w || star.y > args.grid.h
      star.x = (random_x args)
      star.y = (random_y args)
      star[:s] = random_speed
    end
  end

  def tick args
    args.state.star_count ||= 0

    # sets console command when sample app initially opens
    if Kernel.global_tick_count == 0
      puts ""
      puts ""
      puts "========================================================="
      puts "* INFO: Sprites, Hashes"
      puts "* INFO: Please specify the number of sprites to render."
      args.gtk.console.set_command "reset_with count: 100"
    end

    # init
    if Kernel.tick_count == 0
      args.state.stars = args.state.star_count.map { |i| new_star args }
    end

    # update
    args.state.stars.each { |s| move_star args, s }

    # render
    args.outputs.sprites << args.state.stars
    args.outputs.background_color = [0, 0, 0]
    args.outputs.primitives << args.gtk.current_framerate_primitives
  end

  # resets game, and assigns star count given by user
  def reset_with count: count
    $gtk.reset
    $gtk.args.state.star_count = count
  end

```

### Sprites As Entities - main.rb
```ruby
  # ./samples/09_performance/02_sprites_as_entities/app/main.rb
  # Sprites represented as Entities using the queue ~args.outputs.sprites~
  # yields nicer access apis over Hashes, but require a bit more code upfront.
  # The hash sample has to use star[:s] to get the speed of the star, but
  # an entity can use .s instead.
  def random_x args
    (args.grid.w.randomize :ratio) * -1
  end

  def random_y args
    (args.grid.h.randomize :ratio) * -1
  end

  def random_speed
    1 + (4.randomize :ratio)
  end

  def new_star args
    args.state.new_entity :star, {
      x: (random_x args),
      y: (random_y args),
      w: 4, h: 4,
      path: 'sprites/tiny-star.png',
      s: random_speed
    }
  end

  def move_star args, star
    star.x += star.s
    star.y += star.s
    if star.x > args.grid.w || star.y > args.grid.h
      star.x = (random_x args)
      star.y = (random_y args)
      star.s = random_speed
    end
  end

  def tick args
    args.state.star_count ||= 0

    # sets console command when sample app initially opens
    if Kernel.global_tick_count == 0
      puts ""
      puts ""
      puts "========================================================="
      puts "* INFO: Sprites, Open Entities"
      puts "* INFO: Please specify the number of sprites to render."
      args.gtk.console.set_command "reset_with count: 100"
    end

    # init
    if Kernel.tick_count == 0
      args.state.stars = args.state.star_count.map { |i| new_star args }
    end

    # update
    args.state.stars.each { |s| move_star args, s }

    # render
    args.outputs.sprites << args.state.stars
    args.outputs.background_color = [0, 0, 0]
    args.outputs.primitives << args.gtk.current_framerate_primitives
  end

  # resets game, and assigns star count given by user
  def reset_with count: count
    $gtk.reset
    $gtk.args.state.star_count = count
  end

```

### Sprites As Strict Entities - main.rb
```ruby
  # ./samples/09_performance/04_sprites_as_strict_entities/app/main.rb
  # Sprites represented as StrictEntities using the queue ~args.outputs.sprites~
  # yields apis access similar to Entities, but all properties that can be set on the
  # entity must be predefined with a default value. Strict entities do not support the
  # addition of new properties after the fact. They are more performant than OpenEntities
  # because of this constraint.
  def random_x args
    (args.grid.w.randomize :ratio) * -1
  end

  def random_y args
    (args.grid.h.randomize :ratio) * -1
  end

  def random_speed
    1 + (4.randomize :ratio)
  end

  def new_star args
    args.state.new_entity_strict(:star,
                                 x: (random_x args),
                                 y: (random_y args),
                                 w: 4, h: 4,
                                 path: 'sprites/tiny-star.png',
                                 s: random_speed) do |entity|
      # invoke attr_sprite so that it responds to
      # all properties that are required to render a sprite
      entity.attr_sprite
    end
  end

  def move_star args, star
    star.x += star.s
    star.y += star.s
    if star.x > args.grid.w || star.y > args.grid.h
      star.x = (random_x args)
      star.y = (random_y args)
      star.s = random_speed
    end
  end

  def tick args
    args.state.star_count ||= 0

    # sets console command when sample app initially opens
    if Kernel.global_tick_count == 0
      puts ""
      puts ""
      puts "========================================================="
      puts "* INFO: Sprites, Strict Entities"
      puts "* INFO: Please specify the number of sprites to render."
      args.gtk.console.set_command "reset_with count: 100"
    end

    # init
    if Kernel.tick_count == 0
      args.state.stars = args.state.star_count.map { |i| new_star args }
    end

    # update
    args.state.stars.each { |s| move_star args, s }

    # render
    args.outputs.sprites << args.state.stars
    args.outputs.background_color = [0, 0, 0]
    args.outputs.primitives << args.gtk.current_framerate_primitives
  end

  # resets game, and assigns star count given by user
  def reset_with count: count
    $gtk.reset
    $gtk.args.state.star_count = count
  end

```

### Sprites As Classes - main.rb
```ruby
  # ./samples/09_performance/05_sprites_as_classes/app/main.rb
  # Sprites represented as Classes using the queue ~args.outputs.sprites~.
  # gives you full control of property declaration and method invocation.
  # They are more performant than OpenEntities and StrictEntities, but more code upfront.
  class Star
    attr_sprite

    def initialize grid
      @grid = grid
      @x = (rand @grid.w) * -1
      @y = (rand @grid.h) * -1
      @w    = 4
      @h    = 4
      @s    = 1 + (4.randomize :ratio)
      @path = 'sprites/tiny-star.png'
    end

    def move
      @x += @s
      @y += @s
      @x = (rand @grid.w) * -1 if @x > @grid.right
      @y = (rand @grid.h) * -1 if @y > @grid.top
    end
  end

  # calls methods needed for game to run properly
  def tick args
    # sets console command when sample app initially opens
    if Kernel.global_tick_count == 0
      puts ""
      puts ""
      puts "========================================================="
      puts "* INFO: Sprites, Classes"
      puts "* INFO: Please specify the number of sprites to render."
      args.gtk.console.set_command "reset_with count: 100"
    end

    args.state.star_count ||= 0

    # init
    if Kernel.tick_count == 0
      args.state.stars = args.state.star_count.map { |i| Star.new args.grid }
    end

    # update
    args.state.stars.each(&:move)

    # render
    args.outputs.sprites << args.state.stars
    args.outputs.background_color = [0, 0, 0]
    args.outputs.primitives << args.gtk.current_framerate_primitives
  end

  # resets game, and assigns star count given by user
  def reset_with count: count
    $gtk.reset
    $gtk.args.state.star_count = count
  end

```

### Static Sprites As Classes - main.rb
```ruby
  # ./samples/09_performance/06_static_sprites_as_classes/app/main.rb
  # Sprites represented as Classes using the queue ~args.outputs.static_sprites~.
  # bypasses the queue behavior of ~args.outputs.sprites~. All instances are held
  # by reference. You get better performance, but you are mutating state of held objects
  # which is less functional/data oriented.
  class Star
    attr_sprite

    def initialize grid
      @grid = grid
      @x = (rand @grid.w) * -1
      @y = (rand @grid.h) * -1
      @w    = 4
      @h    = 4
      @s    = 1 + (4.randomize :ratio)
      @path = 'sprites/tiny-star.png'
    end

    def move
      @x += @s
      @y += @s
      @x = (rand @grid.w) * -1 if @x > @grid.right
      @y = (rand @grid.h) * -1 if @y > @grid.top
    end
  end

  # calls methods needed for game to run properly
  def tick args
    # sets console command when sample app initially opens
    if Kernel.global_tick_count == 0
      puts ""
      puts ""
      puts "========================================================="
      puts "* INFO: Static Sprites, Classes"
      puts "* INFO: Please specify the number of sprites to render."
      args.gtk.console.set_command "reset_with count: 100"
    end

    args.state.star_count ||= 0

    # init
    if Kernel.tick_count == 0
      args.state.stars = args.state.star_count.map { |i| Star.new args.grid }
      args.outputs.static_sprites << args.state.stars
    end

    # update
    args.state.stars.each(&:move)

    # render
    args.outputs.background_color = [0, 0, 0]
    args.outputs.primitives << args.gtk.current_framerate_primitives
  end

  # resets game, and assigns star count given by user
  def reset_with count: count
    $gtk.reset
    $gtk.args.state.star_count = count
  end

```

### Static Sprites As Classes With Custom Drawing - main.rb
```ruby
  # ./samples/09_performance/07_static_sprites_as_classes_with_custom_drawing/app/main.rb
  # Sprites represented as Classes, with a draw_override method, and using the queue ~args.outputs.static_sprites~.
  # is the fastest approach. This is comparable to what other game engines set as the default behavior.
  # There are tradeoffs for all this speed if the creation of a full blown class, and bypassing
  # functional/data-oriented practices.
  class Star
    def initialize grid
      @grid = grid
      @x = (rand @grid.w) * -1
      @y = (rand @grid.h) * -1
      @w    = 4
      @h    = 4
      @s    = 1 + (4.randomize :ratio)
      @path = 'sprites/tiny-star.png'
    end

    def move
      @x += @s
      @y += @s
      @x = (rand @grid.w) * -1 if @x > @grid.right
      @y = (rand @grid.h) * -1 if @y > @grid.top
    end

    # if the object that is in args.outputs.sprites (or static_sprites)
    # respond_to? :draw_override, then the method is invoked giving you
    # access to the class used to draw to the canvas.
    def draw_override ffi_draw
      # first move then draw
      move

      # The argument order for ffi.draw_sprite is:
      # x, y, w, h, path
      ffi_draw.draw_sprite @x, @y, @w, @h, @path

      # The argument order for ffi_draw.draw_sprite_2 is (pass in nil for default value):
      # x, y, w, h, path,
      # angle, alpha

      # The argument order for ffi_draw.draw_sprite_3 is:
      # x, y, w, h,
      # path,
      # angle,
      # alpha, red_saturation, green_saturation, blue_saturation
      # tile_x, tile_y, tile_w, tile_h,
      # flip_horizontally, flip_vertically,
      # angle_anchor_x, angle_anchor_y,
      # source_x, source_y, source_w, source_h

      # The argument order for ffi_draw.draw_sprite_4 is:
      # x, y, w, h,
      # path,
      # angle,
      # alpha, red_saturation, green_saturation, blue_saturation
      # tile_x, tile_y, tile_w, tile_h,
      # flip_horizontally, flip_vertically,
      # angle_anchor_x, angle_anchor_y,
      # source_x, source_y, source_w, source_h,
      # blendmode_enum

      # The argument order for ffi_draw.draw_sprite_5 is:
      # x, y, w, h,
      # path,
      # angle,
      # alpha, red_saturation, green_saturation, blue_saturation
      # tile_x, tile_y, tile_w, tile_h,
      # flip_horizontally, flip_vertically,
      # angle_anchor_x, angle_anchor_y,
      # source_x, source_y, source_w, source_h,
      # blendmode_enum
      # anchor_x
      # anchor_y

      # The argument order for ffi_draw.draw_sprite_6 is:
      # x, y, w, h,
      # path,
      # angle,
      # alpha, red_saturation, green_saturation, blue_saturation
      # tile_x, tile_y, tile_w, tile_h,
      # flip_horizontally, flip_vertically,
      # angle_anchor_x, angle_anchor_y,
      # source_x, source_y, source_w, source_h,
      # blendmode_enum
      # anchor_x
      # anchor_y
      # scale_quality_enum
    end
  end

  # calls methods needed for game to run properly
  def tick args
    # sets console command when sample app initially opens
    if Kernel.global_tick_count == 0
      puts ""
      puts ""
      puts "========================================================="
      puts "* INFO: Static Sprites, Classes, Draw Override"
      puts "* INFO: Please specify the number of sprites to render."
      args.gtk.console.set_command "reset_with count: 100"
    end

    args.state.star_count ||= 0

    # init
    if Kernel.tick_count == 0
      args.state.stars = args.state.star_count.map { |i| Star.new args.grid }
      args.outputs.static_sprites << args.state.stars
    end

    # render framerate
    args.outputs.background_color = [0, 0, 0]
    args.outputs.primitives << args.gtk.current_framerate_primitives
  end

  # resets game, and assigns star count given by user
  def reset_with count: count
    $gtk.reset
    $gtk.args.state.star_count = count
  end

```

### Collision Limits - main.rb
```ruby
  # ./samples/09_performance/08_collision_limits/app/main.rb
  =begin

   Reminders:
   - find_all: Finds all elements of a collection that meet certain requirements.
     In this sample app, we're finding all bodies that intersect with the center body.

   - args.outputs.solids: An array. The values generate a solid.
     The parameters are [X, Y, WIDTH, HEIGHT, RED, GREEN, BLUE]
     For more information about solids, go to mygame/documentation/03-solids-and-borders.md.

   - args.outputs.labels: An array. The values generate a label.
     The parameters are [X, Y, TEXT, SIZE, ALIGNMENT, RED, GREEN, BLUE, ALPHA, FONT STYLE]
     For more information about labels, go to mygame/documentation/02-labels.md.

   - ARRAY#intersect_rect?: Returns true or false depending on if two rectangles intersect.

  =end

  # This code demonstrates moving objects that loop around once they exceed the scope of the screen,
  # which has dimensions of 1280 by 720, and also detects collisions between objects called "bodies".

  def body_count num
    $gtk.args.state.other_bodies = num.map { [1280 * rand, 720 * rand, 10, 10] } # other_bodies set using num collection
  end

  def tick args

    # Center body's values are set using an array
    # Map is used to set values of 5000 other bodies
    # All bodies that intersect with center body are stored in collisions collection
    args.state.center_body  ||= { x: 640 - 100, y: 360 - 100, w: 200, h: 200 } # calculations done to place body in center
    args.state.other_bodies ||= 5000.map do
      { x: 1280 * rand,
        y: 720 * rand,
        w: 2,
        h: 2,
        path: :pixel,
        r: 0,
        g: 0,
        b: 0 }
    end # 2000 bodies given random position on screen

    # finds all bodies that intersect with center body, stores them in collisions
    collisions = args.state.other_bodies.find_all { |b| b.intersect_rect? args.state.center_body }

    args.borders << args.state.center_body # outputs center body as a black border

    # transparency changes based on number of collisions; the more collisions, the redder (more transparent) the box becomes
    args.sprites  << { x: args.state.center_body.x,
                       y: args.state.center_body.y,
                       w: args.state.center_body.w,
                       h: args.state.center_body.h,
                       path: :pixel,
                       a: collisions.length.idiv(2), # alpha value represents the number of collisions that occured
                       r: 255,
                       g: 0,
                       b: 0 } # center body is red solid
    args.sprites  << args.state.other_bodies # other bodies are output as (black) solids, as well

    args.labels  << [10, 30, args.gtk.current_framerate.to_sf] # outputs frame rate in bottom left corner

    # Bodies are returned to bottom left corner if positions exceed scope of screen
    args.state.other_bodies.each do |b| # for each body in the other_bodies collection
      b.x += 5 # x and y are both incremented by 5
      b.y += 5
      b.x = 0 if b.x > 1280 # x becomes 0 if star exceeds scope of screen (goes too far right)
      b.y = 0 if b.y > 720 # y becomes 0 if star exceeds scope of screen (goes too far up)
    end
  end

  # Resets the game.
  $gtk.reset

```

### Collision Limits Aabb - main.rb
```ruby
  # ./samples/09_performance/09_collision_limits_aabb/app/main.rb
  def tick args
    args.state.id_seed    ||= 1
    args.state.bullets    ||= []
    args.state.terrain    ||= [
      {
        x: 40, y: 0, w: 1200, h: 40, path: :pixel, r: 0, g: 0, b: 0
      },
      {
        x: 1240, y: 0, w: 40, h: 720, path: :pixel, r: 0, g: 0, b: 0
      },
      {
        x: 0, y: 0, w: 40, h: 720, path: :pixel, r: 0, g: 0, b: 0
      },
      {
        x: 40, y: 680, w: 1200, h: 40, path: :pixel, r: 0, g: 0, b: 0
      },

      {
        x: 760, y: 420, w: 180, h: 40, path: :pixel, r: 0, g: 0, b: 0
      },
      {
        x: 720, y: 420, w: 40, h: 100, path: :pixel, r: 0, g: 0, b: 0
      },
      {
        x: 940, y: 420, w: 40, h: 100, path: :pixel, r: 0, g: 0, b: 0
      },

      {
        x: 660, y: 220, w: 280, h: 40, path: :pixel, r: 0, g: 0, b: 0
      },
      {
        x: 620, y: 220, w: 40, h: 100, path: :pixel, r: 0, g: 0, b: 0
      },
      {
        x: 940, y: 220, w: 40, h: 100, path: :pixel, r: 0, g: 0, b: 0
      },

      {
        x: 460, y: 40, w: 280, h: 40, path: :pixel, r: 0, g: 0, b: 0
      },
      {
        x: 420, y: 40, w: 40, h: 100, path: :pixel, r: 0, g: 0, b: 0
      },
      {
        x: 740, y: 40, w: 40, h: 100, path: :pixel, r: 0, g: 0, b: 0
      },
    ]

    if args.inputs.keyboard.space
        b = {
          id: args.state.id_seed,
          x: 60,
          y: 60,
          w: 10,
          h: 10,
          dy: rand(20) + 10,
          dx: rand(20) + 10,
          path: 'sprites/square/blue.png'
        }

        args.state.bullets << b # if b.id == 122

        args.state.id_seed += 1
    end

    terrain = args.state.terrain

    args.state.bullets.each do |b|
      next if b.still
      # if b.still
      #   x_dir = if rand > 0.5
      #             -1
      #           else
      #             1
      #           end

      #   y_dir = if rand > 0.5
      #             -1
      #           else
      #             1
      #           end

      #   b.dy = rand(20) + 10 * x_dir
      #   b.dx = rand(20) + 10 * y_dir
      #   b.still = false
      #   b.on_floor = false
      # end

      if b.on_floor
        b.dx *= 0.9
      end

      b.x += b.dx

      collision_x = args.geometry.find_intersect_rect(b, terrain)

      if collision_x
        if b.dx > 0
          b.x = collision_x.x - b.w
        elsif b.dx < 0
          b.x = collision_x.x + collision_x.w
        end
        b.dx *= -0.8
      end

      b.dy -= 0.25
      b.y += b.dy

      collision_y = args.geometry.find_intersect_rect(b, terrain)

      if collision_y
        if b.dy > 0
          b.y = collision_y.y - b.h
        elsif b.dy < 0
          b.y = collision_y.y + collision_y.h
        end

        if b.dy < 0 && b.dy.abs < 1
          b.on_floor = true
        end

        b.dy *= -0.8
      end

      if b.on_floor && (b.dy.abs + b.dx.abs) < 0.1
        b.still = true
      end
    end

    args.outputs.labels << { x: 60, y: 60.from_top, text: "Hold space bar to add squares." }
    args.outputs.labels << { x: 60, y: 90.from_top, text: "FPS: #{args.gtk.current_framerate.to_sf}" }
    args.outputs.labels << { x: 60, y: 120.from_top, text: "Count: #{args.state.bullets.length}" }
    args.outputs.borders << args.state.terrain
    args.outputs.sprites << args.state.bullets
  end

  # $gtk.reset

```

### Collision Limits Find Single - main.rb
```ruby
  # ./samples/09_performance/09_collision_limits_find_single/app/main.rb
  def tick args
    if args.state.should_reset_framerate_calculation
      args.gtk.reset_framerate_calculation
      args.state.should_reset_framerate_calculation = nil
    end

    if !args.state.rects
      args.state.rects = []
      add_10_000_random_rects args
    end

    args.state.player_rect ||= { x: 640 - 20, y: 360 - 20, w: 40, h: 40 }
    args.state.collision_type ||= :using_lambda

    if Kernel.tick_count == 0
      generate_scene args, args.state.quad_tree
    end

    # inputs
    # have a rectangle that can be moved around using arrow keys
    args.state.player_rect.x += args.inputs.left_right * 4
    args.state.player_rect.y += args.inputs.up_down * 4

    if args.inputs.mouse.click
      add_10_000_random_rects args
      args.state.should_reset_framerate_calculation = true
    end

    if args.inputs.keyboard.key_down.tab
      if args.state.collision_type == :using_lambda
        args.state.collision_type = :using_while_loop
      elsif args.state.collision_type == :using_while_loop
        args.state.collision_type = :using_find_intersect_rect
      elsif args.state.collision_type == :using_find_intersect_rect
        args.state.collision_type = :using_lambda
      end
      args.state.should_reset_framerate_calculation = true
    end

    # calc
    if args.state.collision_type == :using_lambda
      args.state.current_collision = args.state.rects.find { |r| r.intersect_rect? args.state.player_rect }
    elsif args.state.collision_type == :using_while_loop
      args.state.current_collision = nil
      idx = 0
      l = args.state.rects.length
      rects = args.state.rects
      player = args.state.player_rect
      while idx < l
        if rects[idx].intersect_rect? player
          args.state.current_collision = rects[idx]
          break
        end
        idx += 1
      end
    else
      args.state.current_collision = args.geometry.find_intersect_rect args.state.player_rect, args.state.rects
    end

    # render
    render_instructions args
    args.outputs.sprites << { x: 0, y: 0, w: 1280, h: 720, path: :scene }

    if args.state.current_collision
      args.outputs.sprites << args.state.current_collision.merge(path: :pixel, r: 255, g: 0, b: 0)
    end

    args.outputs.sprites << args.state.player_rect.merge(path: :pixel, a: 80, r: 0, g: 255, b: 0)
    args.outputs.labels  << {
      x: args.state.player_rect.x + args.state.player_rect.w / 2,
      y: args.state.player_rect.y + args.state.player_rect.h / 2,
      text: "player",
      alignment_enum: 1,
      vertical_alignment_enum: 1,
      size_enum: -4
    }

  end

  def add_10_000_random_rects args
    add_rects args, 10_000.map { { x: rand(1080) + 100, y: rand(520) + 100 } }
  end

  def add_rects args, points
    args.state.rects.concat(points.map { |point| { x: point.x, y: point.y, w: 5, h: 5 } })
    # args.state.quad_tree = args.geometry.quad_tree_create args.state.rects
    generate_scene args, args.state.quad_tree
  end

  def add_rect args, x, y
    args.state.rects << { x: x, y: y, w: 5, h: 5 }
    # args.state.quad_tree = args.geometry.quad_tree_create args.state.rects
    generate_scene args, args.state.quad_tree
  end

  def generate_scene args, quad_tree
    args.outputs[:scene].transient!
    args.outputs[:scene].w = 1280
    args.outputs[:scene].h = 720
    args.outputs[:scene].solids << { x: 0, y: 0, w: 1280, h: 720, r: 255, g: 255, b: 255 }
    args.outputs[:scene].sprites << args.state.rects.map { |r| r.merge(path: :pixel, r: 0, g: 0, b: 255) }
  end

  def render_instructions args
    args.outputs.primitives << { x:  0, y: 90.from_top, w: 1280, h: 100, r: 0, g: 0, b: 0, a: 200 }.solid!
    args.outputs.labels << { x: 10, y: 10.from_top, r: 255, g: 255, b: 255, size_enum: -2, text: "Click to add 10,000 random rects. Tab to change collision algorithm." }
    args.outputs.labels << { x: 10, y: 40.from_top, r: 255, g: 255, b: 255, size_enum: -2, text: "Algorithm: #{args.state.collision_type}" }
    args.outputs.labels << { x: 10, y: 55.from_top, r: 255, g: 255, b: 255, size_enum: -2, text: "Rect Count: #{args.state.rects.length}" }
    args.outputs.labels << { x: 10, y: 70.from_top, r: 255, g: 255, b: 255, size_enum: -2, text: "FPS: #{args.gtk.current_framerate.to_sf}" }
  end

```

### Collision Limits Many To Many - main.rb
```ruby
  # ./samples/09_performance/09_collision_limits_many_to_many/app/main.rb
  class Square
    attr_sprite

    def initialize
      @x    = rand 1280
      @y    = rand 720
      @w    = 15
      @h    = 15
      @path = 'sprites/square/blue.png'
      @dir = 1
    end

    def mark_collisions all
      @path = if all[self]
                'sprites/square/red.png'
              else
                'sprites/square/blue.png'
              end
    end

    def move
      @dir  = -1 if (@x + @w >= 1280) && @dir ==  1
      @dir  =  1 if (@x      <=    0) && @dir == -1
      @x   += @dir
    end
  end

  def reset_if_needed args
    if Kernel.tick_count == 0 || args.inputs.mouse.click
      args.state.star_count = 1500
      args.state.stars = args.state.star_count.map { |i| Square.new }.to_a
      args.outputs.static_sprites.clear
      args.outputs.static_sprites << args.state.stars
    end
  end

  def tick args
    reset_if_needed args

    Fn.each args.state.stars do |s| s.move end

    all = GTK::Geometry.find_collisions args.state.stars
    Fn.each args.state.stars do |s| s.mark_collisions all end

    args.outputs.background_color = [0, 0, 0]
    args.outputs.primitives << args.gtk.current_framerate_primitives
  end

```
