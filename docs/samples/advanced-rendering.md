### Render Targets Clip Area - main.rb
```ruby
  # ./samples/07_advanced_rendering/01_render_targets_clip_area/app/main.rb
  def tick args
    # define your state
    args.state.player ||= { x: 0, y: 0, w: 300, h: 300, path: "sprites/square/blue.png" }

    # controller input for player
    args.state.player.x += args.inputs.left_right * 5
    args.state.player.y += args.inputs.up_down * 5

    # create a render target that holds the
    # full view that you want to render

    # make the background transparent
    args.outputs[:clipped_area].background_color = [0, 0, 0, 0]

    # set the w/h to match the screen
    args.outputs[:clipped_area].w = 1280
    args.outputs[:clipped_area].h = 720

    # mark it as transient so that the render target
    # isn't cached (since we are going to be changing it every frame)
    args.outputs[:clipped_area].transient!

    # render the player in the render target
    args.outputs[:clipped_area].sprites << args.state.player

    # render the player and clip area as borders to
    # keep track of where everything is at regardless of clip mode
    args.outputs.borders << args.state.player
    args.outputs.borders << { x: 540, y: 460, w: 200, h: 200 }

    # render the render target, but only the clipped area
    args.outputs.sprites << {
      # where to render the render target
      x: 540,
      y: 460,
      w: 200,
      h: 200,
      # what part of the render target to render
      source_x: 540,
      source_y: 460,
      source_w: 200,
      source_h: 200,
      # path of render target to render
      path: :clipped_area
    }

    # mini map
    args.outputs.borders << { x: 1280 - 160, y: 0, w: 160, h: 90 }
    args.outputs.sprites << { x: 1280 - 160, y: 0, w: 160, h: 90, path: :clipped_area }
  end

  $gtk.reset

```

### Render Targets Combining Sprites - main.rb
```ruby
  # ./samples/07_advanced_rendering/01_render_targets_combining_sprites/app/main.rb
  # sample app shows how to use a render target to
  # create a combined sprite
  def tick args
    create_combined_sprite args

    # render the combined sprite
    # using its name :two_squares
    # have it move across the screen and rotate
    args.outputs.sprites << { x: Kernel.tick_count % 1280,
                              y: 0,
                              w: 80,
                              h: 80,
                              angle: Kernel.tick_count,
                              path: :two_squares }
  end

  def create_combined_sprite args
    # NOTE: you can have the construction of the combined
    #       sprite to happen every tick or only once (if the
    #       combined sprite never changes).
    #
    # if the combined sprite never changes, comment out the line
    # below to only construct it on the first frame and then
    # use the cached texture
    # return if Kernel.tick_count != 0 # <---- guard clause to only construct on first frame and cache

    # define the dimensions of the combined sprite
    # the name of the combined sprite is :two_squares
    args.outputs[:two_squares].transient!
    args.outputs[:two_squares].w = 80
    args.outputs[:two_squares].h = 80

    # put a blue sprite within the combined sprite
    # who's width is "thin"
    args.outputs[:two_squares].sprites << {
      x: 40 - 10,
      y: 0,
      w: 20,
      h: 80,
      path: 'sprites/square/blue.png'
    }

    # put a red sprite within the combined sprite
    # who's height is "thin"
    args.outputs[:two_squares].sprites << {
      x: 0,
      y: 40 - 10,
      w: 80,
      h: 20,
      path: 'sprites/square/red.png'
    }
  end

```

### Simple Render Targets - main.rb
```ruby
  # ./samples/07_advanced_rendering/01_simple_render_targets/app/main.rb
  def tick args
    # args.outputs.render_targets are really really powerful.
    # They essentially allow you to create a sprite programmatically and cache the result.

    # Create a render_target of a :block and a :gradient on tick zero.
    if Kernel.tick_count == 0
      args.render_target(:block).solids << [0, 0, 1280, 100]

      # The gradient is actually just a collection of black solids with increasing
      # opacities.
      args.render_target(:gradient).solids << 90.map_with_index do |x|
        50.map_with_index do |y|
          [x * 15, y * 15, 15, 15, 0, 0, 0, (x * 3).fdiv(255) * 255]
        end
      end
    end

    # Take the :block render_target and present it horizontally centered.
    # Use a subsection of the render_targetd specified by source_x,
    # source_y, source_w, source_h.
    args.outputs.sprites << { x: 0,
                              y: 310,
                              w: 1280,
                              h: 100,
                              path: :block,
                              source_x: 0,
                              source_y: 0,
                              source_w: 1280,
                              source_h: 100 }

    # After rendering :block, render gradient on top of :block.
    args.outputs.sprites << [0, 0, 1280, 720, :gradient]

    args.outputs.labels  << [1270, 710, args.gtk.current_framerate, 0, 2, 255, 255, 255]
    tick_instructions args, "Sample app shows how to use render_targets (programmatically create cached sprites)."
  end

  def tick_instructions args, text, y = 715
    return if args.state.key_event_occurred
    if args.inputs.mouse.click ||
       args.inputs.keyboard.directional_vector ||
       args.inputs.keyboard.key_down.enter ||
       args.inputs.keyboard.key_down.escape
      args.state.key_event_occurred = true
    end

    args.outputs.debug << [0, y - 50, 1280, 60].solid
    args.outputs.debug << [640, y, text, 1, 1, 255, 255, 255].label
    args.outputs.debug << [640, y - 25, "(click to dismiss instructions)" , -2, 1, 255, 255, 255].label
  end

  $gtk.reset

```

### Coordinate Systems And Render Targets - main.rb
```ruby
  # ./samples/07_advanced_rendering/02_coordinate_systems_and_render_targets/app/main.rb
  def tick args
    # every 4.5 seconds, swap between origin_bottom_left and origin_center
    args.state.origin_state ||= :bottom_left

    if Kernel.tick_count.zmod? 270
      args.state.origin_state = if args.state.origin_state == :bottom_left
                                  :center
                                else
                                  :bottom_left
                                end
    end

    if args.state.origin_state == :bottom_left
      tick_origin_bottom_left args
    else
      tick_origin_center args
    end
  end

  def tick_origin_center args
    # set the coordinate system to origin_center
    args.grid.origin_center!
    args.outputs.labels <<  { x: 0, y: 100, text: "args.grid.origin_center! with sprite inside of a render target, centered at 0, 0", vertical_alignment_enum: 1, alignment_enum: 1 }

    # create a render target with a sprint in the center assuming the origin is center screen
    args.outputs[:scene].transient!
    args.outputs[:scene].sprites << { x: -50, y: -50, w: 100, h: 100, path: 'sprites/square/blue.png' }
    args.outputs.sprites << { x: -640, y: -360, w: 1280, h: 720, path: :scene }
  end

  def tick_origin_bottom_left args
    args.grid.origin_bottom_left!
    args.outputs.labels <<  { x: 640, y: 360 + 100, text: "args.grid.origin_bottom_left! with sprite inside of a render target, centered at 640, 360", vertical_alignment_enum: 1, alignment_enum: 1 }

    # create a render target with a sprint in the center assuming the origin is bottom left
    args.outputs[:scene].transient!
    args.outputs[:scene].sprites << { x: 640 - 50, y: 360 - 50, w: 100, h: 100, path: 'sprites/square/blue.png' }
    args.outputs.sprites << { x: 0, y: 0, w: 1280, h: 720, path: :scene }
  end

```

### Render Targets Repeating Texture - main.rb
```ruby
  # ./samples/07_advanced_rendering/02_render_targets_repeating_texture/app/main.rb
  # Sample app shows how to leverage render targets to create a repeating
  # texture given a source sprite.
  def tick args
    args.outputs.sprites << repeating_texture(args,
                                              x: 640,
                                              y: 360,
                                              w: 1280,
                                              h: 720,
                                              anchor_x: 0.5,
                                              anchor_y: 0.5,
                                              path: 'sprites/square/blue.png')
  end

  def repeating_texture args, x:, y:, w:, h:, path:, anchor_x: 0, anchor_y: 0
    # create an area to store state for function
    args.state.repeating_texture_lookup ||= {}

    # create a unique name for the repeating texture
    rt_name = "#{path.hash}-#{w}-#{h}"

    # if the repeating texture has not been created yet, create it
    if args.state.repeating_texture_lookup[rt_name]
      return { x: x,
               y: y,
               w: w,
               h: h,
               anchor_x: anchor_x,
               anchor_y: anchor_y,
               path: rt_name }
    end

    # create a render target to store the repeating texture
    args.outputs[rt_name].w = w
    args.outputs[rt_name].h = h

    # calculate the sprite box for the repeating texture
    sprite_w, sprite_h = args.gtk.calcspritebox path

    # calculate the number of rows and columns needed to fill the repeating texture
    rows = h.idiv(sprite_h) + 1
    cols = w.idiv(sprite_w) + 1

    # generate the repeating texture using a render target
    # this only needs to be done once and will be cached
    args.outputs[rt_name].sprites << rows.map do |r|
                                       cols.map do |c|
                                         { x: sprite_w * c,
                                           y:  h - sprite_h * (r + 1),
                                           w: sprite_w,
                                           h: sprite_h,
                                           path: path }
                                       end
                                     end

    # store a flag in state denoting that the repeating
    # texture has been generated
    args.state.repeating_texture_lookup[rt_name] = true

    # return the repeating texture
    repeating_texture args, x: x, y: y, w: w, h: h, path: path
  end

  $gtk.reset

```

### Render Targets Thick Lines - main.rb
```ruby
  # ./samples/07_advanced_rendering/02_render_targets_thick_lines/app/main.rb
  # Sample app shows how you can use render targets to create arbitrary shapes like a thicker line
  def tick args
    args.state.line_cache ||= {}
    args.outputs.primitives << thick_line(args,
                                          args.state.line_cache,
                                          x: 0, y: 0, x2: 640, y2: 360, thickness: 3).merge(r: 0, g: 0, b: 0)
  end

  def thick_line args, cache, line
    line_length = Math.sqrt((line.x2 - line.x)**2 + (line.y2 - line.y)**2)
    name = "line-sprite-#{line_length}-#{line.thickness}"
    cached_line = cache[name]
    line_angle = Math.atan2(line.y2 - line.y, line.x2 - line.x) * 180 / Math::PI
    if cached_line
      perpendicular_angle = (line_angle + 90) % 360
      return cached_line.sprite.merge(x: line.x - perpendicular_angle.vector_x * (line.thickness / 2),
                                      y: line.y - perpendicular_angle.vector_y * (line.thickness / 2),
                                      angle: line_angle)
    end

    cache[name] = {
      line: line,
      thickness: line.thickness,
      sprite: {
        w: line_length,
        h: line.thickness,
        path: name,
        angle_anchor_x: 0,
        angle_anchor_y: 0
      }
    }

    args.outputs[name].w = line_length
    args.outputs[name].h = line.thickness
    args.outputs[name].solids << { x: 0, y: 0, w: line_length, h: line.thickness, r: 255, g: 255, b: 255 }
    return thick_line args, cache, line
  end

```

### Render Targets With Tile Manipulation - main.rb
```ruby
  # ./samples/07_advanced_rendering/02_render_targets_with_tile_manipulation/app/main.rb
  # This sample is meant to show you how to do that dripping transition thing
  #  at the start of the original Doom. Most of this file is here to animate
  #  a scene to wipe away; the actual wipe effect is in the last 20 lines or
  #  so.

  $gtk.reset   # reset all game state if reloaded.

  def circle_of_blocks pass, xoffset, yoffset, angleoffset, blocksize, distance
    numblocks = 10

    for i in 1..numblocks do
      angle = ((360 / numblocks) * i) + angleoffset
      radians = angle * (Math::PI / 180)
      x = (xoffset + (distance * Math.cos(radians))).round
      y = (yoffset + (distance * Math.sin(radians))).round
      pass.solids << [ x, y, blocksize, blocksize, 255, 255, 0 ]
    end
  end

  def draw_scene args, pass
    pass.solids << [0, 360, 1280, 360, 0, 0, 200]
    pass.solids << [0, 0, 1280, 360, 0, 127, 0]

    blocksize = 100
    angleoffset = Kernel.tick_count * 2.5
    centerx = (1280 - blocksize) / 2
    centery = (720 - blocksize) / 2

    circle_of_blocks pass, centerx, centery, angleoffset, blocksize * 2, 500
    circle_of_blocks pass, centerx, centery, angleoffset, blocksize, 325
    circle_of_blocks pass, centerx, centery, angleoffset, blocksize / 2, 200
    circle_of_blocks pass, centerx, centery, angleoffset, blocksize / 4, 100
  end

  def tick args
    segments = 160

    # On the first tick, initialize some stuff.
    if !args.state.yoffsets
      args.state.baseyoff = 0
      args.state.yoffsets = []
      for i in 0..segments do
        args.state.yoffsets << rand * 100
      end
    end

    # Just draw some random stuff for a few seconds.
    args.state.static_debounce ||= 60 * 2.5
    if args.state.static_debounce > 0
      last_frame = args.state.static_debounce == 1
      target = last_frame ? args.render_target(:last_frame) : args.outputs
      draw_scene args, target
      args.state.static_debounce -= 1
      return unless last_frame
    end

    # build up the wipe...

    # this is the thing we're wiping to.
    args.outputs.sprites << [ 0, 0, 1280, 720, 'dragonruby.png' ]

    return if (args.state.baseyoff > (1280 + 100))  # stop when done sliding

    segmentw = 1280 / segments

    x = 0
    for i in 0..segments do
      yoffset = 0
      if args.state.yoffsets[i] < args.state.baseyoff
        yoffset = args.state.baseyoff - args.state.yoffsets[i]
      end

      # (720 - yoffset) flips the coordinate system, (- 720) adjusts for the height of the segment.
      args.outputs.sprites << [ x, (720 - yoffset) - 720, segmentw, 720, 'last_frame', 0, 255, 255, 255, 255, x, 0, segmentw, 720 ]
      x += segmentw
    end

    args.state.baseyoff += 4

    tick_instructions args, "Sample app shows an advanced usage of render_target."
  end

  def tick_instructions args, text, y = 715
    return if args.state.key_event_occurred
    if args.inputs.mouse.click ||
       args.inputs.keyboard.directional_vector ||
       args.inputs.keyboard.key_down.enter ||
       args.inputs.keyboard.key_down.escape
      args.state.key_event_occurred = true
    end

    args.outputs.debug << [0, y - 50, 1280, 60].solid
    args.outputs.debug << [640, y, text, 1, 1, 255, 255, 255].label
    args.outputs.debug << [640, y - 25, "(click to dismiss instructions)" , -2, 1, 255, 255, 255].label
  end

```

