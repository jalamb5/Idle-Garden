### Add Buttons To Console - main.rb
```ruby
  # ./samples/99_genre_dev_tools/add_buttons_to_console/app/main.rb
  # You can customize the buttons that show up in the Console.
  class GTK::Console::Menu
    # STEP 1: Override the custom_buttons function.
    def custom_buttons
      [
        (button id: :yay,
                # row for button
                row: 3,
                # column for button
                col: 10,
                # text
                text: "I AM CUSTOM",
                # when clicked call the custom_button_clicked function
                method: :custom_button_clicked),

        (button id: :yay,
                # row for button
                row: 3,
                # column for button
                col: 9,
                # text
                text: "CUSTOM ALSO",
                # when clicked call the custom_button_also_clicked function
                method: :custom_button_also_clicked)
      ]
    end

    # STEP 2: Define the function that should be called.
    def custom_button_clicked
      log "* INFO: I AM CUSTOM was clicked!"
    end

    def custom_button_also_clicked
      log "* INFO: Custom Button Clicked at #{Kernel.global_tick_count}!"

      all_buttons_as_string = $gtk.console.menu.buttons.map do |b|
        <<-S.strip
  ** id: #{b[:id]}
  :PROPERTIES:
  :id:     :#{b[:id]}
  :method: :#{b[:method]}
  :text:   #{b[:text]}
  :END:
  S
      end.join("\n")

      log <<-S
  * INFO: Here are all the buttons:
  #{all_buttons_as_string}
  S
    end
  end

  def tick args
    args.outputs.labels << [args.grid.center.x, args.grid.center.y,
                            "Open the DragonRuby Console to see the custom menu items.",
                            0, 1]
  end

```