### Render Target Viewports - main.rb
```ruby
  # ./samples/07_advanced_rendering/03_render_target_viewports/app/main.rb
  =begin

   APIs listing that haven't been encountered in previous sample apps:

   - args.state.new_entity: Used when we want to create a new object, like a sprite or button.
     For example, if we want to create a new button, we would declare it as a new entity and
     then define its properties. (Remember, you can use state to define ANY property and it will
     be retained across frames.)

     If you have a solar system and you're creating args.state.sun and setting its image path to an
     image in the sprites folder, you would do the following:
     (See samples/99_sample_nddnug_workshop for more details.)

     args.state.sun ||= args.state.new_entity(:sun) do |s|
     s.path = 'sprites/sun.png'
     end

   - String interpolation: Uses #{} syntax; everything between the #{ and the } is evaluated
     as Ruby code, and the placeholder is replaced with its corresponding value or result.

     For example, if we have a variable
     name = "Ruby"
     then the line
     puts "How are you, #{name}?"
     would print "How are you, Ruby?" to the console.
     (Remember, string interpolation only works with double quotes!)

   - Ternary operator (?): Similar to if statement; first evalulates whether a statement is
     true or false, and then executes a command depending on that result.
     For example, if we had a variable
     grade = 75
     and used the ternary operator in the command
     pass_or_fail = grade > 65 ? "pass" : "fail"
     then the value of pass_or_fail would be "pass" since grade's value was greater than 65.

   Reminders:

   - args.grid.(left|right|top|bottom): Pixel value for the boundaries of the virtual
     720 p screen (Dragon Ruby Game Toolkits's virtual resolution is always 1280x720).

   - Numeric#shift_(left|right|up|down): Shifts the Numeric in the correct direction
     by adding or subracting.

   - ARRAY#inside_rect?: An array with at least two values is considered a point. An array
     with at least four values is considered a rect. The inside_rect? function returns true
     or false depending on if the point is inside the rect.

   - ARRAY#intersect_rect?: Returns true or false depending on if the two rectangles intersect.

   - args.inputs.mouse.click: This property will be set if the mouse was clicked.
     For more information about the mouse, go to mygame/documentation/07-mouse.md.

   - args.inputs.keyboard.key_up.KEY: The value of the properties will be set
     to the frame  that the key_up event occurred (the frame correlates
     to Kernel.tick_count).
     For more information about the keyboard, go to mygame/documentation/06-keyboard.md.

   - args.state.labels:
     The parameters for a label are
     1. the position (x, y)
     2. the text
     3. the size
     4. the alignment
     5. the color (red, green, and blue saturations)
     6. the alpha (or transparency)
     For more information about labels, go to mygame/documentation/02-labels.md.

   - args.state.lines:
     The parameters for a line are
     1. the starting position (x, y)
     2. the ending position (x2, y2)
     3. the color (red, green, and blue saturations)
     4. the alpha (or transparency)
     For more information about lines, go to mygame/documentation/04-lines.md.

   - args.state.solids (and args.state.borders):
     The parameters for a solid (or border) are
     1. the position (x, y)
     2. the width (w)
     3. the height (h)
     4. the color (r, g, b)
     5. the alpha (or transparency)
     For more information about solids and borders, go to mygame/documentation/03-solids-and-borders.md.

   - args.state.sprites:
     The parameters for a sprite are
     1. the position (x, y)
     2. the width (w)
     3. the height (h)
     4. the image path
     5. the angle
     6. the alpha (or transparency)
     For more information about sprites, go to mygame/documentation/05-sprites.md.
  =end

  # This sample app shows different objects that can be used when making games, such as labels,
  # lines, sprites, solids, buttons, etc. Each demo section shows how these objects can be used.

  # Also note that Kernel.tick_count refers to the passage of time, or current frame.

  class TechDemo
    attr_accessor :inputs, :state, :outputs, :grid, :args

    # Calls all methods necessary for the app to run properly.
    def tick
      labels_tech_demo
      lines_tech_demo
      solids_tech_demo
      borders_tech_demo
      sprites_tech_demo
      keyboards_tech_demo
      controller_tech_demo
      mouse_tech_demo
      point_to_rect_tech_demo
      rect_to_rect_tech_demo
      button_tech_demo
      export_game_state_demo
      window_state_demo
      render_seperators
    end

    # Shows output of different kinds of labels on the screen
    def labels_tech_demo
      outputs.labels << [grid.left.shift_right(5), grid.top.shift_down(5), "This is a label located at the top left."]
      outputs.labels << [grid.left.shift_right(5), grid.bottom.shift_up(30), "This is a label located at the bottom left."]
      outputs.labels << [ 5, 690, "Labels (x, y, text, size, align, r, g, b, a)"]
      outputs.labels << [ 5, 660, "Smaller label.",  -2]
      outputs.labels << [ 5, 630, "Small label.",    -1]
      outputs.labels << [ 5, 600, "Medium label.",    0]
      outputs.labels << [ 5, 570, "Large label.",     1]
      outputs.labels << [ 5, 540, "Larger label.",    2]
      outputs.labels << [300, 660, "Left aligned.",    0, 2]
      outputs.labels << [300, 640, "Center aligned.",  0, 1]
      outputs.labels << [300, 620, "Right aligned.",   0, 0]
      outputs.labels << [175, 595, "Red Label.",       0, 0, 255,   0,   0]
      outputs.labels << [175, 575, "Green Label.",     0, 0,   0, 255,   0]
      outputs.labels << [175, 555, "Blue Label.",      0, 0,   0,   0, 255]
      outputs.labels << [175, 535, "Faded Label.",     0, 0,   0,   0,   0, 128]
    end

    # Shows output of lines on the screen
    def lines_tech_demo
      outputs.labels << [5, 500, "Lines (x, y, x2, y2, r, g, b, a)"]
      outputs.lines  << [5, 450, 100, 450]
      outputs.lines  << [5, 430, 300, 430]
      outputs.lines  << [5, 410, 300, 410, Kernel.tick_count % 255, 0, 0, 255] # red saturation changes
      outputs.lines  << [5, 390 - Kernel.tick_count % 25, 300, 390, 0, 0, 0, 255] # y position changes
      outputs.lines  << [5 + Kernel.tick_count % 200, 360, 300, 360, 0, 0, 0, 255] # x position changes
    end

    # Shows output of different kinds of solids on the screen
    def solids_tech_demo
      outputs.labels << [  5, 350, "Solids (x, y, w, h, r, g, b, a)"]
      outputs.solids << [ 10, 270, 50, 50]
      outputs.solids << [ 70, 270, 50, 50, 0, 0, 0]
      outputs.solids << [130, 270, 50, 50, 255, 0, 0]
      outputs.solids << [190, 270, 50, 50, 255, 0, 0, 128]
      outputs.solids << [250, 270, 50, 50, 0, 0, 0, 128 + Kernel.tick_count % 128] # transparency changes
    end

    # Shows output of different kinds of borders on the screen
    # The parameters for a border are the same as the parameters for a solid
    def borders_tech_demo
      outputs.labels <<  [  5, 260, "Borders (x, y, w, h, r, g, b, a)"]
      outputs.borders << [ 10, 180, 50, 50]
      outputs.borders << [ 70, 180, 50, 50, 0, 0, 0]
      outputs.borders << [130, 180, 50, 50, 255, 0, 0]
      outputs.borders << [190, 180, 50, 50, 255, 0, 0, 128]
      outputs.borders << [250, 180, 50, 50, 0, 0, 0, 128 + Kernel.tick_count % 128] # transparency changes
    end

    # Shows output of different kinds of sprites on the screen
    def sprites_tech_demo
      outputs.labels <<  [   5, 170, "Sprites (x, y, w, h, path, angle, a)"]
      outputs.sprites << [  10, 40, 128, 101, 'dragonruby.png']
      outputs.sprites << [ 150, 40, 128, 101, 'dragonruby.png', Kernel.tick_count % 360] # angle changes
      outputs.sprites << [ 300, 40, 128, 101, 'dragonruby.png', 0, Kernel.tick_count % 255] # transparency changes
    end

    # Holds size, alignment, color (black), and alpha (transparency) parameters
    # Using small_font as a parameter accounts for all remaining parameters
    # so they don't have to be repeatedly typed
    def small_font
      [-2, 0, 0, 0, 0, 255]
    end

    # Sets position of each row
    # Converts given row value to pixels that DragonRuby understands
    def row_to_px row_number

      # Row 0 starts 5 units below the top of the grid.
      # Each row afterward is 20 units lower.
      grid.top.shift_down(5).shift_down(20 * row_number)
    end

    # Uses labels to output current game time (passage of time), and whether or not "h" was pressed
    # If "h" is pressed, the frame is output when the key_up event occurred
    def keyboards_tech_demo
      outputs.labels << [460, row_to_px(0), "Current game time: #{Kernel.tick_count}", small_font]
      outputs.labels << [460, row_to_px(2), "Keyboard input: inputs.keyboard.key_up.h", small_font]
      outputs.labels << [460, row_to_px(3), "Press \"h\" on the keyboard.", small_font]

      if inputs.keyboard.key_up.h # if "h" key_up event occurs
        state.h_pressed_at = Kernel.tick_count # frame it occurred is stored
      end

      # h_pressed_at is initially set to false, and changes once the user presses the "h" key.
      state.h_pressed_at ||= false

      if state.h_pressed_at # if h is pressed (pressed_at has a frame number and is no longer false)
        outputs.labels << [460, row_to_px(4), "\"h\" was pressed at time: #{state.h_pressed_at}", small_font]
      else # otherwise, label says "h" was never pressed
        outputs.labels << [460, row_to_px(4), "\"h\" has never been pressed.", small_font]
      end

      # border around keyboard input demo section
      outputs.borders << [455, row_to_px(5), 360, row_to_px(2).shift_up(5) - row_to_px(5)]
    end

    # Sets definition for a small label
    # Makes it easier to position labels in respect to the position of other labels
    def small_label x, row, message
      [x, row_to_px(row), message, small_font]
    end

    # Uses small labels to show whether the "a" button on the controller is down, held, or up.
    # y value of each small label is set by calling the row_to_px method
    def controller_tech_demo
      x = 460
      outputs.labels << small_label(x, 6, "Controller one input: inputs.controller_one")
      outputs.labels << small_label(x, 7, "Current state of the \"a\" button.")
      outputs.labels << small_label(x, 8, "Check console window for more info.")

      if inputs.controller_one.key_down.a # if "a" is in "down" state
        outputs.labels << small_label(x, 9, "\"a\" button down: #{inputs.controller_one.key_down.a}")
        puts "\"a\" button down at #{inputs.controller_one.key_down.a}" # prints frame the event occurred
      elsif inputs.controller_one.key_held.a # if "a" is held down
        outputs.labels << small_label(x, 9, "\"a\" button held: #{inputs.controller_one.key_held.a}")
      elsif inputs.controller_one.key_up.a # if "a" is in up state
        outputs.labels << small_label(x, 9, "\"a\" button up: #{inputs.controller_one.key_up.a}")
        puts "\"a\" key up at #{inputs.controller_one.key_up.a}"
      else # if no event has occurred
        outputs.labels << small_label(x, 9, "\"a\" button state is nil.")
      end

      # border around controller input demo section
      outputs.borders << [455, row_to_px(10), 360, row_to_px(6).shift_up(5) - row_to_px(10)]
    end

    # Outputs when the mouse was clicked, as well as the coordinates on the screen
    # of where the click occurred
    def mouse_tech_demo
      x = 460

      outputs.labels << small_label(x, 11, "Mouse input: inputs.mouse")

      if inputs.mouse.click # if click has a value and is not nil
        state.last_mouse_click = inputs.mouse.click # coordinates of click are stored
      end

      if state.last_mouse_click # if mouse is clicked (has coordinates as value)
        # outputs the time (frame) the click occurred, as well as how many frames have passed since the event
        outputs.labels << small_label(x, 12, "Mouse click happened at: #{state.last_mouse_click.created_at}, #{state.last_mouse_click.created_at_elapsed}")
        # outputs coordinates of click
        outputs.labels << small_label(x, 13, "Mouse click location: #{state.last_mouse_click.point.x}, #{state.last_mouse_click.point.y}")
      else # otherwise if the mouse has not been clicked
        outputs.labels << small_label(x, 12, "Mouse click has not occurred yet.")
        outputs.labels << small_label(x, 13, "Please click mouse.")
      end
    end

    # Outputs whether a mouse click occurred inside or outside of a box
    def point_to_rect_tech_demo
      x = 460

      outputs.labels << small_label(x, 15, "Click inside the blue box maybe ---->")

      box = [765, 370, 50, 50, 0, 0, 170] # blue box
      outputs.borders << box

      if state.last_mouse_click # if the mouse was clicked
        if state.last_mouse_click.point.inside_rect? box # if mouse clicked inside box
          outputs.labels << small_label(x, 16, "Mouse click happened inside the box.")
        else # otherwise, if mouse was clicked outside the box
          outputs.labels << small_label(x, 16, "Mouse click happened outside the box.")
        end
      else # otherwise, if was not clicked at all
        outputs.labels << small_label(x, 16, "Mouse click has not occurred yet.") # output if the mouse was not clicked
      end

      # border around mouse input demo section
      outputs.borders << [455, row_to_px(14), 360, row_to_px(11).shift_up(5) - row_to_px(14)]
    end

    # Outputs a red box onto the screen. A mouse click from the user inside of the red box will output
    # a smaller box. If two small boxes are inside of the red box, it will be determined whether or not
    # they intersect.
    def rect_to_rect_tech_demo
      x = 460

      outputs.labels << small_label(x, 17.5, "Click inside the red box below.") # label with instructions
      red_box = [460, 250, 355, 90, 170, 0, 0] # definition of the red box
      outputs.borders << red_box # output as a border (not filled in)

      # If the mouse is clicked inside the red box, two collision boxes are created.
      if inputs.mouse.click
        if inputs.mouse.click.point.inside_rect? red_box
          if !state.box_collision_one # if the collision_one box does not yet have a definition
            # Subtracts 25 from the x and y positions of the click point in order to make the click point the center of the box.
            # You can try deleting the subtraction to see how it impacts the box placement.
            state.box_collision_one = [inputs.mouse.click.point.x - 25, inputs.mouse.click.point.y - 25, 50, 50, 180, 0,   0, 180]  # sets definition
          elsif !state.box_collision_two # if collision_two does not yet have a definition
            state.box_collision_two = [inputs.mouse.click.point.x - 25, inputs.mouse.click.point.y - 25, 50, 50,   0, 0, 180, 180] # sets definition
          else
            state.box_collision_one = nil # both boxes are empty
            state.box_collision_two = nil
          end
        end
      end

      # If collision boxes exist, they are output onto screen inside the red box as solids
      if state.box_collision_one
        outputs.solids << state.box_collision_one
      end

      if state.box_collision_two
        outputs.solids << state.box_collision_two
      end

      # Outputs whether or not the two collision boxes intersect.
      if state.box_collision_one && state.box_collision_two # if both collision_boxes are defined (and not nil or empty)
        if state.box_collision_one.intersect_rect? state.box_collision_two # if the two boxes intersect
          outputs.labels << small_label(x, 23.5, 'The boxes intersect.')
        else # otherwise, if the two boxes do not intersect
          outputs.labels << small_label(x, 23.5, 'The boxes do not intersect.')
        end
      else
        outputs.labels << small_label(x, 23.5, '--') # if the two boxes are not defined (are nil or empty), this label is output
      end
    end

    # Creates a button and outputs it onto the screen using labels and borders.
    # If the button is clicked, the color changes to make it look faded.
    def button_tech_demo
      x, y, w, h = 460, 160, 300, 50
      state.button        ||= state.new_entity(:button_with_fade)

      # Adds w.half to x and h.half + 10 to y in order to display the text inside the button's borders.
      state.button.label  ||= [x + w.half, y + h.half + 10, "click me and watch me fade", 0, 1]
      state.button.border ||= [x, y, w, h]

      if inputs.mouse.click && inputs.mouse.click.point.inside_rect?(state.button.border) # if mouse is clicked, and clicked inside button's border
        state.button.clicked_at = inputs.mouse.click.created_at # stores the time the click occurred
      end

      outputs.labels << state.button.label
      outputs.borders << state.button.border

      if state.button.clicked_at # if button was clicked (variable has a value and is not nil)

        # The appearance of the button changes for 0.25 seconds after the time the button is clicked at.
        # The color changes (rgb is set to 0, 180, 80) and the transparency gradually changes.
        # Change 0.25 to 1.25 and notice that the transparency takes longer to return to normal.
        outputs.solids << [x, y, w, h, 0, 180, 80, 255 * state.button.clicked_at.ease(0.25.seconds, :flip)]
      end
    end

    # Creates a new button by declaring it as a new entity, and sets values.
    def new_button_prefab x, y, message
      w, h = 300, 50
      button        = state.new_entity(:button_with_fade)
      button.label  = [x + w.half, y + h.half + 10, message, 0, 1] # '+ 10' keeps label's text within button's borders
      button.border = [x, y, w, h] # sets border definition
      button
    end

    # If the mouse has been clicked and the click's location is inside of the button's border, that means
    # that the button has been clicked. This method returns a boolean value.
    def button_clicked? button
      inputs.mouse.click && inputs.mouse.click.point.inside_rect?(button.border)
    end

    # Determines if button was clicked, and changes its appearance if it is clicked
    def tick_button_prefab button
      outputs.labels << button.label # outputs button's label and border
      outputs.borders << button.border

      if button_clicked? button # if button is clicked
        button.clicked_at = inputs.mouse.click.created_at # stores the time that the button was clicked
      end

      if button.clicked_at # if clicked_at has a frame value and is not nil
        # button is output; color changes and transparency changes for 0.25 seconds after click occurs
        outputs.solids << [button.border.x, button.border.y, button.border.w, button.border.h,
                           0, 180, 80, 255 * button.clicked_at.ease(0.25.seconds, :flip)] # transparency changes for 0.25 seconds
      end
    end

    # Exports the app's game state if the export button is clicked.
    def export_game_state_demo
      state.export_game_state_button ||= new_button_prefab(460, 100, "click to export app state")
      tick_button_prefab(state.export_game_state_button) # calls method to output button
      if button_clicked? state.export_game_state_button # if the export button is clicked
        args.gtk.export! "Exported from clicking the export button in the tech demo." # the export occurs
      end
    end

    # The mouse and keyboard focus are set to "yes" when the Dragonruby window is the active window.
    def window_state_demo
      m = $gtk.args.inputs.mouse.has_focus ? 'Y' : 'N' # ternary operator (similar to if statement)
      k = $gtk.args.inputs.keyboard.has_focus ? 'Y' : 'N'
      outputs.labels << [460, 20, "mouse focus: #{m}   keyboard focus: #{k}", small_font]
    end

    #Sets values for the horizontal separator (divides demo sections)
    def horizontal_seperator y, x, x2
      [x, y, x2, y, 150, 150, 150]
    end

    #Sets the values for the vertical separator (divides demo sections)
    def vertical_seperator x, y, y2
      [x, y, x, y2, 150, 150, 150]
    end

    # Outputs vertical and horizontal separators onto the screen to separate each demo section.
    def render_seperators
      outputs.lines << horizontal_seperator(505, grid.left, 445)
      outputs.lines << horizontal_seperator(353, grid.left, 445)
      outputs.lines << horizontal_seperator(264, grid.left, 445)
      outputs.lines << horizontal_seperator(174, grid.left, 445)

      outputs.lines << vertical_seperator(445, grid.top, grid.bottom)

      outputs.lines << horizontal_seperator(690, 445, 820)
      outputs.lines << horizontal_seperator(426, 445, 820)

      outputs.lines << vertical_seperator(820, grid.top, grid.bottom)
    end
  end

  $tech_demo = TechDemo.new

  def tick args
    $tech_demo.inputs = args.inputs
    $tech_demo.state = args.state
    $tech_demo.grid = args.grid
    $tech_demo.args = args
    $tech_demo.outputs = args.render_target(:mini_map)
    $tech_demo.outputs.transient = true
    $tech_demo.tick
    args.outputs.labels  << [830, 715, "Render target:", [-2, 0, 0, 0, 0, 255]]
    args.outputs.sprites << [0, 0, 1280, 720, :mini_map]
    args.outputs.sprites << [830, 300, 675, 379, :mini_map]
    tick_instructions args, "Sample app shows all the rendering apis available."
  end

  def tick_instructions args, text, y = 715
    return if args.state.key_event_occurred
    if args.inputs.mouse.click ||
       args.inputs.keyboard.directional_vector ||
       args.inputs.keyboard.key_down.enter ||
       args.inputs.keyboard.key_down.escape
      args.state.key_event_occurred = true
    end

    args.outputs.debug << [0, y - 50, 1280, 60].solid
    args.outputs.debug << [640, y, text, 1, 1, 255, 255, 255].label
    args.outputs.debug << [640, y - 25, "(click to dismiss instructions)" , -2, 1, 255, 255, 255].label
  end

```

### Render Primitive Hierarchies - main.rb
```ruby
  # ./samples/07_advanced_rendering/04_render_primitive_hierarchies/app/main.rb
  =begin

   APIs listing that haven't been encountered in previous sample apps:

   - Nested array: An array whose individual elements are also arrays; useful for
     storing groups of similar data.  Also called multidimensional arrays.

     In this sample app, we see nested arrays being used in object definitions.
     Notice the parameters for solids, listed below. Parameters 1-3 set the
     definition for the rect, and parameter 4 sets the definition of the color.

     Instead of having a solid definition that looks like this,
     [X, Y, W, H, R, G, B]
     we can separate it into two separate array definitions in one, like this
     [[X, Y, W, H], [R, G, B]]
     and both options work fine in defining our solid (or any object).

   - Collections: Lists of data; useful for organizing large amounts of data.
     One element of a collection could be an array (which itself contains many elements).
     For example, a collection that stores two solid objects would look like this:
     [
      [100, 100, 50, 50, 0, 0, 0],
      [100, 150, 50, 50, 255, 255, 255]
     ]
     If this collection was added to args.outputs.solids, two solids would be output
     next to each other, one black and one white.
     Nested arrays can be used in collections, as you will see in this sample app.

   Reminders:

   - args.outputs.solids: An array. The values generate a solid.
     The parameters for a solid are
     1. The position on the screen (x, y)
     2. The width (w)
     3. The height (h)
     4. The color (r, g, b) (if a color is not assigned, the object's default color will be black)
     NOTE: THE PARAMETERS ARE THE SAME FOR BORDERS!

     Here is an example of a (red) border or solid definition:
     [100, 100, 400, 500, 255, 0, 0]
     It will be a solid or border depending on if it is added to args.outputs.solids or args.outputs.borders.
     For more information about solids and borders, go to mygame/documentation/03-solids-and-borders.md.

   - args.outputs.sprites: An array. The values generate a sprite.
     The parameters for sprites are
     1. The position on the screen (x, y)
     2. The width (w)
     3. The height (h)
     4. The image path (p)

     Here is an example of a sprite definition:
     [100, 100, 400, 500, 'sprites/dragonruby.png']
     For more information about sprites, go to mygame/documentation/05-sprites.md.

  =end

  # This code demonstrates the creation and output of objects like sprites, borders, and solids
  # If filled in, they are solids
  # If hollow, they are borders
  # If images, they are sprites

  # Solids are added to args.outputs.solids
  # Borders are added to args.outputs.borders
  # Sprites are added to args.outputs.sprites

  # The tick method runs 60 frames every second.
  # Your game is going to happen under this one function.
  def tick args
    border_as_solid_and_solid_as_border args
    sprite_as_border_or_solids args
    collection_of_borders_and_solids args
    collection_of_sprites args
  end

  # Shows a border being output onto the screen as a border and a solid
  # Also shows how colors can be set
  def border_as_solid_and_solid_as_border args
    border = [0, 0, 50, 50]
    args.outputs.borders << border
    args.outputs.solids  << border

    # Red, green, blue saturations (last three parameters) can be any number between 0 and 255
    border_with_color = [0, 100, 50, 50, 255, 0, 0]
    args.outputs.borders << border_with_color
    args.outputs.solids  << border_with_color

    border_with_nested_color = [0, 200, 50, 50, [0, 255, 0]] # nested color
    args.outputs.borders << border_with_nested_color
    args.outputs.solids  << border_with_nested_color

    border_with_nested_rect = [[0, 300, 50, 50], 0, 0, 255] # nested rect
    args.outputs.borders << border_with_nested_rect
    args.outputs.solids  << border_with_nested_rect

    border_with_nested_color_and_rect = [[0, 400, 50, 50], [255, 0, 255]] # nested rect and color
    args.outputs.borders << border_with_nested_color_and_rect
    args.outputs.solids  << border_with_nested_color_and_rect
  end

  # Shows a sprite output onto the screen as a sprite, border, and solid
  # Demonstrates that all three outputs appear differently on screen
  def sprite_as_border_or_solids args
    sprite = [100, 0, 50, 50, 'sprites/ship.png']
    args.outputs.sprites << sprite

    # Sprite_as_border variable has same parameters (excluding position) as above object,
    # but will appear differently on screen because it is added to args.outputs.borders
    sprite_as_border = [100, 100, 50, 50, 'sprites/ship.png']
    args.outputs.borders << sprite_as_border

    # Sprite_as_solid variable has same parameters (excluding position) as above object,
    # but will appear differently on screen because it is added to args.outputs.solids
    sprite_as_solid = [100, 200, 50, 50, 'sprites/ship.png']
    args.outputs.solids << sprite_as_solid
  end

  # Holds and outputs a collection of borders and a collection of solids
  # Collections are created by using arrays to hold parameters of each individual object
  def collection_of_borders_and_solids args
    collection_borders = [
      [
        [200,  0, 50, 50],                    # black border
        [200,  100, 50, 50, 255, 0, 0],       # red border
        [200,  200, 50, 50, [0, 255, 0]],     # nested color
      ],
      [[200, 300, 50, 50], 0, 0, 255],        # nested rect
      [[200, 400, 50, 50], [255, 0, 255]]     # nested rect and nested color
    ]

    args.outputs.borders << collection_borders

    collection_solids = [
      [
        [[300, 300, 50, 50], 0, 0, 255],      # nested rect
        [[300, 400, 50, 50], [255, 0, 255]]   # nested rect and nested color
      ],
      [300,  0, 50, 50],
      [300,  100, 50, 50, 255, 0, 0],
      [300,  200, 50, 50, [0, 255, 0]],       # nested color
    ]

    args.outputs.solids << collection_solids
  end

  # Holds and outputs a collection of sprites by adding it to args.outputs.sprites
  # Also outputs a collection with same parameters (excluding position) by adding
  # it to args.outputs.solids and another to args.outputs.borders
  def collection_of_sprites args
    sprites_collection = [
      [
        [400, 0, 50, 50, 'sprites/ship.png'],
        [400, 100, 50, 50, 'sprites/ship.png'],
      ],
      [400, 200, 50, 50, 'sprites/ship.png']
    ]

    args.outputs.sprites << sprites_collection

    args.outputs.solids << [
      [500, 0, 50, 50, 'sprites/ship.png'],
      [500, 100, 50, 50, 'sprites/ship.png'],
      [[[500, 200, 50, 50, 'sprites/ship.png']]]
    ]

    args.outputs.borders << [
      [
        [600, 0, 50, 50, 'sprites/ship.png'],
        [600, 100, 50, 50, 'sprites/ship.png'],
      ],
      [600, 200, 50, 50, 'sprites/ship.png']
    ]
  end

```

### Render Primitives As Hash - main.rb
```ruby
  # ./samples/07_advanced_rendering/05_render_primitives_as_hash/app/main.rb
  =begin

   Reminders:

   - Hashes: Collection of unique keys and their corresponding values. The value can be found
     using their keys.

     For example, if we have a "numbers" hash that stores numbers in English as the
     key and numbers in Spanish as the value, we'd have a hash that looks like this...
     numbers = { "one" => "uno", "two" => "dos", "three" => "tres" }
     and on it goes.

     Now if we wanted to find the corresponding value of the "one" key, we could say
     puts numbers["one"]
     which would print "uno" to the console.

   - args.outputs.sprites: An array. The values generate a sprite.
     The parameters are [X, Y, WIDTH, HEIGHT, PATH, ANGLE, ALPHA, RED, GREEN, BLUE]
     For more information about sprites, go to mygame/documentation/05-sprites.md.

   - args.outputs.labels: An array. The values generate a label.
     The parameters are [X, Y, TEXT, SIZE, ALIGNMENT, RED, GREEN, BLUE, ALPHA, FONT STYLE]
     For more information about labels, go to mygame/documentation/02-labels.md.

   - args.outputs.solids: An array. The values generate a solid.
     The parameters are [X, Y, WIDTH, HEIGHT, RED, GREEN, BLUE, ALPHA]
     For more information about solids, go to mygame/documentation/03-solids-and-borders.md.

   - args.outputs.borders: An array. The values generate a border.
     The parameters are the same as a solid.
     For more information about borders, go to mygame/documentation/03-solids-and-borders.md.

   - args.outputs.lines: An array. The values generate a line.
     The parameters are [X, Y, X2, Y2, RED, GREEN, BLUE]
     For more information about labels, go to mygame/documentation/02-labels.md.

  =end

  # This sample app demonstrates how hashes can be used to output different kinds of objects.

  def tick args
    args.state.angle ||= 0 # initializes angle to 0
    args.state.angle  += 1 # increments angle by 1 every frame (60 times a second)

    # Outputs sprite using a hash
    args.outputs.sprites << {
      x: 30,                          # sprite position
      y: 550,
      w: 128,                         # sprite size
      h: 101,
      path: "dragonruby.png",         # image path
      angle: args.state.angle,        # angle
      a: 255,                         # alpha (transparency)
      r: 255,                         # color saturation
      g: 255,
      b: 255,
      tile_x:  0,                     # sprite sub division/tile
      tile_y:  0,
      tile_w: -1,
      tile_h: -1,
      flip_vertically: false,         # don't flip sprite
      flip_horizontally: false,
      angle_anchor_x: 0.5,            # rotation center set to middle
      angle_anchor_y: 0.5
    }

    # Outputs label using a hash
    args.outputs.labels << {
      x:              200,                 # label position
      y:              550,
      text:           "dragonruby",        # label text
      size_enum:      2,
      alignment_enum: 1,
      r:              155,                 # color saturation
      g:              50,
      b:              50,
      a:              255,                 # transparency
      font:           "fonts/manaspc.ttf"  # font style; without mentioned file, label won't output correctly
    }

    # Outputs solid using a hash
    # [X, Y, WIDTH, HEIGHT, RED, GREEN, BLUE, ALPHA]
    args.outputs.solids << {
      x: 400,                         # position
      y: 550,
      w: 160,                         # size
      h:  90,
      r: 120,                         # color saturation
      g:  50,
      b:  50,
      a: 255                          # transparency
    }

    # Outputs border using a hash
    # Same parameters as a solid
    args.outputs.borders << {
      x: 600,
      y: 550,
      w: 160,
      h:  90,
      r: 120,
      g:  50,
      b:  50,
      a: 255
    }

    # Outputs line using a hash
    args.outputs.lines << {
      x:  900,                        # starting position
      y:  550,
      x2: 1200,                       # ending position
      y2: 550,
      r:  120,                        # color saturation
      g:   50,
      b:   50,
      a:  255                         # transparency
    }

    # Outputs sprite as a primitive using a hash
    args.outputs.primitives << {
      x: 30,                          # position
      y: 200,
      w: 128,                         # size
      h: 101,
      path: "dragonruby.png",         # image path
      angle: args.state.angle,        # angle
      a: 255,                         # transparency
      r: 255,                         # color saturation
      g: 255,
      b: 255,
      tile_x:  0,                     # sprite sub division/tile
      tile_y:  0,
      tile_w: -1,
      tile_h: -1,
      flip_vertically: false,         # don't flip
      flip_horizontally: false,
      angle_anchor_x: 0.5,            # rotation center set to middle
      angle_anchor_y: 0.5
    }.sprite!

    # Outputs label as primitive using a hash
    args.outputs.primitives << {
      x:         200,                 # position
      y:         200,
      text:      "dragonruby",        # text
      size:      2,
      alignment: 1,
      r:         155,                 # color saturation
      g:         50,
      b:         50,
      a:         255,                 # transparency
      font:      "fonts/manaspc.ttf"  # font style
    }.label!

    # Outputs solid as primitive using a hash
    args.outputs.primitives << {
      x: 400,                         # position
      y: 200,
      w: 160,                         # size
      h:  90,
      r: 120,                         # color saturation
      g:  50,
      b:  50,
      a: 255                          # transparency
    }.solid!

    # Outputs border as primitive using a hash
    # Same parameters as solid
    args.outputs.primitives << {
      x: 600,                         # position
      y: 200,
      w: 160,                         # size
      h:  90,
      r: 120,                         # color saturation
      g:  50,
      b:  50,
      a: 255                          # transparency
    }.border!

    # Outputs line as primitive using a hash
    args.outputs.primitives << {
      x:  900,                        # starting position
      y:  200,
      x2: 1200,                       # ending position
      y2: 200,
      r:  120,                        # color saturation
      g:   50,
      b:   50,
      a:  255                         # transparency
    }.line!
  end

```

### Buttons As Render Targets - main.rb
```ruby
  # ./samples/07_advanced_rendering/06_buttons_as_render_targets/app/main.rb
  def tick args
    # create a texture/render_target that's composed of a border and a label
    create_button args, :hello_world_button, "Hello World", 500, 50

    # two button primitives using the hello_world_button render_target
    args.state.buttons ||= [
      # one button at the top
      { id: :top_button, x: 640 - 250, y: 80.from_top, w: 500, h: 50, path: :hello_world_button },

      # another button at the buttom, upside down, and flipped horizontally
      { id: :bottom_button, x: 640 - 250, y: 30, w: 500, h: 50, path: :hello_world_button, angle: 180, flip_horizontally: true },
    ]

    # check if a mouse click occurred
    if args.inputs.mouse.click
      # check to see if any of the buttons were intersected
      # and set the selected button if so
      args.state.selected_button = args.state.buttons.find { |b| b.intersect_rect? args.inputs.mouse }
    end

    # render the buttons
    args.outputs.sprites << args.state.buttons

    # if there was a selected button, print it's id
    if args.state.selected_button
      args.outputs.labels << { x: 30, y: 30.from_top, text: "#{args.state.selected_button.id} was clicked." }
    end
  end

  def create_button args, id, text, w, h
    # render_targets only need to be created once, we use the the id to determine if the texture
    # has already been created
    args.state.created_buttons ||= {}
    return if args.state.created_buttons[id]

    # if the render_target hasn't been created, then generate it and store it in the created_buttons cache
    args.state.created_buttons[id] = { created_at: Kernel.tick_count, id: id, w: w, h: h, text: text }

    # define the w/h of the texture
    args.outputs[id].w = w
    args.outputs[id].h = h

    # create a border
    args.outputs[id].borders << { x: 0, y: 0, w: w, h: h }

    # create a label centered vertically and horizontally within the texture
    args.outputs[id].labels << { x: w / 2, y: h / 2, text: text, vertical_alignment_enum: 1, alignment_enum: 1 }
  end

```

### Pixel Arrays - main.rb
```ruby
  # ./samples/07_advanced_rendering/06_pixel_arrays/app/main.rb
  def tick args
    args.state.posinc ||= 1
    args.state.pos ||= 0
    args.state.rotation ||= 0

    dimension = 10  # keep it small and let the GPU scale it when rendering the sprite.

    # Set up our "scanner" pixel array and fill it with black pixels.
    args.pixel_array(:scanner).width = dimension
    args.pixel_array(:scanner).height = dimension
    args.pixel_array(:scanner).pixels.fill(0xFF000000, 0, dimension * dimension)  # black, full alpha

    # Draw a green line that bounces up and down the sprite.
    args.pixel_array(:scanner).pixels.fill(0xFF00FF00, dimension * args.state.pos, dimension)  # green, full alpha

    # Adjust position for next frame.
    args.state.pos += args.state.posinc
    if args.state.posinc > 0 && args.state.pos >= dimension
      args.state.posinc = -1
      args.state.pos = dimension - 1
    elsif args.state.posinc < 0 && args.state.pos < 0
      args.state.posinc = 1
      args.state.pos = 1
    end

    # New/changed pixel arrays get uploaded to the GPU before we render
    #  anything. At that point, they can be scaled, rotated, and otherwise
    #  used like any other sprite.
    w = 100
    h = 100
    x = (1280 - w) / 2
    y = (720 - h) / 2
    args.outputs.background_color = [64, 0, 128]
    args.outputs.primitives << [x, y, w, h, :scanner, args.state.rotation].sprite
    args.state.rotation += 1

    args.outputs.primitives << args.gtk.current_framerate_primitives
  end


  $gtk.reset

```

### Pixel Arrays From File - main.rb
```ruby
  # ./samples/07_advanced_rendering/06_pixel_arrays_from_file/app/main.rb
  def tick args
    args.state.rotation ||= 0

    # on load, get pixels from png and load it into a pixel array
    if Kernel.tick_count == 0
      pixel_array = args.gtk.get_pixels 'sprites/square/blue.png'
      args.pixel_array(:square).w = pixel_array.w
      args.pixel_array(:square).h = pixel_array.h
      pixel_array.pixels.each_with_index do |p, i|
        args.pixel_array(:square).pixels[i] = p
      end
    end

    w = 100
    h = 100
    x = (1280 - w) / 2
    y = (720 - h) / 2
    args.outputs.background_color = [64, 0, 128]
    # render the pixel array by name
    args.outputs.primitives << { x: x, y: y, w: w, h: h, path: :square, angle: args.state.rotation }
    args.state.rotation += 1

    args.outputs.primitives << args.gtk.current_framerate_primitives
  end

  $gtk.reset

```

### Shake Camera - main.rb
```ruby
  # ./samples/07_advanced_rendering/07_shake_camera/app/main.rb
  # Demo of camera shake
  # Hold space to shake and release to stop

  class ScreenShake
    attr_gtk

    def tick
      defaults
      calc_camera

      outputs.labels << { x: 600, y: 400, text: "Hold Space!" }

      # Add outputs to :scene
      outputs[:scene].transient!
      outputs[:scene].sprites << { x: 100, y: 100,          w: 80, h: 80, path: 'sprites/square/blue.png' }
      outputs[:scene].sprites << { x: 200, y: 300.from_top, w: 80, h: 80, path: 'sprites/square/blue.png' }
      outputs[:scene].sprites << { x: 900, y: 200,          w: 80, h: 80, path: 'sprites/square/blue.png' }

      # Describe how to render :scene
      outputs.sprites << { x: 0 - state.camera.x_offset,
                           y: 0 - state.camera.y_offset,
                           w: 1280,
                           h: 720,
                           angle: state.camera.angle,
                           path: :scene }
    end

    def defaults
      state.camera.trauma ||= 0
      state.camera.angle ||= 0
      state.camera.x_offset ||= 0
      state.camera.y_offset ||= 0
    end

    def calc_camera
      if inputs.keyboard.key_held.space
        state.camera.trauma += 0.02
      end

      next_camera_angle = 180.0 / 20.0 * state.camera.trauma**2
      next_offset       = 100.0 * state.camera.trauma**2

      # Ensure that the camera angle always switches from
      # positive to negative and vice versa
      # which gives the effect of shaking back and forth
      state.camera.angle = state.camera.angle > 0 ?
                             next_camera_angle * -1 :
                             next_camera_angle

      state.camera.x_offset = next_offset.randomize(:sign, :ratio)
      state.camera.y_offset = next_offset.randomize(:sign, :ratio)

      # Gracefully degrade trauma
      state.camera.trauma *= 0.95
    end
  end

  def tick args
    $screen_shake ||= ScreenShake.new
    $screen_shake.args = args
    $screen_shake.tick
  end

```

### Simple Camera - main.rb
```ruby
  # ./samples/07_advanced_rendering/07_simple_camera/app/main.rb
  def tick args
    # variables you can play around with
    args.state.world.w      ||= 1280
    args.state.world.h      ||= 720

    args.state.player.x     ||= 0
    args.state.player.y     ||= 0
    args.state.player.size  ||= 32

    args.state.enemy.x      ||= 700
    args.state.enemy.y      ||= 700
    args.state.enemy.size   ||= 16

    args.state.camera.x                ||= 640
    args.state.camera.y                ||= 300
    args.state.camera.scale            ||= 1.0
    args.state.camera.show_empty_space ||= :yes

    # instructions
    args.outputs.primitives << { x: 0, y:  80.from_top, w: 360, h: 80, r: 0, g: 0, b: 0, a: 128 }.solid!
    args.outputs.primitives << { x: 10, y: 10.from_top, text: "arrow keys to move around", r: 255, g: 255, b: 255}.label!
    args.outputs.primitives << { x: 10, y: 30.from_top, text: "+/- to change zoom of camera", r: 255, g: 255, b: 255}.label!
    args.outputs.primitives << { x: 10, y: 50.from_top, text: "tab to change camera edge behavior", r: 255, g: 255, b: 255}.label!

    # render scene
    args.outputs[:scene].transient!
    args.outputs[:scene].w = args.state.world.w
    args.outputs[:scene].h = args.state.world.h

    args.outputs[:scene].solids << { x: 0, y: 0, w: args.state.world.w, h: args.state.world.h, r: 20, g: 60, b: 80 }
    args.outputs[:scene].solids << { x: args.state.player.x, y: args.state.player.y,
                                     w: args.state.player.size, h: args.state.player.size, r: 80, g: 155, b: 80 }
    args.outputs[:scene].solids << { x: args.state.enemy.x, y: args.state.enemy.y,
                                     w: args.state.enemy.size, h: args.state.enemy.size, r: 155, g: 80, b: 80 }

    # render camera
    scene_position = calc_scene_position args
    args.outputs.sprites << { x: scene_position.x,
                              y: scene_position.y,
                              w: scene_position.w,
                              h: scene_position.h,
                              path: :scene }

    # move player
    if args.inputs.directional_angle
      args.state.player.x += args.inputs.directional_angle.vector_x * 5
      args.state.player.y += args.inputs.directional_angle.vector_y * 5
      args.state.player.x  = args.state.player.x.clamp(0, args.state.world.w - args.state.player.size)
      args.state.player.y  = args.state.player.y.clamp(0, args.state.world.h - args.state.player.size)
    end

    # +/- to zoom in and out
    if args.inputs.keyboard.plus && Kernel.tick_count.zmod?(3)
      args.state.camera.scale += 0.05
    elsif args.inputs.keyboard.hyphen && Kernel.tick_count.zmod?(3)
      args.state.camera.scale -= 0.05
    elsif args.inputs.keyboard.key_down.tab
      if args.state.camera.show_empty_space == :yes
        args.state.camera.show_empty_space = :no
      else
        args.state.camera.show_empty_space = :yes
      end
    end

    args.state.camera.scale = args.state.camera.scale.greater(0.1)
  end

  def calc_scene_position args
    result = { x: args.state.camera.x - (args.state.player.x * args.state.camera.scale),
               y: args.state.camera.y - (args.state.player.y * args.state.camera.scale),
               w: args.state.world.w * args.state.camera.scale,
               h: args.state.world.h * args.state.camera.scale,
               scale: args.state.camera.scale }

    return result if args.state.camera.show_empty_space == :yes

    if result.w < args.grid.w
      result.merge!(x: (args.grid.w - result.w).half)
    elsif (args.state.player.x * result.scale) < args.grid.w.half
      result.merge!(x: 10)
    elsif (result.x + result.w) < args.grid.w
      result.merge!(x: - result.w + (args.grid.w - 10))
    end

    if result.h < args.grid.h
      result.merge!(y: (args.grid.h - result.h).half)
    elsif (result.y) > 10
      result.merge!(y: 10)
    elsif (result.y + result.h) < args.grid.h
      result.merge!(y: - result.h + (args.grid.h - 10))
    end

    result
  end

```

### Simple Camera Multiple Targets - main.rb
```ruby
  # ./samples/07_advanced_rendering/07_simple_camera_multiple_targets/app/main.rb
  def tick args
    args.outputs.background_color = [0, 0, 0]

    # variables you can play around with
    args.state.world.w                ||= 1280
    args.state.world.h                ||= 720
    args.state.target_hero            ||= :hero_1
    args.state.target_hero_changed_at ||= -30
    args.state.hero_size              ||= 32

    # initial state of heros and camera
    args.state.hero_1 ||= { x: 100, y: 100 }
    args.state.hero_2 ||= { x: 100, y: 600 }
    args.state.camera ||= { x: 640, y: 360, scale: 1.0 }

    # render instructions
    args.outputs.primitives << { x: 0,  y: 80.from_top, w: 360, h: 80, r: 0, g: 0, b: 0, a: 128 }.solid!
    args.outputs.primitives << { x: 10, y: 10.from_top, text: "+/- to change zoom of camera", r: 255, g: 255, b: 255}.label!
    args.outputs.primitives << { x: 10, y: 30.from_top, text: "arrow keys to move target hero", r: 255, g: 255, b: 255}.label!
    args.outputs.primitives << { x: 10, y: 50.from_top, text: "space to cycle target hero", r: 255, g: 255, b: 255}.label!

    # render scene
    args.outputs[:scene].transient!
    args.outputs[:scene].w = args.state.world.w
    args.outputs[:scene].h = args.state.world.h

    # render world
    args.outputs[:scene].solids << { x: 0, y: 0, w: args.state.world.w, h: args.state.world.h, r: 20, g: 60, b: 80 }

    # render hero_1
    args.outputs[:scene].solids << { x: args.state.hero_1.x, y: args.state.hero_1.y,
                                     w: args.state.hero_size, h: args.state.hero_size, r: 255, g: 155, b: 80 }

    # render hero_2
    args.outputs[:scene].solids << { x: args.state.hero_2.x, y: args.state.hero_2.y,
                                     w: args.state.hero_size, h: args.state.hero_size, r: 155, g: 255, b: 155 }

    # render scene relative to camera
    scene_position = calc_scene_position args

    args.outputs.sprites << { x: scene_position.x,
                              y: scene_position.y,
                              w: scene_position.w,
                              h: scene_position.h,
                              path: :scene }

    # mini map
    args.outputs.borders << { x: 10,
                              y: 10,
                              w: args.state.world.w.idiv(8),
                              h: args.state.world.h.idiv(8),
                              r: 255,
                              g: 255,
                              b: 255 }
    args.outputs.sprites << { x: 10,
                              y: 10,
                              w: args.state.world.w.idiv(8),
                              h: args.state.world.h.idiv(8),
                              path: :scene }

    # cycle target hero
    if args.inputs.keyboard.key_down.space
      if args.state.target_hero == :hero_1
        args.state.target_hero = :hero_2
      else
        args.state.target_hero = :hero_1
      end
      args.state.target_hero_changed_at = Kernel.tick_count
    end

    # move target hero
    hero_to_move = if args.state.target_hero == :hero_1
                     args.state.hero_1
                   else
                     args.state.hero_2
                   end

    if args.inputs.directional_angle
      hero_to_move.x += args.inputs.directional_angle.vector_x * 5
      hero_to_move.y += args.inputs.directional_angle.vector_y * 5
      hero_to_move.x  = hero_to_move.x.clamp(0, args.state.world.w - hero_to_move.size)
      hero_to_move.y  = hero_to_move.y.clamp(0, args.state.world.h - hero_to_move.size)
    end

    # +/- to zoom in and out
    if args.inputs.keyboard.plus && Kernel.tick_count.zmod?(3)
      args.state.camera.scale += 0.05
    elsif args.inputs.keyboard.hyphen && Kernel.tick_count.zmod?(3)
      args.state.camera.scale -= 0.05
    end

    args.state.camera.scale = 0.1 if args.state.camera.scale < 0.1
  end

  def other_hero args
    if args.state.target_hero == :hero_1
      return args.state.hero_2
    else
      return args.state.hero_1
    end
  end

  def calc_scene_position args
    target_hero = if args.state.target_hero == :hero_1
                    args.state.hero_1
                  else
                    args.state.hero_2
                  end

    other_hero = if args.state.target_hero == :hero_1
                   args.state.hero_2
                 else
                   args.state.hero_1
                 end

    # calculate the lerp percentage based on the time since the target hero changed
    lerp_percentage = args.easing.ease args.state.target_hero_changed_at,
                                       Kernel.tick_count,
                                       30,
                                       :smooth_stop_quint,
                                       :flip

    # calculate the angle and distance between the target hero and the other hero
    angle_to_other_hero = args.geometry.angle_to target_hero, other_hero

    # calculate the distance between the target hero and the other hero
    distance_to_other_hero = args.geometry.distance target_hero, other_hero

    # the camera position is the target hero position plus the angle and distance to the other hero (lerped)
    { x: args.state.camera.x - (target_hero.x + (angle_to_other_hero.vector_x * distance_to_other_hero * lerp_percentage)) * args.state.camera.scale,
      y: args.state.camera.y - (target_hero.y + (angle_to_other_hero.vector_y * distance_to_other_hero * lerp_percentage)) * args.state.camera.scale,
      w: args.state.world.w * args.state.camera.scale,
      h: args.state.world.h * args.state.camera.scale }
  end

```