### Animation Creator Starting Point - main.rb
```ruby
  # ./samples/99_genre_dev_tools/animation_creator_starting_point/app/main.rb
  class OneBitLowrezPaint
    attr_gtk

    def tick
      outputs.background_color = [0, 0, 0]
      defaults
      render_instructions
      render_canvas
      render_buttons_frame_selection
      render_animation_frame_thumbnails
      render_animation
      input_mouse_click
      input_keyboard
      calc_auto_export
      calc_buttons_frame_selection
      calc_animation_frames
      process_queue_create_sprite
      process_queue_reset_sprite
      process_queue_update_rt_animation_frame
    end

    def defaults
      state.animation_frames_per_second = 12
      queues.create_sprite ||= []
      queues.reset_sprite ||= []
      queues.update_rt_animation_frame ||= []

      if !state.animation_frames
        state.animation_frames ||= []
        add_animation_frame_to_end
      end

      state.last_mouse_down ||= 0
      state.last_mouse_up   ||= 0

      state.buttons_frame_selection.left = 10
      state.buttons_frame_selection.top  = grid.top - 10
      state.buttons_frame_selection.size = 20
      state.buttons_frame_selection.items ||= []

      defaults_canvas_sprite

      state.edit_mode ||= :drawing
    end

    def defaults_canvas_sprite
      rt_canvas.size   = 16
      rt_canvas.zoom   = 30
      rt_canvas.width  = rt_canvas.size * rt_canvas.zoom
      rt_canvas.height = rt_canvas.size * rt_canvas.zoom
      rt_canvas.sprite = { x: 0,
                           y: 0,
                           w: rt_canvas.width,
                           h: rt_canvas.height,
                           path: :rt_canvas }.center_inside_rect(x: 0, y: 0, w: 640, h: 720)

      return unless Kernel.tick_count == 1

      outputs[:rt_canvas].transient!
      outputs[:rt_canvas].width      = rt_canvas.width
      outputs[:rt_canvas].height     = rt_canvas.height
      outputs[:rt_canvas].sprites   << (rt_canvas.size + 1).map_with_index do |x|
        (rt_canvas.size + 1).map_with_index do |y|
          path = 'sprites/square-white.png'
          path = 'sprites/square-blue.png' if x == 7 || x == 8
          { x: x * rt_canvas.zoom,
            y: y * rt_canvas.zoom,
            w: rt_canvas.zoom,
            h: rt_canvas.zoom,
            path: path,
            a: 50 }
        end
      end
    end

    def render_instructions
      instructions = [
        "* Hotkeys:",
        "- d: hold to erase, release to draw.",
        "- a: add frame.",
        "- c: copy frame.",
        "- v: paste frame.",
        "- x: delete frame.",
        "- b: go to previous frame.",
        "- f: go to next frame.",
        "- w: save to ./canvas directory.",
        "- l: load from ./canvas."
      ]

      instructions.each.with_index do |l, i|
        outputs.labels << { x: 840, y: 500 - (i * 20), text: "#{l}",
                            r: 180, g: 180, b: 180, size_enum: 0 }
      end
    end

    def render_canvas
      return if Kernel.tick_count.zero?
      outputs.sprites << rt_canvas.sprite
    end

    def render_buttons_frame_selection
      args.outputs.primitives << state.buttons_frame_selection.items.map_with_index do |b, i|
        label = { x: b.x + state.buttons_frame_selection.size.half,
                  y: b.y,
                  text: "#{i + 1}", r: 180, g: 180, b: 180,
                  size_enum: -4, alignment_enum: 1 }.label!

        selection_border = b.merge(r: 40, g: 40, b: 40).border!

        if i == state.animation_frames_selected_index
          selection_border = b.merge(r: 40, g: 230, b: 200).border!
        end

        [selection_border, label]
      end
    end

    def render_animation_frame_thumbnails
      return if Kernel.tick_count.zero?

      outputs[:current_animation_frame].transient!
      outputs[:current_animation_frame].width   = rt_canvas.size
      outputs[:current_animation_frame].height  = rt_canvas.size
      outputs[:current_animation_frame].solids <<  selected_animation_frame.pixels.map_with_index do |f, i|
        { x: f.x,
          y: f.y,
          w: 1,
          h: 1, r: 255, g: 255, b: 255 }
      end

      outputs.sprites << rt_canvas.sprite.merge(path: :current_animation_frame)

      state.animation_frames.map_with_index do |animation_frame, animation_frame_index|
        outputs.sprites << state.buttons_frame_selection.items[animation_frame_index].inner_rect
                                .merge(path: animation_frame.rt_name)
      end
    end

    def render_animation
      sprite_index = 0.frame_index count: state.animation_frames.length,
                                   hold_for: 60 / state.animation_frames_per_second,
                                   repeat: true

      args.outputs.sprites << { x: 700 - 8,
                                y: 120,
                                w: 16,
                                h: 16,
                                path: (sprite_path sprite_index) }

      args.outputs.sprites << { x: 700 - 16,
                                y: 230,
                                w: 32,
                                h: 32,
                                path: (sprite_path sprite_index) }

      args.outputs.sprites << { x: 700 - 32,
                                y: 360,
                                w: 64,
                                h: 64,
                                path: (sprite_path sprite_index) }

      args.outputs.sprites << { x: 700 - 64,
                                y: 520,
                                w: 128,
                                h: 128,
                                path: (sprite_path sprite_index) }
    end

    def input_mouse_click
      if inputs.mouse.up
        state.last_mouse_up = Kernel.tick_count
      elsif inputs.mouse.moved && user_is_editing?
        edit_current_animation_frame inputs.mouse.point
      end

      return unless inputs.mouse.click

      clicked_frame_button = state.buttons_frame_selection.items.find do |b|
        inputs.mouse.point.inside_rect? b
      end

      if (clicked_frame_button)
        state.animation_frames_selected_index = clicked_frame_button.index
      end

      if (inputs.mouse.point.inside_rect? rt_canvas.sprite)
        state.last_mouse_down = Kernel.tick_count
        edit_current_animation_frame inputs.mouse.point
      end
    end

    def input_keyboard
      # w to save
      if inputs.keyboard.key_down.w
        t = Time.now
        state.save_description = "Time: #{t} (#{t.to_i})"
        gtk.serialize_state 'canvas/state.txt', state
        gtk.serialize_state "tmp/canvas_backups/#{t.to_i}/state.txt", state
        animation_frames.each_with_index do |animation_frame, i|
          queues.update_rt_animation_frame << { index: i,
                                                at: Kernel.tick_count + i,
                                                queue_sprite_creation: true }
          queues.create_sprite << { index: i,
                                    at: Kernel.tick_count + animation_frames.length + i,
                                    path_override: "tmp/canvas_backups/#{t.to_i}/sprite-#{i}.png" }
        end
        gtk.notify! "Canvas saved."
      end

      # l to load
      if inputs.keyboard.key_down.l
        args.state = gtk.deserialize_state 'canvas/state.txt'
        animation_frames.each_with_index do |a, i|
          queues.update_rt_animation_frame << { index: i,
                                                at: Kernel.tick_count + i,
                                                queue_sprite_creation: true }
        end
        gtk.notify! "Canvas loaded."
      end

      # d to go into delete mode, release to paint
      if inputs.keyboard.key_held.d
        state.edit_mode = :erasing
        gtk.notify! "Erasing." if inputs.keyboard.key_held.d == (Kernel.tick_count - 1)
      elsif inputs.keyboard.key_up.d
        state.edit_mode = :drawing
        gtk.notify! "Drawing."
      end

      # a to add a frame to the end
      if inputs.keyboard.key_down.a
        queues.create_sprite << { index: state.animation_frames_selected_index,
                                  at: Kernel.tick_count }
        queues.create_sprite << { index: state.animation_frames_selected_index + 1,
                                  at: Kernel.tick_count }
        add_animation_frame_to_end
        gtk.notify! "Frame added to end."
      end

      # c or t to copy
      if (inputs.keyboard.key_down.c || inputs.keyboard.key_down.t)
        state.clipboard = [selected_animation_frame.pixels].flatten
        gtk.notify! "Current frame copied."
      end

      # v or q to paste
      if (inputs.keyboard.key_down.v || inputs.keyboard.key_down.q) && state.clipboard
        selected_animation_frame.pixels = [state.clipboard].flatten
        queues.update_rt_animation_frame << { index: state.animation_frames_selected_index,
                                              at: Kernel.tick_count,
                                              queue_sprite_creation: true }
        gtk.notify! "Pasted."
      end

      # f to go forward/next frame
      if (inputs.keyboard.key_down.f)
        if (state.animation_frames_selected_index == (state.animation_frames.length - 1))
          state.animation_frames_selected_index = 0
        else
          state.animation_frames_selected_index += 1
        end
        gtk.notify! "Next frame."
      end

      # b to go back/previous frame
      if (inputs.keyboard.key_down.b)
        if (state.animation_frames_selected_index == 0)
          state.animation_frames_selected_index = state.animation_frames.length - 1
        else
          state.animation_frames_selected_index -= 1
        end
        gtk.notify! "Previous frame."
      end

      # x to delete frame
      if (inputs.keyboard.key_down.x) && animation_frames.length > 1
        state.clipboard = selected_animation_frame.pixels
        state.animation_frames = animation_frames.find_all { |v| v.index != state.animation_frames_selected_index }
        if state.animation_frames_selected_index >= state.animation_frames.length
          state.animation_frames_selected_index = state.animation_frames.length - 1
        end
        gtk.notify! "Frame deleted."
      end
    end

    def calc_auto_export
      return if user_is_editing?
      return if state.last_mouse_up.elapsed_time != 30
      # auto export current animation frame if there is no editing for 30 ticks
      queues.create_sprite << { index: state.animation_frames_selected_index,
                                at: Kernel.tick_count }
    end

    def calc_buttons_frame_selection
      state.buttons_frame_selection.items = animation_frames.length.map_with_index do |i|
        { x: state.buttons_frame_selection.left + i * state.buttons_frame_selection.size,
          y: state.buttons_frame_selection.top - state.buttons_frame_selection.size,
          inner_rect: {
            x: (state.buttons_frame_selection.left + 2) + i * state.buttons_frame_selection.size,
            y: (state.buttons_frame_selection.top - state.buttons_frame_selection.size + 2),
            w: 16,
            h: 16,
          },
          w: state.buttons_frame_selection.size,
          h: state.buttons_frame_selection.size,
          index: i }
      end
    end

    def calc_animation_frames
      animation_frames.each_with_index do |animation_frame, i|
        animation_frame.index = i
        animation_frame.rt_name = "animation_frame_#{i}"
      end
    end

    def process_queue_create_sprite
      sprites_to_create = queues.create_sprite
                                .find_all { |h| h.at.elapsed? }

      queues.create_sprite = queues.create_sprite - sprites_to_create

      sprites_to_create.each do |h|
        export_animation_frame h.index, h.path_override
      end
    end

    def process_queue_reset_sprite
      sprites_to_reset = queues.reset_sprite
                               .find_all { |h| h.at.elapsed? }

      queues.reset_sprite -= sprites_to_reset

      sprites_to_reset.each { |h| gtk.reset_sprite (sprite_path h.index) }
    end

    def process_queue_update_rt_animation_frame
      animation_frames_to_update = queues.update_rt_animation_frame
                                         .find_all { |h| h.at.elapsed? }

      queues.update_rt_animation_frame -= animation_frames_to_update

      animation_frames_to_update.each do |h|
        update_animation_frame_render_target animation_frames[h.index]

        if h.queue_sprite_creation
          queues.create_sprite << { index: h.index,
                                    at: Kernel.tick_count + 1 }
        end
      end
    end

    def update_animation_frame_render_target animation_frame
      return if !animation_frame

      outputs[animation_frame.rt_name].transient = true
      outputs[animation_frame.rt_name].width   = state.rt_canvas.size
      outputs[animation_frame.rt_name].height  = state.rt_canvas.size
      outputs[animation_frame.rt_name].solids << animation_frame.pixels.map do |f|
        { x: f.x,
          y: f.y,
          w: 1,
          h: 1, r: 255, g: 255, b: 255 }
      end
    end

    def animation_frames
      state.animation_frames
    end

    def add_animation_frame_to_end
      animation_frames << {
        index: animation_frames.length,
        pixels: [],
        rt_name: "animation_frame_#{animation_frames.length}"
      }

      state.animation_frames_selected_index = (animation_frames.length - 1)
      queues.update_rt_animation_frame << { index: state.animation_frames_selected_index,
                                            at: Kernel.tick_count,
                                            queue_sprite_creation: true }
    end

    def sprite_path i
      "canvas/sprite-#{i}.png"
    end

    def export_animation_frame i, path_override = nil
      return if !state.animation_frames[i]

      outputs.screenshots << state.buttons_frame_selection
                                  .items[i].inner_rect
                                  .merge(path: path_override || (sprite_path i))

      outputs.screenshots << state.buttons_frame_selection
                                  .items[i].inner_rect
                                  .merge(path: "tmp/sprite_backups/#{Time.now.to_i}-sprite-#{i}.png")

      queues.reset_sprite << { index: i, at: Kernel.tick_count }
    end

    def selected_animation_frame
      state.animation_frames[state.animation_frames_selected_index]
    end

    def edit_current_animation_frame point
      draw_area_point = (to_draw_area point)
      if state.edit_mode == :drawing && (!selected_animation_frame.pixels.include? draw_area_point)
        selected_animation_frame.pixels << draw_area_point
        queues.update_rt_animation_frame << { index: state.animation_frames_selected_index,
                                              at: Kernel.tick_count,
                                              queue_sprite_creation: !user_is_editing? }
      elsif state.edit_mode == :erasing && (selected_animation_frame.pixels.include? draw_area_point)
        selected_animation_frame.pixels = selected_animation_frame.pixels.reject { |p| p == draw_area_point }
        queues.update_rt_animation_frame << { index: state.animation_frames_selected_index,
                                              at: Kernel.tick_count,
                                              queue_sprite_creation: !user_is_editing? }
      end
    end

    def user_is_editing?
      state.last_mouse_down > state.last_mouse_up
    end

    def to_draw_area point
      x, y = point.x, point.y
      x -= rt_canvas.sprite.x
      y -= rt_canvas.sprite.y
      { x: x.idiv(rt_canvas.zoom),
        y: y.idiv(rt_canvas.zoom) }
    end

    def rt_canvas
      state.rt_canvas ||= state.new_entity(:rt_canvas)
    end

    def queues
      state.queues ||= state.new_entity(:queues)
    end
  end

  $game = OneBitLowrezPaint.new

  def tick args
    $game.args = args
    $game.tick
  end

  # $gtk.reset

```