### Splitscreen Camera - main.rb
```ruby
  # ./samples/07_advanced_rendering/08_splitscreen_camera/app/main.rb
  class CameraMovement
    attr_accessor :state, :inputs, :outputs, :grid

    #==============================================================================================
    #Serialize
    def serialize
      {state: state, inputs: inputs, outputs: outputs, grid: grid }
    end

    def inspect
      serialize.to_s
    end

    def to_s
      serialize.to_s
    end

    #==============================================================================================
    #Tick
    def tick
      defaults
      calc
      render
      input
    end

    #==============================================================================================
    #Default functions
    def defaults
      outputs[:scene].transient!
      outputs[:scene].background_color = [0,0,0]
      state.trauma ||= 0.0
      state.trauma_power ||= 2
      state.player_cyan ||= new_player_cyan
      state.player_magenta ||= new_player_magenta
      state.camera_magenta ||= new_camera_magenta
      state.camera_cyan ||= new_camera_cyan
      state.camera_center ||= new_camera_center
      state.room ||= new_room
    end

    def default_player x, y, w, h, sprite_path
      state.new_entity(:player,
                       { x: x,
                         y: y,
                         dy: 0,
                         dx: 0,
                         w: w,
                         h: h,
                         damage: 0,
                         dead: false,
                         orientation: "down",
                         max_alpha: 255,
                         sprite_path: sprite_path})
    end

    def default_floor_tile x, y, w, h, sprite_path
      state.new_entity(:room,
                       { x: x,
                         y: y,
                         w: w,
                         h: h,
                         sprite_path: sprite_path})
    end

    def default_camera x, y, w, h
      state.new_entity(:camera,
                       { x: x,
                         y: y,
                         dx: 0,
                         dy: 0,
                         w: w,
                         h: h})
    end

    def new_player_cyan
      default_player(0, 0, 64, 64,
                     "sprites/player/player_#{state.player_cyan.orientation}_standing.png")
    end

    def new_player_magenta
      default_player(64, 0, 64, 64,
                     "sprites/player/player_#{state.player_magenta.orientation}_standing.png")
    end

    def new_camera_magenta
      default_camera(0,0,720,720)
    end

    def new_camera_cyan
      default_camera(0,0,720,720)
    end

    def new_camera_center
      default_camera(0,0,1280,720)
    end


    def new_room
      default_floor_tile(0,0,1024,1024,'sprites/rooms/camera_room.png')
    end

    #==============================================================================================
    #Calculation functions
    def calc
      calc_camera_magenta
      calc_camera_cyan
      calc_camera_center
      calc_player_cyan
      calc_player_magenta
      calc_trauma_decay
    end

    def center_camera_tolerance
      return Math.sqrt(((state.player_magenta.x - state.player_cyan.x) ** 2) +
                ((state.player_magenta.y - state.player_cyan.y) ** 2)) > 640
    end

    def calc_player_cyan
      state.player_cyan.x += state.player_cyan.dx
      state.player_cyan.y += state.player_cyan.dy
    end

    def calc_player_magenta
      state.player_magenta.x += state.player_magenta.dx
      state.player_magenta.y += state.player_magenta.dy
    end

    def calc_camera_center
      timeScale = 1
      midX = (state.player_magenta.x + state.player_cyan.x)/2
      midY = (state.player_magenta.y + state.player_cyan.y)/2
      targetX = midX - state.camera_center.w/2
      targetY = midY - state.camera_center.h/2
      state.camera_center.x += (targetX - state.camera_center.x) * 0.1 * timeScale
      state.camera_center.y += (targetY - state.camera_center.y) * 0.1 * timeScale
    end


    def calc_camera_magenta
      timeScale = 1
      targetX = state.player_magenta.x + state.player_magenta.w - state.camera_magenta.w/2
      targetY = state.player_magenta.y + state.player_magenta.h - state.camera_magenta.h/2
      state.camera_magenta.x += (targetX - state.camera_magenta.x) * 0.1 * timeScale
      state.camera_magenta.y += (targetY - state.camera_magenta.y) * 0.1 * timeScale
    end

    def calc_camera_cyan
      timeScale = 1
      targetX = state.player_cyan.x + state.player_cyan.w - state.camera_cyan.w/2
      targetY = state.player_cyan.y + state.player_cyan.h - state.camera_cyan.h/2
      state.camera_cyan.x += (targetX - state.camera_cyan.x) * 0.1 * timeScale
      state.camera_cyan.y += (targetY - state.camera_cyan.y) * 0.1 * timeScale
    end

    def calc_player_quadrant angle
      if angle < 45 and angle > -45 and state.player_cyan.x < state.player_magenta.x
        return 1
      elsif angle < 45 and angle > -45 and state.player_cyan.x > state.player_magenta.x
        return 3
      elsif (angle > 45 or angle < -45) and state.player_cyan.y < state.player_magenta.y
        return 2
      elsif (angle > 45 or angle < -45) and state.player_cyan.y > state.player_magenta.y
        return 4
      end
    end

    def calc_camera_shake
      state.trauma
    end

    def calc_trauma_decay
      state.trauma = state.trauma * 0.9
    end

    def calc_random_float_range(min, max)
      rand * (max-min) + min
    end

    #==============================================================================================
    #Render Functions
    def render
      render_floor
      render_player_cyan
      render_player_magenta
      if center_camera_tolerance
        render_split_camera_scene
      else
        render_camera_center_scene
      end
    end

    def render_player_cyan
      outputs[:scene].sprites << {x: state.player_cyan.x,
                                  y: state.player_cyan.y,
                                  w: state.player_cyan.w,
                                  h: state.player_cyan.h,
                                  path: "sprites/player/player_#{state.player_cyan.orientation}_standing.png",
                                  r: 0,
                                  g: 255,
                                  b: 255}
    end

    def render_player_magenta
      outputs[:scene].sprites << {x: state.player_magenta.x,
                                  y: state.player_magenta.y,
                                  w: state.player_magenta.w,
                                  h: state.player_magenta.h,
                                  path: "sprites/player/player_#{state.player_magenta.orientation}_standing.png",
                                  r: 255,
                                  g: 0,
                                  b: 255}
    end

    def render_floor
      outputs[:scene].sprites << [state.room.x, state.room.y,
                                  state.room.w, state.room.h,
                                  state.room.sprite_path]
    end

    def render_camera_center_scene
      zoomFactor = 1
      outputs[:scene].width = state.room.w
      outputs[:scene].height = state.room.h

      maxAngle = 10.0
      maxOffset = 20.0
      angle = maxAngle * calc_camera_shake * calc_random_float_range(-1,1)
      offsetX = 32 - (maxOffset * calc_camera_shake * calc_random_float_range(-1,1))
      offsetY = 32 - (maxOffset * calc_camera_shake * calc_random_float_range(-1,1))

      outputs.sprites << {x: (-state.camera_center.x - offsetX)/zoomFactor,
                          y: (-state.camera_center.y - offsetY)/zoomFactor,
                          w: outputs[:scene].width/zoomFactor,
                          h: outputs[:scene].height/zoomFactor,
                          path: :scene,
                          angle: angle,
                          source_w: -1,
                          source_h: -1}
      outputs.labels << [128,64,"#{state.trauma.round(1)}",8,2,255,0,255,255]
    end

    def render_split_camera_scene
       outputs[:scene].width = state.room.w
       outputs[:scene].height = state.room.h
       render_camera_magenta_scene
       render_camera_cyan_scene

       angle = Math.atan((state.player_magenta.y - state.player_cyan.y)/(state.player_magenta.x- state.player_cyan.x)) * 180/Math::PI
       output_split_camera angle

    end

    def render_camera_magenta_scene
       zoomFactor = 1
       offsetX = 32
       offsetY = 32

       outputs[:scene_magenta].transient!
       outputs[:scene_magenta].sprites << {x: (-state.camera_magenta.x*2),
                                           y: (-state.camera_magenta.y),
                                           w: outputs[:scene].width*2,
                                           h: outputs[:scene].height,
                                           path: :scene}

    end

    def render_camera_cyan_scene
      zoomFactor = 1
      offsetX = 32
      offsetY = 32
      outputs[:scene_cyan].transient!
      outputs[:scene_cyan].sprites << {x: (-state.camera_cyan.x*2),
                                       y: (-state.camera_cyan.y),
                                       w: outputs[:scene].width*2,
                                       h: outputs[:scene].height,
                                       path: :scene}
    end

    def output_split_camera angle
      #TODO: Clean this up!
      quadrant = calc_player_quadrant angle
      outputs.labels << [128,64,"#{quadrant}",8,2,255,0,255,255]
      if quadrant == 1
        set_camera_attributes(w: 640, h: 720, m_x: 640, m_y: 0, c_x: 0, c_y: 0)

      elsif quadrant == 2
        set_camera_attributes(w: 1280, h: 360, m_x: 0, m_y: 360, c_x: 0, c_y: 0)

      elsif quadrant == 3
        set_camera_attributes(w: 640, h: 720, m_x: 0, m_y: 0, c_x: 640, c_y: 0)

      elsif quadrant == 4
        set_camera_attributes(w: 1280, h: 360, m_x: 0, m_y: 0, c_x: 0, c_y: 360)

      end
    end

    def set_camera_attributes(w: 0, h: 0, m_x: 0, m_y: 0, c_x: 0, c_y: 0)
      state.camera_cyan.w = w + 64
      state.camera_cyan.h = h + 64
      outputs[:scene_cyan].width = (w) * 2
      outputs[:scene_cyan].height = h

      state.camera_magenta.w = w + 64
      state.camera_magenta.h = h + 64
      outputs[:scene_magenta].width = (w) * 2
      outputs[:scene_magenta].height = h
      outputs.sprites << {x: m_x,
                          y: m_y,
                          w: w,
                          h: h,
                          path: :scene_magenta}
      outputs.sprites << {x: c_x,
                          y: c_y,
                          w: w,
                          h: h,
                          path: :scene_cyan}
    end

    def add_trauma amount
      state.trauma = [state.trauma + amount, 1.0].min
    end

    def remove_trauma amount
      state.trauma = [state.trauma - amount, 0.0].max
    end
    #==============================================================================================
    #Input functions
    def input
      input_move_cyan
      input_move_magenta

      if inputs.keyboard.key_down.t
        add_trauma(0.5)
      elsif inputs.keyboard.key_down.y
        remove_trauma(0.1)
      end
    end

    def input_move_cyan
      if inputs.keyboard.key_held.up
        state.player_cyan.dy = 5
        state.player_cyan.orientation = "up"
      elsif inputs.keyboard.key_held.down
        state.player_cyan.dy = -5
        state.player_cyan.orientation = "down"
      else
        state.player_cyan.dy *= 0.8
      end
      if inputs.keyboard.key_held.left
        state.player_cyan.dx = -5
        state.player_cyan.orientation = "left"
      elsif inputs.keyboard.key_held.right
        state.player_cyan.dx = 5
        state.player_cyan.orientation = "right"
      else
        state.player_cyan.dx *= 0.8
      end

      outputs.labels << [128,512,"#{state.player_cyan.x.round()}",8,2,0,255,255,255]
      outputs.labels << [128,480,"#{state.player_cyan.y.round()}",8,2,0,255,255,255]
    end

    def input_move_magenta
      if inputs.keyboard.key_held.w
        state.player_magenta.dy = 5
        state.player_magenta.orientation = "up"
      elsif inputs.keyboard.key_held.s
        state.player_magenta.dy = -5
        state.player_magenta.orientation = "down"
      else
        state.player_magenta.dy *= 0.8
      end
      if inputs.keyboard.key_held.a
        state.player_magenta.dx = -5
        state.player_magenta.orientation = "left"
      elsif inputs.keyboard.key_held.d
        state.player_magenta.dx = 5
        state.player_magenta.orientation = "right"
      else
        state.player_magenta.dx *= 0.8
      end

      outputs.labels << [128,360,"#{state.player_magenta.x.round()}",8,2,255,0,255,255]
      outputs.labels << [128,328,"#{state.player_magenta.y.round()}",8,2,255,0,255,255]
    end
  end

  $camera_movement = CameraMovement.new

  def tick args
    args.outputs.background_color = [0,0,0]
    $camera_movement.inputs  = args.inputs
    $camera_movement.outputs = args.outputs
    $camera_movement.state   = args.state
    $camera_movement.grid    = args.grid
    $camera_movement.tick
  end

```

### Z Targeting Camera - main.rb
```ruby
  # ./samples/07_advanced_rendering/09_z_targeting_camera/app/main.rb
  class Game
    attr_gtk

    def tick
      defaults
      render
      input
      calc
    end

    def defaults
      outputs.background_color = [219, 208, 191]
      player.x        ||= 634
      player.y        ||= 153
      player.angle    ||= 90
      player.distance ||= arena_radius
      target.x        ||= 634
      target.y        ||= 359
    end

    def render
      outputs[:scene].transient!
      outputs[:scene].sprites << ({ x: 0, y: 0, w: 933, h: 700, path: 'sprites/arena.png' }.center_inside_rect grid.rect)
      outputs[:scene].sprites << target_sprite
      outputs[:scene].sprites << player_sprite
      outputs.sprites << scene
    end

    def target_sprite
      {
        x: target.x, y: target.y,
        w: 10, h: 10,
        path: 'sprites/square/black.png'
      }.anchor_rect 0.5, 0.5
    end

    def input
      if inputs.up && player.distance > 30
        player.distance -= 2
      elsif inputs.down && player.distance < 200
        player.distance += 2
      end

      player.angle += inputs.left_right * -1
    end

    def calc
      player.x = target.x + ((player.angle *  1).vector_x player.distance)
      player.y = target.y + ((player.angle * -1).vector_y player.distance)
    end

    def player_sprite
      {
        x: player.x,
        y: player.y,
        w: 50,
        h: 100,
        path: 'sprites/player.png',
        angle: (player.angle * -1) + 90
      }.anchor_rect 0.5, 0
    end

    def center_map
      { x: 634, y: 359 }
    end

    def zoom_factor_single
      2 - ((args.geometry.distance player, center_map).fdiv arena_radius)
    end

    def zoom_factor
      zoom_factor_single ** 2
    end

    def arena_radius
      206
    end

    def scene
      {
        x:    (640 - player.x) + (640 - (640 * zoom_factor)),
        y:    (360 - player.y - (75 * zoom_factor)) + (320 - (320 * zoom_factor)),
        w:    1280 * zoom_factor,
        h:     720 * zoom_factor,
        path: :scene,
        angle: player.angle - 90,
        angle_anchor_x: (player.x.fdiv 1280),
        angle_anchor_y: (player.y.fdiv 720)
      }
    end

    def player
      state.player
    end

    def target
      state.target
    end
  end

  def tick args
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

  $gtk.reset

```

### Camera And Large Map - main.rb
```ruby
  # ./samples/07_advanced_rendering/10_camera_and_large_map/app/main.rb
  def tick args
    # you want to make sure all of your pngs are a maximum size of 1280x1280
    # low-end android devices and machines with underpowered GPUs are unable to
    # load very large textures.

    # this sample app creates 640x640 tiles of a 6400x6400 pixel png and displays them
    # on the screen relative to the player's position

    # tile creation process
    create_tiles_if_needed args

    # if tiles are already present the show map
    display_tiles args
  end

  def display_tiles args
    # set the player's starting location
    args.state.player ||= {
      x:  0,
      y:  0,
      w: 40,
      h: 40,
      path: "sprites/square/blue.png"
    }

    # if all tiles have been created, then we are
    # in "displaying_tiles" mode
    if args.state.displaying_tiles
      # create a render target that can hold 9 640x640 tiles
      args.outputs[:scene].transient!
      args.outputs[:scene].background_color = [0, 0, 0, 0]
      args.outputs[:scene].w = 1920
      args.outputs[:scene].h = 1920

      # allow player to be moved with arrow keys
      args.state.player.x += args.inputs.left_right * 10
      args.state.player.y += args.inputs.up_down * 10

      # given the player's location, return a collection of primitives
      # to render that are within the 1920x1920 viewport
      args.outputs[:scene].primitives << tiles_in_viewport(args)

      # place the player in the center of the render_target
      args.outputs[:scene].primitives << {
        x: 960 - 20,
        y: 960 - 20,
        w: 40,
        h: 40,
        path: "sprites/square/blue.png"
      }

      # center the 1920x1920 render target within the 1280x720 window
      args.outputs.sprites << {
        x: -320,
        y: -600,
        w: 1920,
        h: 1920,
        path: :scene
      }
    end
  end

  def tiles_in_viewport args
    state = args.state
    # define the size of each tile
    tile_size = 640

    # determine what tile the player is on
    tile_player_is_on = { x: state.player.x.idiv(tile_size), y: state.player.y.idiv(tile_size) }

    # calculate the x and y offset of the player so that tiles are positioned correctly
    offset_x = 960 - (state.player.x - (tile_player_is_on.x * tile_size))
    offset_y = 960 - (state.player.y - (tile_player_is_on.y * tile_size))

    primitives = []

    # get 9 tiles in total (the tile the player is on and the 8 surrounding tiles)

    # center tile
    primitives << (tile_in_viewport size:       tile_size,
                                    from_row:   tile_player_is_on.y,
                                    from_col:   tile_player_is_on.x,
                                    offset_row: 0,
                                    offset_col: 0,
                                    dy:         offset_y,
                                    dx:         offset_x)

    # tile to the right
    primitives << (tile_in_viewport size:       tile_size,
                                    from_row:   tile_player_is_on.y,
                                    from_col:   tile_player_is_on.x,
                                    offset_row: 0,
                                    offset_col: 1,
                                    dy:         offset_y,
                                    dx:         offset_x)
    # tile to the left
    primitives << (tile_in_viewport size:        tile_size,
                                    from_row:    tile_player_is_on.y,
                                    from_col:    tile_player_is_on.x,
                                    offset_row:  0,
                                    offset_col: -1,
                                    dy:          offset_y,
                                    dx:          offset_x)

    # tile directly above
    primitives << (tile_in_viewport size:       tile_size,
                                    from_row:   tile_player_is_on.y,
                                    from_col:   tile_player_is_on.x,
                                    offset_row: 1,
                                    offset_col: 0,
                                    dy:         offset_y,
                                    dx:         offset_x)
    # tile directly below
    primitives << (tile_in_viewport size:         tile_size,
                                    from_row:     tile_player_is_on.y,
                                    from_col:     tile_player_is_on.x,
                                    offset_row:  -1,
                                    offset_col:   0,
                                    dy:           offset_y,
                                    dx:           offset_x)
    # tile up and to the left
    primitives << (tile_in_viewport size:        tile_size,
                                    from_row:    tile_player_is_on.y,
                                    from_col:    tile_player_is_on.x,
                                    offset_row:  1,
                                    offset_col: -1,
                                    dy:          offset_y,
                                    dx:          offset_x)

    # tile up and to the right
    primitives << (tile_in_viewport size:       tile_size,
                                    from_row:   tile_player_is_on.y,
                                    from_col:   tile_player_is_on.x,
                                    offset_row: 1,
                                    offset_col: 1,
                                    dy:         offset_y,
                                    dx:         offset_x)

    # tile down and to the left
    primitives << (tile_in_viewport size:        tile_size,
                                    from_row:    tile_player_is_on.y,
                                    from_col:    tile_player_is_on.x,
                                    offset_row: -1,
                                    offset_col: -1,
                                    dy:          offset_y,
                                    dx:          offset_x)

    # tile down and to the right
    primitives << (tile_in_viewport size:        tile_size,
                                    from_row:    tile_player_is_on.y,
                                    from_col:    tile_player_is_on.x,
                                    offset_row: -1,
                                    offset_col:  1,
                                    dy:          offset_y,
                                    dx:          offset_x)

    primitives
  end

  def tile_in_viewport size:, from_row:, from_col:, offset_row:, offset_col:, dy:, dx:;
    x = size * offset_col + dx
    y = size * offset_row + dy

    return nil if (from_row + offset_row) < 0
    return nil if (from_row + offset_row) > 9

    return nil if (from_col + offset_col) < 0
    return nil if (from_col + offset_col) > 9

    # return the tile sprite, a border demarcation, and label of which tile x and y
    [
      {
        x: x,
        y: y,
        w: size,
        h: size,
        path: "sprites/tile-#{from_col + offset_col}-#{from_row + offset_row}.png",
      },
      {
        x: x,
        y: y,
        w: size,
        h: size,
        r: 255,
        primitive_marker: :border,
      },
      {
        x: x + size / 2 - 150,
        y: y + size / 2 - 25,
        w: 300,
        h: 50,
        primitive_marker: :solid,
        r: 0,
        g: 0,
        b: 0,
        a: 128
      },
      {
        x: x + size / 2,
        y: y + size / 2,
        text: "tile #{from_col + offset_col}, #{from_row + offset_row}",
        alignment_enum: 1,
        vertical_alignment_enum: 1,
        size_enum: 2,
        r: 255,
        g: 255,
        b: 255
      },
    ]
  end

  def create_tiles_if_needed args
    # We are going to use args.outputs.screenshots to generate tiles of a
    # png of size 6400x6400 called sprites/large.png.
    if !args.gtk.stat_file("sprites/tile-9-9.png") && !args.state.creating_tiles
      args.state.displaying_tiles = false
      args.outputs.labels << {
        x: 960,
        y: 360,
        text: "Press enter to generate tiles of sprites/large.png.",
        alignment_enum: 1,
        vertical_alignment_enum: 1
      }
    elsif !args.state.creating_tiles
      args.state.displaying_tiles = true
    end

    # pressing enter will start the tile creation process
    if args.inputs.keyboard.key_down.enter && !args.state.creating_tiles
      args.state.displaying_tiles = false
      args.state.creating_tiles = true
      args.state.tile_clock = 0
    end

    # the tile creation process renders an area of sprites/large.png
    # to the screen and takes a screenshot of it every half second
    # until all tiles are generated.
    # once all tiles are generated a map viewport will be rendered that
    # stitches tiles together.
    if args.state.creating_tiles
      args.state.tile_x ||= 0
      args.state.tile_y ||= 0

      # render a sub-square of the large png.
      args.outputs.sprites << {
        x: 0,
        y: 0,
        w: 640,
        h: 640,
        source_x: args.state.tile_x * 640,
        source_y: args.state.tile_y * 640,
        source_w: 640,
        source_h: 640,
        path: "sprites/large.png"
      }

      # determine tile file name
      tile_path = "sprites/tile-#{args.state.tile_x}-#{args.state.tile_y}.png"

      args.outputs.labels << {
        x: 960,
        y: 320,
        text: "Generating #{tile_path}",
        alignment_enum: 1,
        vertical_alignment_enum: 1
      }

      # take a screenshot on frames divisible by 29
      if args.state.tile_clock.zmod?(29)
        args.outputs.screenshots << {
          x: 0,
          y: 0,
          w: 640,
          h: 640,
          path: tile_path,
          a: 255
        }
      end

      # increment tile to render on frames divisible by 30 (half a second)
      # (one frame is allotted to take screenshot)
      if args.state.tile_clock.zmod?(30)
        args.state.tile_x += 1
        if args.state.tile_x >= 10
          args.state.tile_x  = 0
          args.state.tile_y += 1
        end

        # once all of tile tiles are created, begin displaying map
        if args.state.tile_y >= 10
          args.state.creating_tiles = false
          args.state.displaying_tiles = true
        end
      end

      args.state.tile_clock += 1
    end
  end

  $gtk.reset

```

### Blend Modes - main.rb
```ruby
  # ./samples/07_advanced_rendering/11_blend_modes/app/main.rb
  $gtk.reset

  def draw_blendmode args, mode
    w = 160
    h = w
    args.state.x += (1280-w) / (args.state.blendmodes.length + 1)
    x = args.state.x
    y = (720 - h) / 2
    s = 'sprites/blue-feathered.png'
    args.outputs.sprites << { blendmode_enum: mode.value, x: x, y: y, w: w, h: h, path: s }
    args.outputs.labels << [x + (w/2), y, mode.name.to_s, 1, 1, 255, 255, 255]
  end

  def tick args

    # Different blend modes do different things, depending on what they
    # blend against (in this case, the pixels of the background color).
    args.state.bg_element ||= 1
    args.state.bg_color ||= 255
    args.state.bg_color_direction ||= 1
    bg_r = (args.state.bg_element == 1) ? args.state.bg_color : 0
    bg_g = (args.state.bg_element == 2) ? args.state.bg_color : 0
    bg_b = (args.state.bg_element == 3) ? args.state.bg_color : 0
    args.state.bg_color += args.state.bg_color_direction
    if (args.state.bg_color_direction > 0) && (args.state.bg_color >= 255)
      args.state.bg_color_direction = -1
      args.state.bg_color = 255
    elsif (args.state.bg_color_direction < 0) && (args.state.bg_color <= 0)
      args.state.bg_color_direction = 1
      args.state.bg_color = 0
      args.state.bg_element += 1
      if args.state.bg_element >= 4
        args.state.bg_element = 1
      end
    end

    args.outputs.background_color = [ bg_r, bg_g, bg_b, 255 ]

    args.state.blendmodes ||= [
      { name: :none,  value: 0 },
      { name: :blend, value: 1 },
      { name: :add,   value: 2 },
      { name: :mod,   value: 3 },
      { name: :mul,   value: 4 }
    ]

    args.state.x = 0  # reset this, draw_blendmode will increment it.
    args.state.blendmodes.each { |blendmode| draw_blendmode args, blendmode }
  end

```

### Render Target Noclear - main.rb
```ruby
  # ./samples/07_advanced_rendering/12_render_target_noclear/app/main.rb
  def tick args
    args.state.x ||= 500
    args.state.y ||= 350
    args.state.xinc ||= 7
    args.state.yinc ||= 7
    args.state.bgcolor ||= 1
    args.state.bginc ||= 1

    # clear the render target on the first tick, and then never again. Draw
    #  another box to it every tick, accumulating over time.
    clear_target = (Kernel.tick_count == 0) || (args.inputs.keyboard.key_down.space)
    args.render_target(:accumulation).transient = true
    args.render_target(:accumulation).background_color = [ 0, 0, 0, 0 ];
    args.render_target(:accumulation).clear_before_render = clear_target
    args.render_target(:accumulation).solids << [args.state.x, args.state.y, 25, 25, 255, 0, 0, 255];
    args.state.x += args.state.xinc
    args.state.y += args.state.yinc
    args.state.bgcolor += args.state.bginc

    # animation upkeep...change where we draw the next box and what color the
    #  window background will be.
    if args.state.xinc > 0 && args.state.x >= 1280
      args.state.xinc = -7
    elsif args.state.xinc < 0 && args.state.x < 0
      args.state.xinc = 7
    end

    if args.state.yinc > 0 && args.state.y >= 720
      args.state.yinc = -7
    elsif args.state.yinc < 0 && args.state.y < 0
      args.state.yinc = 7
    end

    if args.state.bginc > 0 && args.state.bgcolor >= 255
      args.state.bginc = -1
    elsif args.state.bginc < 0 && args.state.bgcolor <= 0
      args.state.bginc = 1
    end

    # clear the screen to a shade of blue and draw the render target, which
    #  is not clearing every frame, on top of it. Note that you can NOT opt to
    #  skip clearing the screen, only render targets. The screen clears every
    #  frame; double-buffering would prevent correct updates between frames.
    args.outputs.background_color = [ 0, 0, args.state.bgcolor, 255 ]
    args.outputs.sprites << [ 0, 0, 1280, 720, :accumulation ]
  end

  $gtk.reset

```

### Lighting - main.rb
```ruby
  # ./samples/07_advanced_rendering/13_lighting/app/main.rb
  def calc args
    args.state.swinging_light_sign     ||= 1
    args.state.swinging_light_start_at ||= 0
    args.state.swinging_light_duration ||= 300
    args.state.swinging_light_perc       = args.state
                                               .swinging_light_start_at
                                               .ease_spline_extended Kernel.tick_count,
                                                                     args.state.swinging_light_duration,
                                                                     [
                                                                       [0.0, 1.0, 1.0, 1.0],
                                                                       [1.0, 1.0, 1.0, 0.0]
                                                                     ]
    args.state.max_swing_angle ||= 45

    if args.state.swinging_light_start_at.elapsed_time > args.state.swinging_light_duration
      args.state.swinging_light_start_at = Kernel.tick_count
      args.state.swinging_light_sign *= -1
    end

    args.state.swinging_light_angle = 360 + ((args.state.max_swing_angle * args.state.swinging_light_perc) * args.state.swinging_light_sign)
  end

  def render args
    args.outputs.background_color = [0, 0, 0]

    # render scene
    args.outputs[:scene].transient!
    args.outputs[:scene].sprites << { x:        0, y:   0, w: 1280, h: 720, path: :pixel }
    args.outputs[:scene].sprites << { x: 640 - 40, y: 100, w:   80, h:  80, path: 'sprites/square/blue.png' }
    args.outputs[:scene].sprites << { x: 640 - 40, y: 200, w:   80, h:  80, path: 'sprites/square/blue.png' }
    args.outputs[:scene].sprites << { x: 640 - 40, y: 300, w:   80, h:  80, path: 'sprites/square/blue.png' }
    args.outputs[:scene].sprites << { x: 640 - 40, y: 400, w:   80, h:  80, path: 'sprites/square/blue.png' }
    args.outputs[:scene].sprites << { x: 640 - 40, y: 500, w:   80, h:  80, path: 'sprites/square/blue.png' }

    # render light
    swinging_light_w = 1100
    args.outputs[:lights].transient!
    args.outputs[:lights].background_color = [0, 0, 0, 0]
    args.outputs[:lights].sprites << { x: 640 - swinging_light_w.half,
                                       y: -1300,
                                       w: swinging_light_w,
                                       h: 3000,
                                       angle_anchor_x: 0.5,
                                       angle_anchor_y: 1.0,
                                       path: "sprites/lights/mask.png",
                                       angle: args.state.swinging_light_angle }

    args.outputs[:lights].sprites << { x: args.inputs.mouse.x - 400,
                                       y: args.inputs.mouse.y - 400,
                                       w: 800,
                                       h: 800,
                                       path: "sprites/lights/mask.png" }

    # merge unlighted scene with lights
    args.outputs[:lighted_scene].transient!
    args.outputs[:lighted_scene].sprites << { x: 0, y: 0, w: 1280, h: 720, path: :lights, blendmode_enum: 0 }
    args.outputs[:lighted_scene].sprites << { blendmode_enum: 2, x: 0, y: 0, w: 1280, h: 720, path: :scene }

    # output lighted scene to main canvas
    args.outputs.sprites << { x: 0, y: 0, w: 1280, h: 720, path: :lighted_scene }

    # render lights and scene render_targets as a mini map
    args.outputs.debug  << { x: 16,      y: (16 + 90).from_top, w: 160, h: 90, r: 255, g: 255, b: 255 }.solid!
    args.outputs.debug  << { x: 16,      y: (16 + 90).from_top, w: 160, h: 90, path: :lights }
    args.outputs.debug  << { x: 16 + 80, y: (16 + 90 + 8).from_top, text: ":lights render_target", r: 255, g: 255, b: 255, size_enum: -3, alignment_enum: 1 }

    args.outputs.debug  << { x: 16 + 160 + 16,      y: (16 + 90).from_top, w: 160, h: 90, r: 255, g: 255, b: 255 }.solid!
    args.outputs.debug  << { x: 16 + 160 + 16,      y: (16 + 90).from_top, w: 160, h: 90, path: :scene }
    args.outputs.debug  << { x: 16 + 160 + 16 + 80, y: (16 + 90 + 8).from_top, text: ":scene render_target", r: 255, g: 255, b: 255, size_enum: -3, alignment_enum: 1 }
  end

  def tick args
    render args
    calc args
  end

  $gtk.reset

```

### Triangles - main.rb
```ruby
  # ./samples/07_advanced_rendering/14_triangles/app/main.rb
  def tick args
    args.outputs.labels << {
      x: 640,
      y: 30.from_top,
      text: "Triangle rendering is available in Indie and Pro versions (ignored in Standard Edition).",
      alignment_enum: 1
    }

    dragonruby_logo_width  = 128
    dragonruby_logo_height = 101

    row_0 = 400
    row_1 = 250

    col_0 = 384 - dragonruby_logo_width.half + dragonruby_logo_width * 0
    col_1 = 384 - dragonruby_logo_width.half + dragonruby_logo_width * 1
    col_2 = 384 - dragonruby_logo_width.half + dragonruby_logo_width * 2
    col_3 = 384 - dragonruby_logo_width.half + dragonruby_logo_width * 3
    col_4 = 384 - dragonruby_logo_width.half + dragonruby_logo_width * 4

    # row 0
    args.outputs.solids << make_triangle(
      col_0,
      row_0,
      col_0 + dragonruby_logo_width.half,
      row_0 + dragonruby_logo_height,
      col_0 + dragonruby_logo_width.half + dragonruby_logo_width.half,
      row_0,
      0, 128, 128,
      128
    )

    args.outputs.solids << {
      x:  col_1,
      y:  row_0,
      x2: col_1 + dragonruby_logo_width.half,
      y2: row_0 + dragonruby_logo_height,
      x3: col_1 + dragonruby_logo_width,
      y3: row_0,
    }

    args.outputs.sprites << {
      x:  col_2,
      y:  row_0,
      w:  dragonruby_logo_width,
      h:  dragonruby_logo_height,
      path: 'dragonruby.png'
    }

    args.outputs.sprites << {
      x:  col_3,
      y:  row_0,
      x2: col_3 + dragonruby_logo_width.half,
      y2: row_0 + dragonruby_logo_height,
      x3: col_3 + dragonruby_logo_width,
      y3: row_0,
      path: 'dragonruby.png',
      source_x:  0,
      source_y:  0,
      source_x2: dragonruby_logo_width.half,
      source_y2: dragonruby_logo_height,
      source_x3: dragonruby_logo_width,
      source_y3: 0
    }

    args.outputs.sprites << TriangleLogo.new(x:  col_4,
                                             y:  row_0,
                                             x2: col_4 + dragonruby_logo_width.half,
                                             y2: row_0 + dragonruby_logo_height,
                                             x3: col_4 + dragonruby_logo_width,
                                             y3: row_0,
                                             path: 'dragonruby.png',
                                             source_x:  0,
                                             source_y:  0,
                                             source_x2: dragonruby_logo_width.half,
                                             source_y2: dragonruby_logo_height,
                                             source_x3: dragonruby_logo_width,
                                             source_y3: 0)

    # row 1
    args.outputs.primitives << make_triangle(
      col_0,
      row_1,
      col_0 + dragonruby_logo_width.half,
      row_1 + dragonruby_logo_height,
      col_0 + dragonruby_logo_width,
      row_1,
      0, 128, 128,
      Kernel.tick_count.to_radians.sin_r.abs * 255
    )

    args.outputs.primitives << {
      x:  col_1,
      y:  row_1,
      x2: col_1 + dragonruby_logo_width.half,
      y2: row_1 + dragonruby_logo_height,
      x3: col_1 + dragonruby_logo_width,
      y3: row_1,
      r:  0, g: 0, b: 0, a: Kernel.tick_count.to_radians.sin_r.abs * 255
    }

    args.outputs.sprites << {
      x:  col_2,
      y:  row_1,
      w:  dragonruby_logo_width,
      h:  dragonruby_logo_height,
      path: 'dragonruby.png',
      source_x:  0,
      source_y:  0,
      source_w:  dragonruby_logo_width,
      source_h:  dragonruby_logo_height.half +
                 dragonruby_logo_height.half * Math.sin(Kernel.tick_count.to_radians).abs,
    }

    args.outputs.primitives << {
      x:  col_3,
      y:  row_1,
      x2: col_3 + dragonruby_logo_width.half,
      y2: row_1 + dragonruby_logo_height,
      x3: col_3 + dragonruby_logo_width,
      y3: row_1,
      path: 'dragonruby.png',
      source_x:  0,
      source_y:  0,
      source_x2: dragonruby_logo_width.half,
      source_y2: dragonruby_logo_height.half +
                 dragonruby_logo_height.half * Math.sin(Kernel.tick_count.to_radians).abs,
      source_x3: dragonruby_logo_width,
      source_y3: 0
    }

    args.outputs.primitives << TriangleLogo.new(x:  col_4,
                                                y:  row_1,
                                                x2: col_4 + dragonruby_logo_width.half,
                                                y2: row_1 + dragonruby_logo_height,
                                                x3: col_4 + dragonruby_logo_width,
                                                y3: row_1,
                                                path: 'dragonruby.png',
                                                source_x:  0,
                                                source_y:  0,
                                                source_x2: dragonruby_logo_width.half,
                                                source_y2: dragonruby_logo_height.half +
                                                           dragonruby_logo_height.half * Math.sin(Kernel.tick_count.to_radians).abs,
                                                source_x3: dragonruby_logo_width,
                                                source_y3: 0)
  end

  def make_triangle *opts
    x, y, x2, y2, x3, y3, r, g, b, a = opts
    {
      x: x, y: y, x2: x2, y2: y2, x3: x3, y3: y3,
      r: r || 0,
      g: g || 0,
      b: b || 0,
      a: a || 255
    }
  end

  class TriangleLogo
    attr_sprite

    def initialize x:, y:, x2:, y2:, x3:, y3:, path:, source_x:, source_y:, source_x2:, source_y2:, source_x3:, source_y3:;
      @x         = x
      @y         = y
      @x2        = x2
      @y2        = y2
      @x3        = x3
      @y3        = y3
      @path      = path
      @source_x  = source_x
      @source_y  = source_y
      @source_x2 = source_x2
      @source_y2 = source_y2
      @source_x3 = source_x3
      @source_y3 = source_y3
    end
  end

```