### Frame By Frame - main.rb
```ruby
  # ./samples/99_genre_dev_tools/frame_by_frame/app/main.rb
  def tick args
    # create a tick count variant called clock
    # so I can manually control "tick_count"
    args.state.clock ||= 0

    # calc for frame by frame stepping
    calc_debug args

    # conditional calc of game
    calc_game args

    # always render game
    render_game args

    # increment clock
    if args.state.frame_by_frame
      if args.state.increment_frame > 0
        args.state.clock += 1
      end
    else
      args.state.clock += 1
    end
  end

  def calc_debug args
    # create an increment_frame counter for frame by frame
    # stepping
    args.state.increment_frame ||= 0
    args.state.increment_frame  -= 1

    # press l to increment by 30 frames or if any key is pressed
    if args.inputs.keyboard.key_down.l || args.inputs.keyboard.key_down.truthy_keys.length > 0
      args.state.increment_frame = 30
    end

    # enable disable frame by frame mode
    if args.inputs.keyboard.key_down.p
      if args.state.frame_by_frame == true
        args.state.frame_by_frame = false
      else
        args.state.frame_by_frame = true
        args.state.increment_frame = 0
      end
    end

    # press k to increment by one frame
    if args.inputs.keyboard.key_down.k
      args.state.increment_frame = 1
    end
  end

  def render_game args
    args.outputs.sprites << args.state.player
  end

  def calc_game args
    return if args.state.frame_by_frame && args.state.increment_frame < 0

    args.state.player ||= {
      x: 0,
      y: 360,
      w: 40,
      h: 40,
      anchor_x: 0.5,
      anchor_y: 0.5,
      path: :pixel,
      r: 0, g: 0, b: 255
    }

    args.state.player.x += 10
    args.state.player.y += args.inputs.up_down * 10

    if args.state.player.x > 1280
      args.state.player.x = 0
    end

    if args.state.player.y > 720
      args.state.player.y = 0
    elsif args.state.player.y < 0
      args.state.player.y = 720
    end
  end

  $gtk.reset

```