### Triangles Trapezoid - main.rb
```ruby
  # ./samples/07_advanced_rendering/15_triangles_trapezoid/app/main.rb
  def tick args
    args.outputs.labels << {
      x: 640,
      y: 30.from_top,
      text: "Triangle rendering is available in Indie and Pro versions (ignored in Standard Edition).",
      alignment_enum: 1
    }

    transform_scale = ((Kernel.tick_count / 3).sin.abs ** 5).half
    args.outputs.sprites << [
      { x:         600,
        y:         320,
        x2:        600,
        y2:        400,
        x3:        640,
        y3:        360,
        path:      "sprites/square/blue.png",
        source_x:  0,
        source_y:  0,
        source_x2: 0,
        source_y2: 80,
        source_x3: 40,
        source_y3: 40 },
      { x:         600,
        y:         400,
        x2:        680,
        y2:        (400 - 80 * transform_scale).round,
        x3:        640,
        y3:        360,
        path:      "sprites/square/blue.png",
        source_x:  0,
        source_y:  80,
        source_x2: 80,
        source_y2: 80,
        source_x3: 40,
        source_y3: 40 },
      { x:         640,
        y:         360,
        x2:        680,
        y2:        (400 - 80 * transform_scale).round,
        x3:        680,
        y3:        (320 + 80 * transform_scale).round,
        path:      "sprites/square/blue.png",
        source_x:  40,
        source_y:  40,
        source_x2: 80,
        source_y2: 80,
        source_x3: 80,
        source_y3: 0 },
      { x:         600,
        y:         320,
        x2:        640,
        y2:        360,
        x3:        680,
        y3:        (320 + 80 * transform_scale).round,
        path:      "sprites/square/blue.png",
        source_x:  0,
        source_y:  0,
        source_x2: 40,
        source_y2: 40,
        source_x3: 80,
        source_y3: 0 }
    ]
  end

```

### Camera Space World Space Simple - main.rb
```ruby
  # ./samples/07_advanced_rendering/16_camera_space_world_space_simple/app/main.rb
  def tick args
    # camera must have the following properties (x, y, and scale)
    args.state.camera ||= {
      x: 0,
      y: 0,
      scale: 1
    }

    args.state.camera.x += args.inputs.left_right * 10 * args.state.camera.scale
    args.state.camera.y += args.inputs.up_down * 10 * args.state.camera.scale

    # generate 500 shapes with random positions
    args.state.objects ||= 500.map do
      {
        x: -2000 + rand(4000),
        y: -2000 + rand(4000),
        w: 16,
        h: 16,
        path: 'sprites/square/blue.png'
      }
    end

    # "i" to zoom in, "o" to zoom out
    if args.inputs.keyboard.key_down.i || args.inputs.keyboard.key_down.equal_sign || args.inputs.keyboard.key_down.plus
      args.state.camera.scale += 0.1
    elsif args.inputs.keyboard.key_down.o || args.inputs.keyboard.key_down.minus
      args.state.camera.scale -= 0.1
      args.state.camera.scale = 0.1 if args.state.camera.scale < 0.1
    end

    # "zero" to reset zoom and camera
    if args.inputs.keyboard.key_down.zero
      args.state.camera.scale = 1
      args.state.camera.x = 0
      args.state.camera.y = 0
    end

    # if mouse is clicked
    if args.inputs.mouse.click
      # convert the mouse to world space and delete any objects that intersect with the mouse
      rect = Camera.to_world_space args.state.camera, args.inputs.mouse
      args.state.objects.reject! { |o| rect.intersect_rect? o }
    end

    # "r" to reset
    if args.inputs.keyboard.key_down.r
      $gtk.reset_next_tick
    end

    # define scene
    args.outputs[:scene].transient!
    args.outputs[:scene].w = Camera::WORLD_SIZE
    args.outputs[:scene].h = Camera::WORLD_SIZE

    # render diagonals and background of scene
    args.outputs[:scene].lines << { x: 0, y: 0, x2: 1500, y2: 1500, r: 0, g: 0, b: 0, a: 255 }
    args.outputs[:scene].lines << { x: 0, y: 1500, x2: 1500, y2: 0, r: 0, g: 0, b: 0, a: 255 }
    args.outputs[:scene].solids << { x: 0, y: 0, w: 1500, h: 1500, a: 128 }

    # find all objects to render
    objects_to_render = Camera.find_all_intersect_viewport args.state.camera, args.state.objects

    # for objects that were found, convert the rect to screen coordinates and place them in scene
    args.outputs[:scene].sprites << objects_to_render.map { |o| Camera.to_screen_space args.state.camera, o }

    # render scene to screen
    args.outputs.sprites << { **Camera.viewport, path: :scene }

    # render instructions
    args.outputs.sprites << { x: 0, y: 110.from_top, w: 1280, h: 110, path: :pixel, r: 0, g: 0, b: 0, a: 128 }
    label_style = { r: 255, g: 255, b: 255, anchor_y: 0.5 }
    args.outputs.labels << { x: 30, y: 30.from_top, text: "Arrow keys to move around. I and O Keys to zoom in and zoom out (0 to reset camera, R to reset everything).", **label_style }
    args.outputs.labels << { x: 30, y: 60.from_top, text: "Click square to remove from world.", **label_style }
    args.outputs.labels << { x: 30, y: 90.from_top, text: "Mouse locationin world: #{(Camera.to_world_space args.state.camera, args.inputs.mouse).to_sf}", **label_style }
  end

  # helper methods to create a camera and go to and from screen space and world space
  class Camera
    SCREEN_WIDTH = 1280
    SCREEN_HEIGHT = 720
    WORLD_SIZE = 1500
    WORLD_SIZE_HALF = WORLD_SIZE / 2
    OFFSET_X = (SCREEN_WIDTH - WORLD_SIZE) / 2
    OFFSET_Y = (SCREEN_HEIGHT - WORLD_SIZE) / 2

    class << self
      # given a rect in screen space, converts the rect to world space
      def to_world_space camera, rect
        rect_x = rect.x
        rect_y = rect.y
        rect_w = rect.w || 0
        rect_h = rect.h || 0
        x = (rect_x - WORLD_SIZE_HALF + camera.x * camera.scale - OFFSET_X) / camera.scale
        y = (rect_y - WORLD_SIZE_HALF + camera.y * camera.scale - OFFSET_Y) / camera.scale
        w = rect_w / camera.scale
        h = rect_h / camera.scale
        rect.merge x: x, y: y, w: w, h: h
      end

      # given a rect in world space, converts the rect to screen space
      def to_screen_space camera, rect
        rect_x = rect.x
        rect_y = rect.y
        rect_w = rect.w || 0
        rect_h = rect.h || 0
        x = rect_x * camera.scale - camera.x * camera.scale + WORLD_SIZE_HALF
        y = rect_y * camera.scale - camera.y * camera.scale + WORLD_SIZE_HALF
        w = rect_w * camera.scale
        h = rect_h * camera.scale
        rect.merge x: x, y: y, w: w, h: h
      end

      # viewport of the scene
      def viewport
        {
          x: OFFSET_X,
          y: OFFSET_Y,
          w: 1500,
          h: 1500
        }
      end

      # viewport in the context of the world
      def viewport_world camera
        to_world_space camera, viewport
      end

      # helper method to find objects within viewport
      def find_all_intersect_viewport camera, os
        Geometry.find_all_intersect_rect viewport_world(camera), os
      end
    end
  end

  $gtk.reset

```

### Camera Space World Space Simple Grid Map - main.rb
```ruby
  # ./samples/07_advanced_rendering/16_camera_space_world_space_simple_grid_map/app/main.rb
  def tick args
    defaults args
    calc args
    render args
  end

  def defaults args
    tile_size = 100
    tiles_per_row = 32
    number_of_rows = 32
    number_of_tiles = tiles_per_row * number_of_rows

    # generate map tiles
    args.state.tiles ||= number_of_tiles.map_with_index do |i|
      row = i.idiv(tiles_per_row)
      col = i.mod(tiles_per_row)
      {
        x: row * tile_size,
        y: col * tile_size,
        w: tile_size,
        h: tile_size,
        path: 'sprites/square/blue.png'
      }
    end

    center_map = {
      x: tiles_per_row.idiv(2) * tile_size,
      y: number_of_rows.idiv(2) * tile_size,
      w: 1,
      h: 1
    }

    args.state.center_tile ||= args.state.tiles.find { |o| o.intersect_rect? center_map }
    args.state.selected_tile ||= args.state.center_tile

    # camera must have the following properties (x, y, and scale)
    if !args.state.camera
      args.state.camera = {
        x: 0,
        y: 0,
        scale: 1,
        target_x: 0,
        target_y: 0,
        target_scale: 1
      }

      args.state.camera.target_x = args.state.selected_tile.x + args.state.selected_tile.w.half
      args.state.camera.target_y = args.state.selected_tile.y + args.state.selected_tile.h.half
      args.state.camera.x = args.state.camera.target_x
      args.state.camera.y = args.state.camera.target_y
    end
  end

  def calc args
    calc_inputs args
    calc_camera args
  end

  def calc_inputs args
    # "i" to zoom in, "o" to zoom out
    if args.inputs.keyboard.key_down.i || args.inputs.keyboard.key_down.equal_sign || args.inputs.keyboard.key_down.plus
      args.state.camera.target_scale += 0.1 * args.state.camera.scale
    elsif args.inputs.keyboard.key_down.o || args.inputs.keyboard.key_down.minus
      args.state.camera.target_scale -= 0.1 * args.state.camera.scale
      args.state.camera.target_scale = 0.1 if args.state.camera.scale < 0.1
    end

    # "zero" to reset zoom and camera
    if args.inputs.keyboard.key_down.zero
      args.state.camera.target_scale = 1
      args.state.selected_tile = args.state.center_tile
    end

    # if mouse is clicked
    if args.inputs.mouse.click
      # convert the mouse to world space and delete any tiles that intersect with the mouse
      rect = Camera.to_world_space args.state.camera, args.inputs.mouse
      selected_tile = args.state.tiles.find { |o| rect.intersect_rect? o }
      if selected_tile
        args.state.selected_tile = selected_tile
        args.state.camera.target_scale = 1
      end
    end

    # "r" to reset
    if args.inputs.keyboard.key_down.r
      $gtk.reset_next_tick
    end
  end

  def calc_camera args
    args.state.camera.target_x = args.state.selected_tile.x + args.state.selected_tile.w.half
    args.state.camera.target_y = args.state.selected_tile.y + args.state.selected_tile.h.half
    dx = args.state.camera.target_x - args.state.camera.x
    dy = args.state.camera.target_y - args.state.camera.y
    ds = args.state.camera.target_scale - args.state.camera.scale
    args.state.camera.x += dx * 0.1 * args.state.camera.scale
    args.state.camera.y += dy * 0.1 * args.state.camera.scale
    args.state.camera.scale += ds * 0.1
  end

  def render args
    args.outputs.background_color = [0, 0, 0]

    # define scene
    args.outputs[:scene].transient!
    args.outputs[:scene].w = Camera::WORLD_SIZE
    args.outputs[:scene].h = Camera::WORLD_SIZE
    args.outputs[:scene].background_color = [0, 0, 0, 0]

    # render diagonals and background of scene
    args.outputs[:scene].lines << { x: 0, y: 0, x2: 1500, y2: 1500, r: 0, g: 0, b: 0, a: 255 }
    args.outputs[:scene].lines << { x: 0, y: 1500, x2: 1500, y2: 0, r: 0, g: 0, b: 0, a: 255 }
    args.outputs[:scene].solids << { x: 0, y: 0, w: 1500, h: 1500, a: 128 }

    # find all tiles to render
    objects_to_render = Camera.find_all_intersect_viewport args.state.camera, args.state.tiles

    # convert mouse to world space to see if it intersects with any tiles (hover color)
    mouse_in_world = Camera.to_world_space args.state.camera, args.inputs.mouse

    # for tiles that were found, convert the rect to screen coordinates and place them in scene
    args.outputs[:scene].sprites << objects_to_render.map do |o|
      if o == args.state.selected_tile
        tile_to_render = o.merge path: 'sprites/square/green.png'
      elsif o.intersect_rect? mouse_in_world
        tile_to_render = o.merge path: 'sprites/square/orange.png'
      else
        tile_to_render = o.merge path: 'sprites/square/blue.png'
      end

      Camera.to_screen_space args.state.camera, tile_to_render
    end

    # render scene to screen
    args.outputs.sprites << { **Camera.viewport, path: :scene }

    # render instructions
    args.outputs.sprites << { x: 0, y: 110.from_top, w: 1280, h: 110, path: :pixel, r: 0, g: 0, b: 0, a: 200 }
    label_style = { r: 255, g: 255, b: 255, anchor_y: 0.5 }
    args.outputs.labels << { x: 30, y: 30.from_top, text: "I/O or +/- keys to zoom in and zoom out (0 to reset camera, R to reset everything).", **label_style }
    args.outputs.labels << { x: 30, y: 60.from_top, text: "Click to center on square.", **label_style }
    args.outputs.labels << { x: 30, y: 90.from_top, text: "Mouse location in world: #{(Camera.to_world_space args.state.camera, args.inputs.mouse).to_sf}", **label_style }
  end

  # helper methods to create a camera and go to and from screen space and world space
  class Camera
    SCREEN_WIDTH = 1280
    SCREEN_HEIGHT = 720
    WORLD_SIZE = 1500
    WORLD_SIZE_HALF = WORLD_SIZE / 2
    OFFSET_X = (SCREEN_WIDTH - WORLD_SIZE) / 2
    OFFSET_Y = (SCREEN_HEIGHT - WORLD_SIZE) / 2

    class << self
      # given a rect in screen space, converts the rect to world space
      def to_world_space camera, rect
        rect_x = rect.x
        rect_y = rect.y
        rect_w = rect.w || 0
        rect_h = rect.h || 0
        x = (rect_x - WORLD_SIZE_HALF + camera.x * camera.scale - OFFSET_X) / camera.scale
        y = (rect_y - WORLD_SIZE_HALF + camera.y * camera.scale - OFFSET_Y) / camera.scale
        w = rect_w / camera.scale
        h = rect_h / camera.scale
        rect.merge x: x, y: y, w: w, h: h
      end

      # given a rect in world space, converts the rect to screen space
      def to_screen_space camera, rect
        rect_x = rect.x
        rect_y = rect.y
        rect_w = rect.w || 0
        rect_h = rect.h || 0
        x = rect_x * camera.scale - camera.x * camera.scale + WORLD_SIZE_HALF
        y = rect_y * camera.scale - camera.y * camera.scale + WORLD_SIZE_HALF
        w = rect_w * camera.scale
        h = rect_h * camera.scale
        rect.merge x: x, y: y, w: w, h: h
      end

      # viewport of the scene
      def viewport
        {
          x: OFFSET_X,
          y: OFFSET_Y,
          w: WORLD_SIZE,
          h: WORLD_SIZE
        }
      end

      # viewport in the context of the world
      def viewport_world camera
        to_world_space camera, viewport
      end

      # helper method to find objects within viewport
      def find_all_intersect_viewport camera, os
        Geometry.find_all_intersect_rect viewport_world(camera), os
      end
    end
  end

  $gtk.reset

```

### Matrix And Triangles 2d - main.rb
```ruby
  # ./samples/07_advanced_rendering/16_matrix_and_triangles_2d/app/main.rb
  include MatrixFunctions

  def tick args
    args.state.square_one_sprite = { x:        0,
                                     y:        0,
                                     w:        100,
                                     h:        100,
                                     path:     "sprites/square/blue.png",
                                     source_x: 0,
                                     source_y: 0,
                                     source_w: 80,
                                     source_h: 80 }

    args.state.square_two_sprite = { x:        0,
                                     y:        0,
                                     w:        100,
                                     h:        100,
                                     path:     "sprites/square/red.png",
                                     source_x: 0,
                                     source_y: 0,
                                     source_w: 80,
                                     source_h: 80 }

    args.state.square_one        = sprite_to_triangles args.state.square_one_sprite
    args.state.square_two        = sprite_to_triangles args.state.square_two_sprite
    args.state.camera.x        ||= 0
    args.state.camera.y        ||= 0
    args.state.camera.zoom     ||= 1
    args.state.camera.rotation ||= 0

    zmod = 1
    move_multiplier = 1
    dzoom = 0.01

    if Kernel.tick_count.zmod? zmod
      args.state.camera.x += args.inputs.left_right * -1 * move_multiplier
      args.state.camera.y += args.inputs.up_down * -1 * move_multiplier
    end

    if args.inputs.keyboard.i
      args.state.camera.zoom += dzoom
    elsif args.inputs.keyboard.o
      args.state.camera.zoom -= dzoom
    end

    args.state.camera.zoom = args.state.camera.zoom.clamp(0.25, 10)

    args.outputs.sprites << triangles_mat3_mul(args.state.square_one,
                                               mat3_translate(-50, -50),
                                               mat3_rotate(Kernel.tick_count),
                                               mat3_translate(0, 0),
                                               mat3_translate(args.state.camera.x, args.state.camera.y),
                                               mat3_scale(args.state.camera.zoom),
                                               mat3_translate(640, 360))

    args.outputs.sprites << triangles_mat3_mul(args.state.square_two,
                                               mat3_translate(-50, -50),
                                               mat3_rotate(Kernel.tick_count),
                                               mat3_translate(100, 100),
                                               mat3_translate(args.state.camera.x, args.state.camera.y),
                                               mat3_scale(args.state.camera.zoom),
                                               mat3_translate(640, 360))

    mouse_coord = vec3 args.inputs.mouse.x,
                       args.inputs.mouse.y,
                       1

    mouse_coord = mul mouse_coord,
                      mat3_translate(-640, -360),
                      mat3_scale(args.state.camera.zoom),
                      mat3_translate(-args.state.camera.x, -args.state.camera.y)

    args.outputs.lines  << { x: 640, y:   0, h:  720 }
    args.outputs.lines  << { x:   0, y: 360, w: 1280 }
    args.outputs.labels << { x: 30, y: 60.from_top, text: "x: #{args.state.camera.x.to_sf} y: #{args.state.camera.y.to_sf} z: #{args.state.camera.zoom.to_sf}" }
    args.outputs.labels << { x: 30, y: 90.from_top, text: "Mouse: #{mouse_coord.x.to_sf} #{mouse_coord.y.to_sf}" }
    args.outputs.labels << { x: 30,
                             y: 30.from_top,
                             text: "W,A,S,D to move. I, O to zoom. Triangles is a Indie/Pro Feature and will be ignored in Standard." }
  end

  def sprite_to_triangles sprite
    [
      {
        x:         sprite.x,                          y:  sprite.y,
        x2:        sprite.x,                          y2: sprite.y + sprite.h,
        x3:        sprite.x + sprite.w,               y3: sprite.y + sprite.h,
        source_x:  sprite.source_x,                   source_y:  sprite.source_y,
        source_x2: sprite.source_x,                   source_y2: sprite.source_y + sprite.source_h,
        source_x3: sprite.source_x + sprite.source_w, source_y3: sprite.source_y + sprite.source_h,
        path:      sprite.path
      },
      {
        x:  sprite.x,                                 y:  sprite.y,
        x2: sprite.x + sprite.w,                      y2: sprite.y + sprite.h,
        x3: sprite.x + sprite.w,                      y3: sprite.y,
        source_x:  sprite.source_x,                   source_y:  sprite.source_y,
        source_x2: sprite.source_x + sprite.source_w, source_y2: sprite.source_y + sprite.source_h,
        source_x3: sprite.source_x + sprite.source_w, source_y3: sprite.source_y,
        path:      sprite.path
      }
    ]
  end

  def mat3_translate dx, dy
    mat3 1, 0, dx,
         0, 1, dy,
         0, 0,  1
  end

  def mat3_rotate angle_d
    angle_r = angle_d.to_radians
    mat3 Math.cos(angle_r), -Math.sin(angle_r), 0,
         Math.sin(angle_r),  Math.cos(angle_r), 0,
                         0,                  0, 1
  end

  def mat3_scale scale
    mat3 scale,     0, 0,
             0, scale, 0,
             0,     0, 1
  end

  def triangles_mat3_mul triangles, *matrices
    triangles.map { |triangle| triangle_mat3_mul triangle, *matrices }
  end

  def triangle_mat3_mul triangle, *matrices
    result = [
      (vec3 triangle.x,  triangle.y,  1),
      (vec3 triangle.x2, triangle.y2, 1),
      (vec3 triangle.x3, triangle.y3, 1)
    ].map do |coord|
      mul coord, *matrices
    end

    {
      **triangle,
      x:  result[0].x,
      y:  result[0].y,
      x2: result[1].x,
      y2: result[1].y,
      x3: result[2].x,
      y3: result[2].y,
    }
  rescue Exception => e
    pretty_print triangle
    pretty_print result
    pretty_print matrices
    puts "#{matrices}"
    raise e
  end

```

### Matrix And Triangles 3d - main.rb
```ruby
  # ./samples/07_advanced_rendering/16_matrix_and_triangles_3d/app/main.rb
  include MatrixFunctions

  def tick args
    args.outputs.labels << { x: 0,
                             y: 30.from_top,
                             text: "W,A,S,D to move. Q,E,U,O to turn, I,K for elevation. Triangles is a Indie/Pro Feature and will be ignored in Standard.",
                             alignment_enum: 1 }

    args.grid.origin_center!

    args.state.cam_x ||= 0.00
    if args.inputs.keyboard.left
      args.state.cam_x += 0.01
    elsif args.inputs.keyboard.right
      args.state.cam_x -= 0.01
    end

    args.state.cam_y ||= 0.00
    if args.inputs.keyboard.i
      args.state.cam_y += 0.01
    elsif args.inputs.keyboard.k
      args.state.cam_y -= 0.01
    end

    args.state.cam_z ||= 6.5
    if args.inputs.keyboard.s
      args.state.cam_z += 0.1
    elsif args.inputs.keyboard.w
      args.state.cam_z -= 0.1
    end

    args.state.cam_angle_y ||= 0
    if args.inputs.keyboard.q
      args.state.cam_angle_y += 0.25
    elsif args.inputs.keyboard.e
      args.state.cam_angle_y -= 0.25
    end

    args.state.cam_angle_x ||= 0
    if args.inputs.keyboard.u
      args.state.cam_angle_x += 0.1
    elsif args.inputs.keyboard.o
      args.state.cam_angle_x -= 0.1
    end

    # model A
    args.state.a = [
      [vec4(0, 0, 0, 1),   vec4(0.5, 0, 0, 1),   vec4(0, 0.5, 0, 1)],
      [vec4(0.5, 0, 0, 1), vec4(0.5, 0.5, 0, 1), vec4(0, 0.5, 0, 1)]
    ]

    # model to world
    args.state.a_world = mul_world args,
                                   args.state.a,
                                   (translate -0.25, -0.25, 0),
                                   (translate  0, 0, 0.25),
                                   (rotate_x Kernel.tick_count)

    args.state.a_camera = mul_cam args, args.state.a_world
    args.state.a_projected = mul_perspective args, args.state.a_camera
    render_projection args, args.state.a_projected

    # model B
    args.state.b = [
      [vec4(0, 0, 0, 1),   vec4(0.5, 0, 0, 1),   vec4(0, 0.5, 0, 1)],
      [vec4(0.5, 0, 0, 1), vec4(0.5, 0.5, 0, 1), vec4(0, 0.5, 0, 1)]
    ]

    # model to world
    args.state.b_world = mul_world args,
                                   args.state.b,
                                   (translate -0.25, -0.25, 0),
                                   (translate  0, 0, -0.25),
                                   (rotate_x Kernel.tick_count)

    args.state.b_camera = mul_cam args, args.state.b_world
    args.state.b_projected = mul_perspective args, args.state.b_camera
    render_projection args, args.state.b_projected

    # model C
    args.state.c = [
      [vec4(0, 0, 0, 1),   vec4(0.5, 0, 0, 1),   vec4(0, 0.5, 0, 1)],
      [vec4(0.5, 0, 0, 1), vec4(0.5, 0.5, 0, 1), vec4(0, 0.5, 0, 1)]
    ]

    # model to world
    args.state.c_world = mul_world args,
                                   args.state.c,
                                   (translate -0.25, -0.25, 0),
                                   (rotate_y 90),
                                   (translate -0.25,  0, 0),
                                   (rotate_x Kernel.tick_count)

    args.state.c_camera = mul_cam args, args.state.c_world
    args.state.c_projected = mul_perspective args, args.state.c_camera
    render_projection args, args.state.c_projected

    # model D
    args.state.d = [
      [vec4(0, 0, 0, 1),   vec4(0.5, 0, 0, 1),   vec4(0, 0.5, 0, 1)],
      [vec4(0.5, 0, 0, 1), vec4(0.5, 0.5, 0, 1), vec4(0, 0.5, 0, 1)]
    ]

    # model to world
    args.state.d_world = mul_world args,
                                   args.state.d,
                                   (translate -0.25, -0.25, 0),
                                   (rotate_y 90),
                                   (translate  0.25,  0, 0),
                                   (rotate_x Kernel.tick_count)

    args.state.d_camera = mul_cam args, args.state.d_world
    args.state.d_projected = mul_perspective args, args.state.d_camera
    render_projection args, args.state.d_projected

    # model E
    args.state.e = [
      [vec4(0, 0, 0, 1),   vec4(0.5, 0, 0, 1),   vec4(0, 0.5, 0, 1)],
      [vec4(0.5, 0, 0, 1), vec4(0.5, 0.5, 0, 1), vec4(0, 0.5, 0, 1)]
    ]

    # model to world
    args.state.e_world = mul_world args,
                                   args.state.e,
                                   (translate -0.25, -0.25, 0),
                                   (rotate_x 90),
                                   (translate  0,  0.25, 0),
                                   (rotate_x Kernel.tick_count)

    args.state.e_camera = mul_cam args, args.state.e_world
    args.state.e_projected = mul_perspective args, args.state.e_camera
    render_projection args, args.state.e_projected

    # model E
    args.state.f = [
      [vec4(0, 0, 0, 1),   vec4(0.5, 0, 0, 1),   vec4(0, 0.5, 0, 1)],
      [vec4(0.5, 0, 0, 1), vec4(0.5, 0.5, 0, 1), vec4(0, 0.5, 0, 1)]
    ]

    # model to world
    args.state.f_world = mul_world args,
                                   args.state.f,
                                   (translate -0.25, -0.25, 0),
                                   (rotate_x 90),
                                   (translate  0,  -0.25, 0),
                                   (rotate_x Kernel.tick_count)

    args.state.f_camera = mul_cam args, args.state.f_world
    args.state.f_projected = mul_perspective args, args.state.f_camera
    render_projection args, args.state.f_projected

    # render_debug args, args.state.a, args.state.a_transform, args.state.a_projected
    # args.outputs.labels << { x: -630, y:  10.from_top,  text: "x:         #{args.state.cam_x.to_sf} -> #{( args.state.cam_x * 1000 ).to_sf}" }
    # args.outputs.labels << { x: -630, y:  30.from_top,  text: "y:         #{args.state.cam_y.to_sf} -> #{( args.state.cam_y * 1000 ).to_sf}" }
    # args.outputs.labels << { x: -630, y:  50.from_top,  text: "z:         #{args.state.cam_z.fdiv(10).to_sf} -> #{( args.state.cam_z * 100 ).to_sf}" }
  end

  def mul_world args, model, *mul_def
    model.map do |vecs|
      vecs.map do |vec|
        mul vec,
            *mul_def
      end
    end
  end

  def mul_cam args, world_vecs
    world_vecs.map do |vecs|
      vecs.map do |vec|
        mul vec,
            (translate -args.state.cam_x, args.state.cam_y, -args.state.cam_z),
            (rotate_y args.state.cam_angle_y),
            (rotate_x args.state.cam_angle_x)
      end
    end
  end

  def mul_perspective args, camera_vecs
    camera_vecs.map do |vecs|
      vecs.map do |vec|
        perspective vec
      end
    end
  end

  def render_debug args, model, transform, projected
    args.outputs.labels << { x: -630, y:  10.from_top,  text: "model:     #{vecs_to_s model[0]}" }
    args.outputs.labels << { x: -630, y:  30.from_top,  text: "           #{vecs_to_s model[1]}" }
    args.outputs.labels << { x: -630, y:  50.from_top,  text: "transform: #{vecs_to_s transform[0]}" }
    args.outputs.labels << { x: -630, y:  70.from_top,  text: "           #{vecs_to_s transform[1]}" }
    args.outputs.labels << { x: -630, y:  90.from_top,  text: "projected: #{vecs_to_s projected[0]}" }
    args.outputs.labels << { x: -630, y: 110.from_top,  text: "           #{vecs_to_s projected[1]}" }
  end

  def render_projection args, projection
    p0 = projection[0]
    args.outputs.sprites << {
      x:  p0[0].x,   y: p0[0].y,
      x2: p0[1].x,  y2: p0[1].y,
      x3: p0[2].x,  y3: p0[2].y,
      source_x:   0, source_y:   0,
      source_x2: 80, source_y2:  0,
      source_x3:  0, source_y3: 80,
      a: 40,
      # r: 128, g: 128, b: 128,
      path: 'sprites/square/blue.png'
    }

    p1 = projection[1]
    args.outputs.sprites << {
      x:  p1[0].x,   y: p1[0].y,
      x2: p1[1].x,  y2: p1[1].y,
      x3: p1[2].x,  y3: p1[2].y,
      source_x:  80, source_y:   0,
      source_x2: 80, source_y2: 80,
      source_x3:  0, source_y3: 80,
      a: 40,
      # r: 128, g: 128, b: 128,
      path: 'sprites/square/blue.png'
    }
  end

  def perspective vec
    left   = -1.0
    right  =  1.0
    bottom = -1.0
    top    =  1.0
    near   =  300.0
    far    =  1000.0
    sx = 2 * near / (right - left)
    sy = 2 * near / (top - bottom)
    c2 = - (far + near) / (far - near)
    c1 = 2 * near * far / (near - far)
    tx = -near * (left + right) / (right - left)
    ty = -near * (bottom + top) / (top - bottom)

    p = mat4 sx, 0, 0, tx,
             0, sy, 0, ty,
             0, 0, c2, c1,
             0, 0, -1, 0

    r = mul vec, p
    r.x *= r.z / r.w / 100
    r.y *= r.z / r.w / 100
    r
  end

  def mat_scale scale
    mat4 scale,     0,     0,   0,
             0, scale,     0,   0,
             0,     0, scale,   0,
             0,     0,     0,   1
  end

  def rotate_y angle_d
    cos_t = Math.cos angle_d.to_radians
    sin_t = Math.sin angle_d.to_radians
    (mat4  cos_t,  0, sin_t, 0,
           0,      1, 0,     0,
           -sin_t, 0, cos_t, 0,
           0,      0, 0,     1)
  end

  def rotate_z angle_d
    cos_t = Math.cos angle_d.to_radians
    sin_t = Math.sin angle_d.to_radians
    (mat4 cos_t, -sin_t, 0, 0,
          sin_t,  cos_t, 0, 0,
          0,      0,     1, 0,
          0,      0,     0, 1)
  end

  def translate dx, dy, dz
    mat4 1, 0, 0, dx,
         0, 1, 0, dy,
         0, 0, 1, dz,
         0, 0, 0,  1
  end


  def rotate_x angle_d
    cos_t = Math.cos angle_d.to_radians
    sin_t = Math.sin angle_d.to_radians
    (mat4  1,     0,      0, 0,
           0, cos_t, -sin_t, 0,
           0, sin_t,  cos_t, 0,
           0,     0,      0, 1)
  end

  def vecs_to_s vecs
    vecs.map do |vec|
      "[#{vec.x.to_sf} #{vec.y.to_sf} #{vec.z.to_sf}]"
    end.join " "
  end

```

### Matrix Camera Space World Space - main.rb
```ruby
  # ./samples/07_advanced_rendering/16_matrix_camera_space_world_space/app/main.rb
  # sample app shows how to translate between screen and world coordinates using matrix multiplication
  class Game
    attr_gtk

    def tick
      defaults
      input
      calc
      render
    end

    def defaults
      return if Kernel.tick_count != 0

      # define the size of the world
      state.world_size = 1280

      # initialize the camera
      state.camera = {
        x: 0,
        y: 0,
        zoom: 1
      }

      # initialize entities: place entities randomly in the world
      state.entities = 200.map do
        {
          x: (rand * state.world_size - 100).to_i * (rand > 0.5 ? 1 : -1),
          y: (rand * state.world_size - 100).to_i * (rand > 0.5 ? 1 : -1),
          w: 32,
          h: 32,
          angle: 0,
          path: "sprites/square/blue.png",
          rotation_speed: rand * 5
        }
      end

      # backdrop for the world
      state.backdrop = { x: -state.world_size,
                         y: -state.world_size,
                         w: state.world_size * 2,
                         h: state.world_size * 2,
                         r: 200,
                         g: 100,
                         b: 0,
                         a: 128,
                         path: :pixel }

      # rect representing the screen
      state.screen_rect = { x: 0, y: 0, w: 1280, h: 720 }

      # update the camera matricies (initial state)
      update_matricies!
    end

    # if the camera is ever changed, recompute the matricies that are used
    # to translate between screen and world coordinates. we want to cache
    # the resolved matrix for speed
    def update_matricies!
      # camera space is defined with three matricies
      # every entity is:
      # - offset by the location of the camera
      # - scaled
      # - then centered on the screen
      state.to_camera_space_matrix = MatrixFunctions.mul(mat3_translate(state.camera.x, state.camera.y),
                                                         mat3_scale(state.camera.zoom),
                                                         mat3_translate(640, 360))

      # world space is defined based off the camera matricies but inverted:
      # every entity is:
      # - uncentered from the screen
      # - unscaled
      # - offset by the location of the camera in the opposite direction
      state.to_world_space_matrix = MatrixFunctions.mul(mat3_translate(-640, -360),
                                                        mat3_scale(1.0 / state.camera.zoom),
                                                        mat3_translate(-state.camera.x, -state.camera.y))

      # the viewport is computed by taking the screen rect and moving it into world space.
      # what entities get rendered is based off of the viewport
      state.viewport = rect_mul_matrix(state.screen_rect, state.to_world_space_matrix)
    end

    def input
      # if the camera is changed, invalidate/recompute the translation matricies
      should_update_matricies = false

      # + and - keys zoom in and out
      if inputs.keyboard.equal_sign || inputs.keyboard.plus || inputs.mouse.wheel && inputs.mouse.wheel.y > 0
        state.camera.zoom += 0.01 * state.camera.zoom
        should_update_matricies = true
      elsif inputs.keyboard.minus || inputs.mouse.wheel && inputs.mouse.wheel.y < 0
        state.camera.zoom -= 0.01 * state.camera.zoom
        should_update_matricies = true
      end

      # clamp the zoom to a minimum of 0.25
      if state.camera.zoom < 0.25
        state.camera.zoom = 0.25
        should_update_matricies = true
      end

      # left and right keys move the camera left and right
      if inputs.left_right != 0
        state.camera.x += -1 * (inputs.left_right * 10) * state.camera.zoom
        should_update_matricies = true
      end

      # up and down keys move the camera up and down
      if inputs.up_down != 0
        state.camera.y += -1 * (inputs.up_down * 10) * state.camera.zoom
        should_update_matricies = true
      end

      # reset the camera to the default position
      if inputs.keyboard.key_down.zero
        state.camera.x = 0
        state.camera.y = 0
        state.camera.zoom = 1
        should_update_matricies = true
      end

      # if the update matricies flag is set, recompute the matricies
      update_matricies! if should_update_matricies
    end

    def calc
      # rotate all the entities by their rotation speed
      # and reset their hovered state
      state.entities.each do |entity|
        entity.hovered = false
        entity.angle += entity.rotation_speed
      end

      # find all the entities that are hovered by the mouse and update their state back to hovered
      mouse_in_world = rect_to_world_coordinates inputs.mouse.rect
      hovered_entities = geometry.find_all_intersect_rect mouse_in_world, state.entities
      hovered_entities.each { |entity| entity.hovered = true }
    end

    def render
      # create a render target to represent the camera's viewport
      outputs[:scene].transient!
      outputs[:scene].w = state.world_size
      outputs[:scene].h = state.world_size

      # render the backdrop
      outputs[:scene].primitives << rect_to_screen_coordinates(state.backdrop)

      # get all entities that are within the camera's viewport
      entities_to_render = geometry.find_all_intersect_rect state.viewport, state.entities

      # render all the entities within the viewport
      outputs[:scene].primitives << entities_to_render.map do |entity|
        r = rect_to_screen_coordinates entity

        # change the color of the entity if it's hovered
        r.merge!(path: "sprites/square/red.png") if entity.hovered

        r
      end

      # render the camera's viewport
      outputs.sprites << {
        x: 0,
        y: 0,
        w: state.world_size,
        h: state.world_size,
        path: :scene
      }

      # show a label that shows the mouse's screen and world coordinates
      outputs.labels << { x: 30, y: 30.from_top, text: "#{gtk.current_framerate.to_sf}" }

      mouse_in_world = rect_to_world_coordinates inputs.mouse.rect

      outputs.labels << {
        x: 30,
        y: 55.from_top,
        text: "Screen Coordinates: #{inputs.mouse.x}, #{inputs.mouse.y}",
      }

      outputs.labels << {
        x: 30,
        y: 80.from_top,
        text: "World Coordinates: #{mouse_in_world.x.to_sf}, #{mouse_in_world.y.to_sf}",
      }
    end

    def rect_to_screen_coordinates rect
      rect_mul_matrix rect, state.to_camera_space_matrix
    end

    def rect_to_world_coordinates rect
      rect_mul_matrix rect, state.to_world_space_matrix
    end

    def rect_mul_matrix rect, matrix
      # the bottom left and top right corners of the rect
      # are multiplied by the matrix to get the new coordinates
      bottom_left = MatrixFunctions.mul (MatrixFunctions.vec3 rect.x, rect.y, 1), matrix
      top_right   = MatrixFunctions.mul (MatrixFunctions.vec3 rect.x + rect.w, rect.y + rect.h, 1), matrix

      # with the points of the rect recomputed, reconstruct the rect
      rect.merge x: bottom_left.x,
                 y: bottom_left.y,
                 w: top_right.x - bottom_left.x,
                 h: top_right.y - bottom_left.y
    end

    # this is the definition of how to move a point in 2d space using a matrix
    def mat3_translate x, y
      MatrixFunctions.mat3 1, 0, x,
                           0, 1, y,
                           0, 0, 1
    end

    # this is the definition of how to scale a point in 2d space using a matrix
    def mat3_scale scale
      MatrixFunctions.mat3 scale, 0, 0,
                           0, scale, 0,
                           0,     0, 1
    end
  end

  $game = Game.new

  def tick args
    $game.args = args
    $game.tick
  end

  $gtk.reset

```