### Tile Editor Starting Point - main.rb
```ruby
  # ./samples/99_genre_dev_tools/tile_editor_starting_point/app/main.rb
  =begin

   APIs listing that haven't been encountered in previous sample apps:

   - to_s: Returns a string representation of an object.
     For example, if we had
     500.to_s
     the string "500" would be returned.
     Similar to to_i, which returns an integer representation of an object.

   - Ceil: Returns an integer number greater than or equal to the original
     with no decimal.

   Reminders:

   - ARRAY#inside_rect?: Returns true or false depending on if the point is inside a rect.

   - args.outputs.labels: An array. The values generate a label.
     The parameters are [X, Y, TEXT, SIZE, ALIGNMENT, RED, GREEN, BLUE, ALPHA, FONT STYLE]
     For more information about labels, go to mygame/documentation/02-labels.md.

   - args.outputs.sprites: An array. The values generate a sprite.
     The parameters are [X, Y, WIDTH, HEIGHT, IMAGE PATH]
     For more information about sprites, go to mygame/documentation/05-sprites.md.

   - args.outputs.solids: An array. The values generate a solid.
     The parameters are [X, Y, WIDTH, HEIGHT, RED, GREEN, BLUE]
     For more information about solids, go to mygame/documentation/03-solids-and-borders.md.

   - args.outputs.lines: An array. The values generate a line.
     The parameters are [X, Y, X2, Y2, RED, GREEN, BLUE]
     For more information about lines, go to mygame/documentation/04-lines.md.

   - args.state.new_entity: Used when we want to create a new object, like a sprite or button.
     In this sample app, new_entity is used to create a new button that clears the grid.
     (Remember, you can use state to define ANY property and it will be retained across frames.)

  =end

  # This sample app shows an empty grid that the user can paint in. There are different image tiles that
  # the user can use to fill the grid, and the "Clear" button can be pressed to clear the grid boxes.

  class TileEditor
    attr_accessor :inputs, :state, :outputs, :grid, :args

    # Runs all the methods necessary for the game to function properly.
    def tick
      defaults
      render
      check_click
      draw_buttons
    end

    # Sets default values
    # Initialization only happens in the first frame
    # NOTE: The values of some of these variables may seem confusingly large at first.
    # The gridSize is 1600 but it seems a lot smaller on the screen, for example.
    # But keep in mind that by using the "W", "A", "S", and "D" keys, you can
    # move the grid's view in all four directions for more grid spaces.
    def defaults
      state.tileCords      ||= []
      state.tileQuantity   ||= 6
      state.tileSize       ||= 50
      state.tileSelected   ||= 1
      state.tempX          ||= 50
      state.tempY          ||= 500
      state.speed          ||= 4
      state.centerX        ||= 4000
      state.centerY        ||= 4000
      state.originalCenter ||= [state.centerX, state.centerY]
      state.gridSize       ||= 1600
      state.lineQuantity   ||= 50
      state.increment      ||= state.gridSize / state.lineQuantity
      state.gridX          ||= []
      state.gridY          ||= []
      state.filled_squares ||= []
      state.grid_border    ||= [390, 140, 500, 500]

      get_grid unless state.tempX == 0 # calls get_grid in the first frame only
      determineTileCords unless state.tempX == 0 # calls determineTileCords in first frame
      state.tempX = 0 # sets tempX to 0; the two methods aren't called again
    end

    # Calculates the placement of lines or separators in the grid
    def get_grid
      curr_x = state.centerX - (state.gridSize / 2) # starts at left of grid
      deltaX = state.gridSize / state.lineQuantity # finds distance to place vertical lines evenly through width of grid
      (state.lineQuantity + 2).times do
        state.gridX << curr_x # adds curr_x to gridX collection
        curr_x += deltaX # increment curr_x by the distance between vertical lines
      end

      curr_y = state.centerY - (state.gridSize / 2) # starts at bottom of grid
      deltaY = state.gridSize / state.lineQuantity # finds distance to place horizontal lines evenly through height of grid
      (state.lineQuantity + 2).times do
        state.gridY << curr_y # adds curr_y to gridY collection
        curr_y += deltaY # increments curr_y to distance between horizontal lines
      end
    end

    # Determines coordinate positions of patterned tiles (on the left side of the grid)
    def determineTileCords
      state.tempCounter ||= 1 # initializes tempCounter to 1
      state.tileQuantity.times do # there are 6 different kinds of tiles
        state.tileCords += [[state.tempX, state.tempY, state.tempCounter]] # adds tile definition to collection
        state.tempX += 75 # increments tempX to put horizontal space between the patterned tiles
        state.tempCounter += 1 # increments tempCounter
        if state.tempX > 200 # if tempX exceeds 200 pixels
          state.tempX = 50 # a new row of patterned tiles begins
          state.tempY -= 75 # the new row is 75 pixels lower than the previous row
        end
      end
    end

    # Outputs objects (grid, tiles, etc) onto the screen
    def render
      outputs.sprites << state.tileCords.map do # outputs tileCords collection using images in sprites folder
        |x, y, order|
        [x, y, state.tileSize, state.tileSize, 'sprites/image' + order.to_s + ".png"]
      end
      outputs.solids << [0, 0, 1280, 720, 255, 255, 255] # outputs white background
      add_grid # outputs grid
      print_title # outputs title and current tile pattern
    end

    # Creates a grid by outputting vertical and horizontal grid lines onto the screen.
    # Outputs sprites for the filled_squares collection onto the screen.
    def add_grid

      # Outputs the grid's border.
      outputs.borders << state.grid_border
      temp = 0

      # Before looking at the code that outputs the vertical and horizontal lines in the
      # grid, take note of the fact that:
      # grid_border[1] refers to the border's bottom line (running horizontally),
      # grid_border[2] refers to the border's top line (running (horizontally),
      # grid_border[0] refers to the border's left line (running vertically),
      # and grid_border[3] refers to the border's right line (running vertically).

      #           [2]
      #       ----------
      #       |        |
      # [0]   |        | [3]
      #       |        |
      #       ----------
      #           [1]

      # Calculates the positions and outputs the x grid lines in the color gray.
      state.gridX.map do # perform an action on all elements of the gridX collection
        |x|
        temp += 1 # increment temp

        # if x's value is greater than (or equal to) the x value of the border's left side
        # and less than (or equal to) the x value of the border's right side
        if x >= state.centerX - (state.grid_border[2] / 2) && x <= state.centerX + (state.grid_border[2] / 2)
          delta = state.centerX - 640
          # vertical lines have the same starting and ending x positions
          # starting y and ending y positions lead from the bottom of the border to the top of the border
          outputs.lines << [x - delta, state.grid_border[1], x - delta, state.grid_border[1] + state.grid_border[2], 150, 150, 150] # sets definition of vertical line and outputs it
        end
      end
      temp = 0

      # Calculates the positions and outputs the y grid lines in the color gray.
      state.gridY.map do # perform an action on all elements of the gridY collection
        |y|
        temp += 1 # increment temp

        # if y's value is greater than (or equal to) the y value of the border's bottom side
        # and less than (or equal to) the y value of the border's top side
        if y >= state.centerY - (state.grid_border[3] / 2) && y <= state.centerY + (state.grid_border[3] / 2)
          delta = state.centerY - 393
          # horizontal lines have the same starting and ending y positions
          # starting x and ending x positions lead from the left side of the border to the right side of the border
          outputs.lines << [state.grid_border[0], y - delta, state.grid_border[0] + state.grid_border[3], y - delta, 150, 150, 150] # sets definition of horizontal line and outputs it
        end
      end

      # Sets values and outputs sprites for the filled_squares collection.
      state.filled_squares.map do # perform an action on every element of the filled_squares collection
        |x, y, w, h, sprite|
          # if x's value is greater than (or equal to) the x value of 17 pixels to the left of the border's left side
          # and less than (or equal to) the x value of the border's right side
          # and y's value is greater than (or equal to) the y value of the border's bottom side
          # and less than (or equal to) the y value of 25 pixels above the border's top side
          # NOTE: The allowance of 17 pixels and 25 pixels is due to the fact that a grid box may be slightly cut off or
          # not entirely visible in the grid's view (until it is moved using "W", "A", "S", "D")
          if x >= state.centerX - (state.grid_border[2] / 2) - 17 && x <= state.centerX + (state.grid_border[2] / 2) &&
             y >= state.centerY - (state.grid_border[3] / 2) && y <= state.centerY + (state.grid_border[3] / 2) + 25
            # calculations done to place sprites in grid spaces that are meant to filled in
            # mess around with the x and y values and see how the sprite placement changes
            outputs.sprites << [x - state.centerX + 630, y - state.centerY + 360, w, h, sprite]
          end
        end

        # outputs a white solid along the left side of the grid (change the color and you'll be able to see it against the white background)
        # state.increment subtracted in x parameter because solid's position is denoted by bottom left corner
        # state.increment subtracted in y parameter to avoid covering the title label
        outputs.primitives << [state.grid_border[0] - state.increment,
                               state.grid_border[1] - state.increment, state.increment, state.grid_border[3] + (state.increment * 2),
                               255, 255, 255].solid

        # outputs a white solid along the right side of the grid
        # state.increment subtracted from y parameter to avoid covering title label
        outputs.primitives << [state.grid_border[0] + state.grid_border[2],
                               state.grid_border[1] - state.increment, state.increment, state.grid_border[3] + (state.increment * 2),
                               255, 255, 255].solid

        # outputs a white solid along the bottom of the grid
        # state.increment subtracted from y parameter to avoid covering last row of grid boxes
        outputs.primitives << [state.grid_border[0] - state.increment, state.grid_border[1] - state.increment,
                               state.grid_border[2] + (2 * state.increment), state.increment, 255, 255, 255].solid

        # outputs a white solid along the top of the grid
        outputs.primitives << [state.grid_border[0] - state.increment, state.grid_border[1] + state.grid_border[3],
                               state.grid_border[2] + (2 * state.increment), state.increment, 255, 255, 255].solid

    end

    # Outputs title and current tile pattern
    def print_title
      outputs.labels << [640, 700, 'Mouse to Place Tile, WASD to Move Around', 7, 1] # title label
      outputs.lines << horizontal_separator(660, 0, 1280) # outputs horizontal separator
      outputs.labels << [1050, 500, 'Current:', 3, 1] # outputs Current label
      outputs.sprites << [1110, 474, state.tileSize / 2, state.tileSize / 2, 'sprites/image' + state.tileSelected.to_s + ".png"] # outputs sprite of current tile pattern using images in sprites folder; output is half the size of a tile
    end

    # Sets the starting position, ending position, and color for the horizontal separator.
    def horizontal_separator y, x, x2
      [x, y, x2, y, 150, 150, 150] # definition of separator; horizontal line means same starting/ending y
    end

    # Checks if the mouse is being clicked or dragged
    def check_click
      if inputs.keyboard.key_down.r # if the "r" key is pressed down
        $dragon.reset
      end

      if inputs.mouse.down #is mouse up or down?
        state.mouse_held = true
        if inputs.mouse.position.x < state.grid_border[0] # if mouse's x position is inside the grid's borders
          state.tileCords.map do # perform action on all elements of tileCords collection
            |x, y, order|
            # if mouse's x position is greater than (or equal to) the starting x position of a tile
            # and the mouse's x position is also less than (or equal to) the ending x position of that tile,
            # and the mouse's y position is greater than (or equal to) the starting y position of that tile,
            # and the mouse's y position is also less than (or equal to) the ending y position of that tile,
            # (BASICALLY, IF THE MOUSE'S POSITION IS WITHIN THE STARTING AND ENDING POSITIONS OF A TILE)
            if inputs.mouse.position.x >= x && inputs.mouse.position.x <= x + state.tileSize &&
               inputs.mouse.position.y >= y && inputs.mouse.position.y <= y + state.tileSize
              state.tileSelected = order # that tile is selected
            end
          end
        end
      elsif inputs.mouse.up # otherwise, if the mouse is in the "up" state
        state.mouse_held = false # mouse is not held down or dragged
        state.mouse_dragging = false
      end

      if state.mouse_held &&    # mouse needs to be down
         !inputs.mouse.click &&     # must not be first click
         ((inputs.mouse.previous_click.point.x - inputs.mouse.position.x).abs > 15 ||
          (inputs.mouse.previous_click.point.y - inputs.mouse.position.y).abs > 15) # Need to move 15 pixels before "drag"
        state.mouse_dragging = true
      end

      # if mouse is clicked inside grid's border, search_lines method is called with click input type
      if ((inputs.mouse.click) && (inputs.mouse.click.point.inside_rect? state.grid_border))
        search_lines(inputs.mouse.click.point, :click)

      # if mouse is dragged inside grid's border, search_lines method is called with drag input type
      elsif ((state.mouse_dragging) && (inputs.mouse.position.inside_rect? state.grid_border))
        search_lines(inputs.mouse.position, :drag)
      end

      # Changes grid's position on screen by moving it up, down, left, or right.

      # centerX is incremented by speed if the "d" key is pressed and if that sum is less than
      # the original left side of the center plus half the grid, minus half the top border of grid.
      # MOVES GRID RIGHT (increasing x)
      state.centerX += state.speed if inputs.keyboard.key_held.d &&
                                      (state.centerX + state.speed) < state.originalCenter[0] + (state.gridSize / 2) - (state.grid_border[2] / 2)
      # centerX is decremented by speed if the "a" key is pressed and if that difference is greater than
      # the original left side of the center minus half the grid, plus half the top border of grid.
      # MOVES GRID LEFT (decreasing x)
      state.centerX -= state.speed if inputs.keyboard.key_held.a &&
                                      (state.centerX - state.speed) > state.originalCenter[0] - (state.gridSize / 2) + (state.grid_border[2] / 2)
      # centerY is incremented by speed if the "w" key is pressed and if that sum is less than
      # the original bottom of the center plus half the grid, minus half the right border of grid.
      # MOVES GRID UP (increasing y)
      state.centerY += state.speed if inputs.keyboard.key_held.w &&
                                      (state.centerY + state.speed) < state.originalCenter[1] + (state.gridSize / 2) - (state.grid_border[3] / 2)
      # centerY is decremented by speed if the "s" key is pressed and if the difference is greater than
      # the original bottom of the center minus half the grid, plus half the right border of grid.
      # MOVES GRID DOWN (decreasing y)
      state.centerY -= state.speed if inputs.keyboard.key_held.s &&
                                      (state.centerY - state.speed) > state.originalCenter[1] - (state.gridSize / 2) + (state.grid_border[3] / 2)
    end

    # Performs calculations on the gridX and gridY collections, and sets values.
    # Sets the definition of a grid box, including the image that it is filled with.
    def search_lines (point, input_type)
      point.x += state.centerX - 630 # increments x and y
      point.y += state.centerY - 360
      findX = 0
      findY = 0
      increment = state.gridSize / state.lineQuantity # divides grid by number of separators

      state.gridX.map do # perform an action on every element of collection
        |x|
        # findX increments x by 10 if point.x is less than that sum and findX is currently 0
        findX = x + 10 if point.x < (x + 10) && findX == 0
      end

      state.gridY.map do
        |y|
        # findY is set to y if point.y is less than that value and findY is currently 0
        findY = y if point.y < (y) && findY == 0
      end
      # position of a box is denoted by bottom left corner, which is why the increment is being subtracted
      grid_box = [findX - (increment.ceil), findY - (increment.ceil), increment.ceil, increment.ceil,
                  "sprites/image" + state.tileSelected.to_s + ".png"] # sets sprite definition

      if input_type == :click # if user clicks their mouse
        if state.filled_squares.include? grid_box # if grid box is already filled in
          state.filled_squares.delete grid_box # box is cleared and removed from filled_squares
        else
          state.filled_squares << grid_box # otherwise, box is filled in and added to filled_squares
        end
      elsif input_type == :drag # if user drags mouse
        unless state.filled_squares.include? grid_box # unless grid box dragged over is already filled in
          state.filled_squares << grid_box # box is filled in and added to filled_squares
        end
      end
    end

    # Creates a "Clear" button using labels and borders.
    def draw_buttons
      x, y, w, h = 390, 50, 240, 50
      state.clear_button        ||= state.new_entity(:button_with_fade)

      # x and y positions are set to display "Clear" label in center of the button
      # Try changing first two parameters to simply x, y and see what happens to the text placement
      state.clear_button.label  ||= [x + w.half, y + h.half + 10, "Clear", 0, 1]
      state.clear_button.border ||= [x, y, w, h] # definition of button's border

      # If the mouse is clicked inside the borders of the clear button
      if inputs.mouse.click && inputs.mouse.click.point.inside_rect?(state.clear_button.border)
        state.clear_button.clicked_at = inputs.mouse.click.created_at # value is frame of mouse click
        state.filled_squares.clear # filled squares collection is emptied (squares are cleared)
        inputs.mouse.previous_click = nil # no previous click
      end

      outputs.labels << state.clear_button.label # outputs clear button
      outputs.borders << state.clear_button.border

      # When the clear button is clicked, the color of the button changes
      # and the transparency changes, as well. If you change the time from
      # 0.25.seconds to 1.25.seconds or more, the change will last longer.
      if state.clear_button.clicked_at
        outputs.solids << [x, y, w, h, 0, 180, 80, 255 * state.clear_button.clicked_at.ease(0.25.seconds, :flip)]
      end
    end
  end

  $tile_editor = TileEditor.new

  def tick args
    $tile_editor.inputs = args.inputs
    $tile_editor.grid = args.grid
    $tile_editor.args = args
    $tile_editor.outputs = args.outputs
    $tile_editor.state = args.state
    $tile_editor.tick
    tick_instructions args, "Roll your own tile editor. CLICK to select a sprite. CLICK in grid to place sprite. WASD to move around."
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