### Matrix Cubeworld - main.rb
```ruby
  # ./samples/07_advanced_rendering/16_matrix_cubeworld/app/main.rb
  require 'app/modeling-api.rb'

  include MatrixFunctions

  def tick args
    args.outputs.labels << { x: 0,
                             y: 30.from_top,
                             text: "W,A,S,D to move. Mouse to look. Triangles is a Indie/Pro Feature and will be ignored in Standard.",
                             alignment_enum: 1 }

    args.grid.origin_center!

    args.state.cam_y ||= 0.00
    if args.inputs.keyboard.i
      args.state.cam_y += 0.01
    elsif args.inputs.keyboard.k
      args.state.cam_y -= 0.01
    end

    args.state.cam_angle_y ||= 0
    if args.inputs.keyboard.q
      args.state.cam_angle_y += 0.25
    elsif args.inputs.keyboard.e
      args.state.cam_angle_y -= 0.25
    end

    args.state.cam_angle_x ||= 0
    if args.inputs.keyboard.u
      args.state.cam_angle_x += 0.1
    elsif args.inputs.keyboard.o
      args.state.cam_angle_x -= 0.1
    end

    if args.inputs.mouse.has_focus
      y_change_rate = (args.inputs.mouse.x / 640) ** 2
      if args.inputs.mouse.x < 0
        args.state.cam_angle_y -= 0.8 * y_change_rate
      else
        args.state.cam_angle_y += 0.8 * y_change_rate
      end

      x_change_rate = (args.inputs.mouse.y / 360) ** 2
      if args.inputs.mouse.y < 0
        args.state.cam_angle_x += 0.8 * x_change_rate
      else
        args.state.cam_angle_x -= 0.8 * x_change_rate
      end
    end

    args.state.cam_z ||= 6.4
    if args.inputs.keyboard.up
      point_1 = { x: 0, y: 0.02 }
      point_r = args.geometry.rotate_point point_1, args.state.cam_angle_y
      args.state.cam_x -= point_r.x
      args.state.cam_z -= point_r.y
    elsif args.inputs.keyboard.down
      point_1 = { x: 0, y: -0.02 }
      point_r = args.geometry.rotate_point point_1, args.state.cam_angle_y
      args.state.cam_x -= point_r.x
      args.state.cam_z -= point_r.y
    end

    args.state.cam_x ||= 0.00
    if args.inputs.keyboard.right
      point_1 = { x: -0.02, y: 0 }
      point_r = args.geometry.rotate_point point_1, args.state.cam_angle_y
      args.state.cam_x -= point_r.x
      args.state.cam_z -= point_r.y
    elsif args.inputs.keyboard.left
      point_1 = { x:  0.02, y: 0 }
      point_r = args.geometry.rotate_point point_1, args.state.cam_angle_y
      args.state.cam_x -= point_r.x
      args.state.cam_z -= point_r.y
    end


    if args.inputs.keyboard.key_down.r || args.inputs.keyboard.key_down.zero
      args.state.cam_x = 0.00
      args.state.cam_y = 0.00
      args.state.cam_z = 1.00
      args.state.cam_angle_y = 0
      args.state.cam_angle_x = 0
    end

    if !args.state.models
      args.state.models = []
      25.times do
        args.state.models.concat new_random_cube
      end
    end

    args.state.models.each do |m|
      render_triangles args, m
    end

    args.outputs.lines << { x:   0, y: -50, h: 100, a: 80 }
    args.outputs.lines << { x: -50, y:   0, w: 100, a: 80 }
  end

  def mul_triangles model, *mul_def
    combined = mul mul_def
    model.map do |vecs|
      vecs.map do |vec|
        mul vec, *combined
      end
    end
  end

  def mul_cam args, world_vecs
    mul_triangles world_vecs,
                  (translate -args.state.cam_x, -args.state.cam_y, -args.state.cam_z),
                  (rotate_y args.state.cam_angle_y),
                  (rotate_x args.state.cam_angle_x)
  end

  def mul_perspective camera_vecs
    camera_vecs.map do |vecs|
      r = vecs.map do |vec|
        perspective vec
      end

      r if r[0] && r[1] && r[2]
    end.reject_nil
  end

  def render_debug args, model, transform, projected
    args.outputs.labels << { x: -630, y:  10.from_top,  text: "model:     #{vecs_to_s model[0]}" }
    args.outputs.labels << { x: -630, y:  30.from_top,  text: "           #{vecs_to_s model[1]}" }
    args.outputs.labels << { x: -630, y:  50.from_top,  text: "transform: #{vecs_to_s transform[0]}" }
    args.outputs.labels << { x: -630, y:  70.from_top,  text: "           #{vecs_to_s transform[1]}" }
    args.outputs.labels << { x: -630, y:  90.from_top,  text: "projected: #{vecs_to_s projected[0]}" }
    args.outputs.labels << { x: -630, y: 110.from_top,  text: "           #{vecs_to_s projected[1]}" }
  end

  def render_triangles args, triangles
    camera_space = mul_cam args, triangles
    projection = mul_perspective camera_space

    args.outputs.sprites << projection.map_with_index do |i, index|
      if i
        {
          x:  i[0].x,   y: i[0].y,
          x2: i[1].x,  y2: i[1].y,
          x3: i[2].x,  y3: i[2].y,
          source_x:   0, source_y:   0,
          source_x2: 80, source_y2:  0,
          source_x3:  0, source_y3: 80,
          r: 128, g: 128, b: 128,
          a: 80 + 128 * 1 / (index + 1),
          path: :pixel
        }
      end
    end
  end

  def perspective vec
    left   =  100.0
    right  = -100.0
    bottom =  100.0
    top    = -100.0
    near   =  3000.0
    far    =  8000.0
    sx = 2 * near / (right - left)
    sy = 2 * near / (top - bottom)
    c2 = - (far + near) / (far - near)
    c1 = 2 * near * far / (near - far)
    tx = -near * (left + right) / (right - left)
    ty = -near * (bottom + top) / (top - bottom)

    p = mat4 sx, 0, 0, tx,
             0, sy, 0, ty,
             0, 0, c2, c1,
             0, 0, -1, 0

    r = mul vec, p
    return nil if r.w < 0
    r.x *= r.z / r.w / 100
    r.y *= r.z / r.w / 100
    r
  end

  def mat_scale scale
    mat4 scale,     0,     0,   0,
             0, scale,     0,   0,
             0,     0, scale,   0,
             0,     0,     0,   1
  end

  def rotate_y angle_d
    cos_t = Math.cos angle_d.to_radians
    sin_t = Math.sin angle_d.to_radians
    (mat4  cos_t,  0, sin_t, 0,
           0,      1, 0,     0,
           -sin_t, 0, cos_t, 0,
           0,      0, 0,     1)
  end

  def rotate_z angle_d
    cos_t = Math.cos angle_d.to_radians
    sin_t = Math.sin angle_d.to_radians
    (mat4 cos_t, -sin_t, 0, 0,
          sin_t,  cos_t, 0, 0,
          0,      0,     1, 0,
          0,      0,     0, 1)
  end

  def translate dx, dy, dz
    mat4 1, 0, 0, dx,
         0, 1, 0, dy,
         0, 0, 1, dz,
         0, 0, 0,  1
  end


  def rotate_x angle_d
    cos_t = Math.cos angle_d.to_radians
    sin_t = Math.sin angle_d.to_radians
    (mat4  1,     0,      0, 0,
           0, cos_t, -sin_t, 0,
           0, sin_t,  cos_t, 0,
           0,     0,      0, 1)
  end

  def vecs_to_s vecs
    vecs.map do |vec|
      "[#{vec.x.to_sf} #{vec.y.to_sf} #{vec.z.to_sf}]"
    end.join " "
  end

  def new_random_cube
    cube_w = rand * 0.2 + 0.1
    cube_h = rand * 0.2 + 0.1
    randx = rand * 2.0 * [1, -1].sample
    randy = rand * 2.0
    randz = rand * 5   * [1, -1].sample

    cube = [
      square do
        scale x: cube_w, y: cube_h
        translate x: -cube_w / 2, y: -cube_h / 2
        rotate_x 90
        translate y: -cube_h / 2
        translate x: randx, y: randy, z: randz
      end,
      square do
        scale x: cube_w, y: cube_h
        translate x: -cube_w / 2, y: -cube_h / 2
        rotate_x 90
        translate y:  cube_h / 2
        translate x: randx, y: randy, z: randz
      end,
      square do
        scale x: cube_h, y: cube_h
        translate x: -cube_h / 2, y: -cube_h / 2
        rotate_y 90
        translate x: -cube_w / 2
        translate x: randx, y: randy, z: randz
      end,
      square do
        scale x: cube_h, y: cube_h
        translate x: -cube_h / 2, y: -cube_h / 2
        rotate_y 90
        translate x:  cube_w / 2
        translate x: randx, y: randy, z: randz
      end,
      square do
        scale x: cube_w, y: cube_h
        translate x: -cube_w / 2, y: -cube_h / 2
        translate z: -cube_h / 2
        translate x: randx, y: randy, z: randz
      end,
      square do
        scale x: cube_w, y: cube_h
        translate x: -cube_w / 2, y: -cube_h / 2
        translate z:  cube_h / 2
        translate x: randx, y: randy, z: randz
      end
    ]

    cube
  end

  $gtk.reset

```

### Matrix Cubeworld - modeling-api.rb
```ruby
  # ./samples/07_advanced_rendering/16_matrix_cubeworld/app/modeling-api.rb
  class ModelingApi
    attr :matricies

    def initialize
      @matricies = []
    end

    def scale x: 1, y: 1, z: 1
      @matricies << scale_matrix(x: x, y: y, z: z)
      if block_given?
        yield
        @matricies << scale_matrix(x: -x, y: -y, z: -z)
      end
    end

    def translate x: 0, y: 0, z: 0
      @matricies << translate_matrix(x: x, y: y, z: z)
      if block_given?
        yield
        @matricies << translate_matrix(x: -x, y: -y, z: -z)
      end
    end

    def rotate_x x
      @matricies << rotate_x_matrix(x)
      if block_given?
        yield
        @matricies << rotate_x_matrix(-x)
      end
    end

    def rotate_y y
      @matricies << rotate_y_matrix(y)
      if block_given?
        yield
        @matricies << rotate_y_matrix(-y)
      end
    end

    def rotate_z z
      @matricies << rotate_z_matrix(z)
      if block_given?
        yield
        @matricies << rotate_z_matrix(-z)
      end
    end

    def scale_matrix x:, y:, z:;
      mat4 x, 0, 0, 0,
           0, y, 0, 0,
           0, 0, z, 0,
           0, 0, 0, 1
    end

    def translate_matrix x:, y:, z:;
      mat4 1, 0, 0, x,
           0, 1, 0, y,
           0, 0, 1, z,
           0, 0, 0, 1
    end

    def rotate_y_matrix angle_d
      cos_t = Math.cos angle_d.to_radians
      sin_t = Math.sin angle_d.to_radians
      (mat4  cos_t,  0, sin_t, 0,
             0,      1, 0,     0,
             -sin_t, 0, cos_t, 0,
             0,      0, 0,     1)
    end

    def rotate_z_matrix angle_d
      cos_t = Math.cos angle_d.to_radians
      sin_t = Math.sin angle_d.to_radians
      (mat4 cos_t, -sin_t, 0, 0,
            sin_t,  cos_t, 0, 0,
            0,      0,     1, 0,
            0,      0,     0, 1)
    end

    def rotate_x_matrix angle_d
      cos_t = Math.cos angle_d.to_radians
      sin_t = Math.sin angle_d.to_radians
      (mat4  1,     0,      0, 0,
             0, cos_t, -sin_t, 0,
             0, sin_t,  cos_t, 0,
             0,     0,      0, 1)
    end

    def __mul_triangles__ model, *mul_def
      model.map do |vecs|
        vecs.map do |vec|
          mul vec,
              *mul_def
        end
      end
    end
  end

  def square &block
    square_verticies = [
      [vec4(0, 0, 0, 1),   vec4(1.0, 0, 0, 1),   vec4(0, 1.0, 0, 1)],
      [vec4(1.0, 0, 0, 1), vec4(1.0, 1.0, 0, 1), vec4(0, 1.0, 0, 1)]
    ]

    m = ModelingApi.new
    m.instance_eval &block if block
    m.__mul_triangles__ square_verticies, *m.matricies
  end

```

### Override Core Rendering - main.rb
```ruby
  # ./samples/07_advanced_rendering/17_override_core_rendering/app/main.rb
  class GTK::Runtime
    # You can completely override how DR renders by defining this method
    # It is strongly recommend that you do not do this unless you know what you're doing.
    def primitives pass
      # fn.each_send pass.solids,            self, :draw_solid
      # fn.each_send pass.static_solids,     self, :draw_solid
      # fn.each_send pass.sprites,           self, :draw_sprite
      # fn.each_send pass.static_sprites,    self, :draw_sprite
      # fn.each_send pass.primitives,        self, :draw_primitive
      # fn.each_send pass.static_primitives, self, :draw_primitive
      fn.each_send pass.labels,            self, :draw_label
      fn.each_send pass.static_labels,     self, :draw_label
      # fn.each_send pass.lines,             self, :draw_line
      # fn.each_send pass.static_lines,      self, :draw_line
      # fn.each_send pass.borders,           self, :draw_border
      # fn.each_send pass.static_borders,    self, :draw_border

      # if !self.production
      #   fn.each_send pass.debug,           self, :draw_primitive
      #   fn.each_send pass.static_debug,    self, :draw_primitive
      # end

      # fn.each_send pass.reserved,          self, :draw_primitive
      # fn.each_send pass.static_reserved,   self, :draw_primitive
    end
  end

  def tick args
    args.outputs.labels << { x: 30, y: 30, text: "primitives function defined, only labels rendered" }
    args.outputs.sprites << { x: 100, y: 100, w: 100, h: 100, path: "dragonruby.png" }
  end

```

### Layouts - main.rb
```ruby
  # ./samples/07_advanced_rendering/18_layouts/app/main.rb
  def tick args
    args.outputs.solids << args.layout.rect(row: 0,
                                            col: 0,
                                            w: 24,
                                            h: 12,
                                            include_row_gutter: true,
                                            include_col_gutter: true).merge(b: 255, a: 80)
    render_row_examples args
    render_column_examples args
    render_max_width_max_height_examples args
    render_points_with_anchored_label_examples args
    render_centered_rect_examples args
    render_rect_group_examples args
  end

  def render_row_examples args
    # rows (light blue)
    args.outputs.labels << args.layout.rect(row: 1, col: 6 + 3).merge(text: "row examples", anchor_x: 0.5, anchor_y: 0.5)
    4.map_with_index do |row|
      args.outputs.solids << args.layout.rect(row: row, col: 6, w: 1, h: 1).merge(**light_blue)
    end

    2.map_with_index do |row|
      args.outputs.solids << args.layout.rect(row: row * 2, col: 6 + 1, w: 1, h: 2).merge(**light_blue)
    end

    4.map_with_index do |row|
      args.outputs.solids << args.layout.rect(row: row, col: 6 + 2, w: 2, h: 1).merge(**light_blue)
    end

    2.map_with_index do |row|
      args.outputs.solids << args.layout.rect(row: row * 2, col: 6 + 4, w: 2, h: 2).merge(**light_blue)
    end
  end

  def render_column_examples args
    # columns (yellow)
    yellow = { r: 255, g: 255, b: 128 }
    args.outputs.labels << args.layout.rect(row: 1, col: 12 + 3).merge(text: "column examples", anchor_x: 0.5, anchor_y: 0.5)
    6.times do |col|
      args.outputs.solids << args.layout.rect(row: 0, col: 12 + col, w: 1, h: 1).merge(**yellow)
    end

    3.times do |col|
      args.outputs.solids << args.layout.rect(row: 1, col: 12 + col * 2, w: 2, h: 1).merge(**yellow)
    end

    6.times do |col|
      args.outputs.solids << args.layout.rect(row: 2, col: 12 + col, w: 1, h: 2).merge(**yellow)
    end
  end

  def render_max_width_max_height_examples args
    # max width/height baseline (transparent green)
    args.outputs.labels << args.layout.rect(row: 4, col: 12).merge(text: "max width/height examples", anchor_x: 0.5, anchor_y: 0.5)
    args.outputs.solids << args.layout.rect(row: 4, col: 0, w: 24, h: 2).merge(a: 64, **green)

    # max height
    args.outputs.solids << args.layout.rect(row: 4, col: 0, w: 24, h: 2, max_height: 1).merge(a: 64, **green)

    # max width
    args.outputs.solids << args.layout.rect(row: 4, col: 0, w: 24, h: 2, max_width: 12).merge(a: 64, **green)
  end

  def render_points_with_anchored_label_examples args
    # labels relative to rects
    label_color = { r: 0, g: 0, b: 0 }

    # labels realtive to point, achored at 0.0, 0.0
    args.outputs.borders << args.layout.rect(row: 6, col: 3, w: 6, h: 5)
    args.outputs.labels << args.layout.rect(row: 6, col: 3, w: 6, h: 1).center.merge(text: "layout.point anchored to 0.0, 0.0", anchor_x: 0.5, anchor_y: 0.5, size_px: 15)
    grey = { r: 128, g: 128, b: 128 }
    args.outputs.solids << args.layout.rect(row: 7, col: 4.5).merge(**grey)
    args.outputs.labels << args.layout.point(row: 7, col: 4.5, row_anchor: 1.0, col_anchor: 0.0).merge(text: "[x]", anchor_x: 0.5, anchor_y: 0.5, **label_color)

    args.outputs.solids << args.layout.rect(row: 7, col: 5.5).merge(**grey)
    args.outputs.labels << args.layout.point(row: 7, col: 5.5, row_anchor: 1.0, col_anchor: 0.5).merge(text: "[x]", anchor_x: 0.5, anchor_y: 0.5, **label_color)

    args.outputs.solids << args.layout.rect(row: 7, col: 6.5).merge(**grey)
    args.outputs.labels << args.layout.point(row: 7, col: 6.5, row_anchor: 1.0, col_anchor: 1.0).merge(text: "[x]", anchor_x: 0.5, anchor_y: 0.5, **label_color)

    args.outputs.solids << args.layout.rect(row: 8, col: 4.5).merge(**grey)
    args.outputs.labels << args.layout.point(row: 8, col: 4.5, row_anchor: 0.5, col_anchor: 0.0).merge(text: "[x]", anchor_x: 0.5, anchor_y: 0.5, **label_color)

    args.outputs.solids << args.layout.rect(row: 8, col: 5.5).merge(**grey)
    args.outputs.labels << args.layout.point(row: 8, col: 5.5, row_anchor: 0.5, col_anchor: 0.5).merge(text: "[x]", anchor_x: 0.5, anchor_y: 0.5, **label_color)

    args.outputs.solids << args.layout.rect(row: 8, col: 6.5).merge(**grey)
    args.outputs.labels << args.layout.point(row: 8, col: 6.5, row_anchor: 0.5, col_anchor: 1.0).merge(text: "[x]", anchor_x: 0.5, anchor_y: 0.5, **label_color)

    args.outputs.solids << args.layout.rect(row: 9, col: 4.5).merge(**grey)
    args.outputs.labels << args.layout.point(row: 9, col: 4.5, row_anchor: 0.0, col_anchor: 0.0).merge(text: "[x]", anchor_x: 0.5, anchor_y: 0.5, **label_color)

    args.outputs.solids << args.layout.rect(row: 9, col: 5.5).merge(**grey)
    args.outputs.labels << args.layout.point(row: 9, col: 5.5, row_anchor: 0.0, col_anchor: 0.5).merge(text: "[x]", anchor_x: 0.5, anchor_y: 0.5, **label_color)

    args.outputs.solids << args.layout.rect(row: 9, col: 6.5).merge(**grey)
    args.outputs.labels << args.layout.point(row: 9, col: 6.5, row_anchor: 0.0, col_anchor: 1.0).merge(text: "[x]", anchor_x: 0.5, anchor_y: 0.5, **label_color)
  end

  def render_centered_rect_examples args
    # centering rects
    args.outputs.borders << args.layout.rect(row: 6, col: 9, w: 6, h: 5)
    args.outputs.labels << args.layout.rect(row: 6, col: 9, w: 6, h: 1).center.merge(text: "layout.rect centered inside another rect", anchor_x: 0.5, anchor_y: 0.5, size_px: 15)
    outer_rect = args.layout.rect(row: 7, col: 10.5, w: 3, h: 3)

    # render outer rect
    args.outputs.solids << outer_rect.merge(**light_blue)

    # # center a yellow rect with w and h of two
    args.outputs.solids << args.layout.rect_center(
      args.layout.rect(w: 1, h: 5), # inner rect
      outer_rect, # outer rect
    ).merge(**yellow)

    # # center a black rect with w three h of one
    args.outputs.solids << args.layout.rect_center(
      args.layout.rect(w: 5, h: 1), # inner rect
      outer_rect, # outer rect
    )
  end

  def render_rect_group_examples args
    args.outputs.labels << args.layout.rect(row: 6, col: 15, w: 6, h: 1).center.merge(text: "layout.rect_group usage", anchor_x: 0.5, anchor_y: 0.5, size_px: 15)
    args.outputs.borders << args.layout.rect(row: 6, col: 15, w: 6, h: 5)

    horizontal_markers = [
      { r: 0, g: 0, b: 0 },
      { r: 0, g: 0, b: 0 },
      { r: 0, g: 0, b: 0 },
      { r: 0, g: 0, b: 0 },
      { r: 0, g: 0, b: 0 },
      { r: 0, g: 0, b: 0 },
    ]

    args.outputs.solids << args.layout.rect_group(row: 7,
                                                  col: 15,
                                                  dcol: 1,
                                                  w: 1,
                                                  h: 1,
                                                  group: horizontal_markers)

    vertical_markers = [
      { r: 0, g: 0, b: 0 },
      { r: 0, g: 0, b: 0 },
      { r: 0, g: 0, b: 0 },
      { r: 0, g: 0, b: 0 }
    ]

    args.outputs.solids << args.layout.rect_group(row: 7,
                                                  col: 15,
                                                  drow: 1,
                                                  w: 1,
                                                  h: 1,
                                                  group: vertical_markers)

    colors = [
      { r:   0, g:   0, b:   0 },
      { r:  50, g:  50, b:  50 },
      { r: 100, g: 100, b: 100 },
      { r: 150, g: 150, b: 150 },
      { r: 200, g: 200, b: 200 },
      { r: 250, g: 250, b: 250 },
    ]

    args.outputs.solids << args.layout.rect_group(row: 8,
                                                  col: 15,
                                                  dcol: 1,
                                                  w: 1,
                                                  h: 1,
                                                  group: colors)
  end

  def light_blue
    { r: 128, g: 255, b: 255 }
  end

  def yellow
    { r: 255, g: 255, b: 128 }
  end

  def green
    { r: 0, g: 128, b: 80 }
  end

  def white
    { r: 255, g: 255, b: 255 }
  end

  def label_color
    { r: 0, g: 0, b: 0 }
  end

  $gtk.reset

```
