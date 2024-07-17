### Roguelike Starting Point - constants.rb
```ruby
  # ./samples/99_genre_rpg_roguelike/01_roguelike_starting_point/app/constants.rb
  SHOW_LEGEND = true
  SOURCE_TILE_SIZE = 16
  DESTINATION_TILE_SIZE = 16
  TILE_SHEET_SIZE = 256
  TILE_R = 0
  TILE_G = 0
  TILE_B = 0
  TILE_A = 255

```

### Roguelike Starting Point - legend.rb
```ruby
  # ./samples/99_genre_rpg_roguelike/01_roguelike_starting_point/app/legend.rb
  def tick_legend args
    return unless SHOW_LEGEND

    legend_padding = 16
    legend_x = 1280 - TILE_SHEET_SIZE - legend_padding
    legend_y =  720 - TILE_SHEET_SIZE - legend_padding
    tile_sheet_sprite = [legend_x,
                         legend_y,
                         TILE_SHEET_SIZE,
                         TILE_SHEET_SIZE,
                         'sprites/simple-mood-16x16.png', 0,
                         TILE_A,
                         TILE_R,
                         TILE_G,
                         TILE_B]

    if args.inputs.mouse.point.inside_rect? tile_sheet_sprite
      mouse_row = args.inputs.mouse.point.y.idiv(SOURCE_TILE_SIZE)
      tile_row = 15 - (mouse_row - legend_y.idiv(SOURCE_TILE_SIZE))

      mouse_col = args.inputs.mouse.point.x.idiv(SOURCE_TILE_SIZE)
      tile_col = (mouse_col - legend_x.idiv(SOURCE_TILE_SIZE))

      args.outputs.primitives << [legend_x - legend_padding * 2,
                                  mouse_row * SOURCE_TILE_SIZE, 256 + legend_padding * 2, 16, 128, 128, 128, 64].solid

      args.outputs.primitives << [mouse_col * SOURCE_TILE_SIZE,
                                  legend_y - legend_padding * 2, 16, 256 + legend_padding * 2, 128, 128, 128, 64].solid

      sprite_key = sprite_lookup.find { |k, v| v == [tile_row, tile_col] }
      if sprite_key
        member_name, _ = sprite_key
        member_name = member_name_as_code member_name
        args.outputs.labels << [660, 70, "# CODE SAMPLE (place in the tick_game method located in main.rb)", -1, 0]
        args.outputs.labels << [660, 50, "#                                    GRID_X, GRID_Y, TILE_KEY", -1, 0]
        args.outputs.labels << [660, 30, "args.outputs.sprites << tile_in_game(     5,      6, #{member_name}    )", -1, 0]
      else
        args.outputs.labels << [660, 50, "Tile [#{tile_row}, #{tile_col}] not found. Add a key and value to app/sprite_lookup.rb:", -1, 0]
        args.outputs.labels << [660, 30, "{ \"some_string\" => [#{tile_row}, #{tile_col}] } OR { some_symbol: [#{tile_row}, #{tile_col}] }.", -1, 0]
      end

    end

    # render the sprite in the top right with a padding to the top and right so it's
    # not flush against the edge
    args.outputs.sprites << tile_sheet_sprite

    # carefully place some ascii arrows to show the legend labels
    args.outputs.labels  <<  [895, 707, "ROW --->"]
    args.outputs.labels  <<  [943, 412, "       ^"]
    args.outputs.labels  <<  [943, 412, "       |"]
    args.outputs.labels  <<  [943, 394, "COL ---+"]

    # use the tile sheet to print out row and column numbers
    args.outputs.sprites << 16.map_with_index do |i|
      sprite_key = i % 10
      [
        tile(1280 - TILE_SHEET_SIZE - legend_padding * 2 - SOURCE_TILE_SIZE,
              720 - legend_padding * 2 - (SOURCE_TILE_SIZE * i),
              sprite(sprite_key)),
        tile(1280 - TILE_SHEET_SIZE - SOURCE_TILE_SIZE + (SOURCE_TILE_SIZE * i),
              720 - TILE_SHEET_SIZE - legend_padding * 3, sprite(sprite_key))
      ]
    end
  end

```

### Roguelike Starting Point - main.rb
```ruby
  # ./samples/99_genre_rpg_roguelike/01_roguelike_starting_point/app/main.rb
  require 'app/constants.rb'
  require 'app/sprite_lookup.rb'
  require 'app/legend.rb'

  def tick args
    tick_game args
    tick_legend args
  end

  def tick_game args
    # setup the grid
    args.state.grid.padding = 104
    args.state.grid.size = 512

    # set up your game
    # initialize the game/game defaults. ||= means that you only initialize it if
    # the value isn't alread initialized
    args.state.player.x ||= 0
    args.state.player.y ||= 0

    args.state.enemies ||= [
      { x: 10, y: 10, type: :goblin, tile_key: :G },
      { x: 15, y: 30, type: :rat,    tile_key: :R }
    ]

    args.state.info_message ||= "Use arrow keys to move around."

    # handle keyboard input
    # keyboard input (arrow keys to move player)
    new_player_x = args.state.player.x
    new_player_y = args.state.player.y
    player_direction = ""
    player_moved = false
    if args.inputs.keyboard.key_down.up
      new_player_y += 1
      player_direction = "north"
      player_moved = true
    elsif args.inputs.keyboard.key_down.down
      new_player_y -= 1
      player_direction = "south"
      player_moved = true
    elsif args.inputs.keyboard.key_down.right
      new_player_x += 1
      player_direction = "east"
      player_moved = true
    elsif args.inputs.keyboard.key_down.left
      new_player_x -= 1
      player_direction = "west"
      player_moved = true
    end

    #handle game logic
    # determine if there is an enemy on that square,
    # if so, don't let the player move there
    if player_moved
      found_enemy = args.state.enemies.find do |e|
        e[:x] == new_player_x && e[:y] == new_player_y
      end

      if !found_enemy
        args.state.player.x = new_player_x
        args.state.player.y = new_player_y
        args.state.info_message = "You moved #{player_direction}."
      else
        args.state.info_message = "You cannot move into a square an enemy occupies."
      end
    end

    args.outputs.sprites << tile_in_game(args.state.player.x,
                                         args.state.player.y, '@')

    # render game
    # render enemies at locations
    args.outputs.sprites << args.state.enemies.map do |e|
      tile_in_game(e[:x], e[:y], e[:tile_key])
    end

    # render the border
    border_x = args.state.grid.padding - DESTINATION_TILE_SIZE
    border_y = args.state.grid.padding - DESTINATION_TILE_SIZE
    border_size = args.state.grid.size + DESTINATION_TILE_SIZE * 2

    args.outputs.borders << [border_x,
                             border_y,
                             border_size,
                             border_size]

    # render label stuff
    args.outputs.labels << [border_x, border_y - 10, "Current player location is: #{args.state.player.x}, #{args.state.player.y}"]
    args.outputs.labels << [border_x, border_y + 25 + border_size, args.state.info_message]
  end

  def tile_in_game x, y, tile_key
    tile($gtk.args.state.grid.padding + x * DESTINATION_TILE_SIZE,
         $gtk.args.state.grid.padding + y * DESTINATION_TILE_SIZE,
         tile_key)
  end

```

### Roguelike Starting Point - sprite_lookup.rb
```ruby
  # ./samples/99_genre_rpg_roguelike/01_roguelike_starting_point/app/sprite_lookup.rb
  def sprite_lookup
    {
      0 => [3, 0],
      1 => [3, 1],
      2 => [3, 2],
      3 => [3, 3],
      4 => [3, 4],
      5 => [3, 5],
      6 => [3, 6],
      7 => [3, 7],
      8 => [3, 8],
      9 => [3, 9],
      '@' => [4, 0],
      A: [ 4,  1],
      B: [ 4,  2],
      C: [ 4,  3],
      D: [ 4,  4],
      E: [ 4,  5],
      F: [ 4,  6],
      G: [ 4,  7],
      H: [ 4,  8],
      I: [ 4,  9],
      J: [ 4, 10],
      K: [ 4, 11],
      L: [ 4, 12],
      M: [ 4, 13],
      N: [ 4, 14],
      O: [ 4, 15],
      P: [ 5,  0],
      Q: [ 5,  1],
      R: [ 5,  2],
      S: [ 5,  3],
      T: [ 5,  4],
      U: [ 5,  5],
      V: [ 5,  6],
      W: [ 5,  7],
      X: [ 5,  8],
      Y: [ 5,  9],
      Z: [ 5, 10],
      a: [ 6,  1],
      b: [ 6,  2],
      c: [ 6,  3],
      d: [ 6,  4],
      e: [ 6,  5],
      f: [ 6,  6],
      g: [ 6,  7],
      h: [ 6,  8],
      i: [ 6,  9],
      j: [ 6, 10],
      k: [ 6, 11],
      l: [ 6, 12],
      m: [ 6, 13],
      n: [ 6, 14],
      o: [ 6, 15],
      p: [ 7,  0],
      q: [ 7,  1],
      r: [ 7,  2],
      s: [ 7,  3],
      t: [ 7,  4],
      u: [ 7,  5],
      v: [ 7,  6],
      w: [ 7,  7],
      x: [ 7,  8],
      y: [ 7,  9],
      z: [ 7, 10],
      '|' => [ 7, 12]
    }
  end

  def sprite key
    $gtk.args.state.reserved.sprite_lookup[key]
  end

  def member_name_as_code raw_member_name
    if raw_member_name.is_a? Symbol
      ":#{raw_member_name}"
    elsif raw_member_name.is_a? String
      "'#{raw_member_name}'"
    elsif raw_member_name.is_a? Fixnum
      "#{raw_member_name}"
    else
      "UNKNOWN: #{raw_member_name}"
    end
  end

  def tile x, y, tile_row_column_or_key
    tile_extended x, y, DESTINATION_TILE_SIZE, DESTINATION_TILE_SIZE, TILE_R, TILE_G, TILE_B, TILE_A, tile_row_column_or_key
  end

  def tile_extended x, y, w, h, r, g, b, a, tile_row_column_or_key
    row_or_key, column = tile_row_column_or_key
    if !column
      row, column = sprite row_or_key
    else
      row, column = row_or_key, column
    end

    if !row
      member_name = member_name_as_code tile_row_column_or_key
      raise "Unabled to find a sprite for #{member_name}. Make sure the value exists in app/sprite_lookup.rb."
    end

    # Sprite provided by Rogue Yun
    # http://www.bay12forums.com/smf/index.php?topic=144897.0
    # License: Public Domain

    {
      x: x,
      y: y,
      w: w,
      h: h,
      tile_x: column * 16,
      tile_y: (row * 16),
      tile_w: 16,
      tile_h: 16,
      r: r,
      g: g,
      b: b,
      a: a,
      path: 'sprites/simple-mood-16x16.png'
    }
  end

  $gtk.args.state.reserved.sprite_lookup = sprite_lookup

```

### Roguelike Line Of Sight - main.rb
```ruby
  # ./samples/99_genre_rpg_roguelike/02_roguelike_line_of_sight/app/main.rb
  =begin

   APIs listing that haven't been encountered in previous sample apps:

   - lambda: A way to define a block and its parameters with special syntax.
     For example, the syntax of lambda looks like this:
     my_lambda = -> { puts "This is my lambda" }

   Reminders:
   - args.outputs.labels: An array. The values generate a label.
     The parameters are [X, Y, TEXT, SIZE, ALIGNMENT, RED, GREEN, BLUE, ALPHA, FONT STYLE]
     For more information about labels, go to mygame/documentation/02-labels.

   - ARRAY#inside_rect?: Returns whether or not the point is inside a rect.

   - product: Returns an array of all combinations of elements from all arrays.

   - find: Finds all elements of a collection that meet requirements.

   - abs: Returns the absolute value.

  =end

  # This sample app allows the player to move around in the dungeon, which becomes more or less visible
  # depending on the player's location, and also has enemies.

  class Game
    attr_accessor :args, :state, :inputs, :outputs, :grid

    # Calls all the methods needed for the game to run properly.
    def tick
      defaults
      render_canvas
      render_dungeon
      render_player
      render_enemies
      print_cell_coordinates
      calc_canvas
      input_move
      input_click_map
    end

    # Sets default values and initializes variables
    def defaults
      outputs.background_color = [0, 0, 0] # black background

      # Initializes empty canvas, dungeon, and enemies collections.
      state.canvas   ||= []
      state.dungeon  ||= []
      state.enemies  ||= []

      # If state.area doesn't have value, load_area_one and derive_dungeon_from_area methods are called
      if !state.area
        load_area_one
        derive_dungeon_from_area

        # Changing these values will change the position of player
        state.x = 7
        state.y = 5

        # Creates new enemies, sets their values, and adds them to the enemies collection.
        state.enemies << state.new_entity(:enemy) do |e| # declares each enemy as new entity
          e.x           = 13 # position
          e.y           = 5
          e.previous_hp = 3
          e.hp          = 3
          e.max_hp      = 3
          e.is_dead     = false # the enemy is alive
        end

        update_line_of_sight # updates line of sight by adding newly visible cells
      end
    end

    # Adds elements into the state.area collection
    # The dungeon is derived using the coordinates of this collection
    def load_area_one
      state.area ||= []
      state.area << [8, 6]
      state.area << [7, 6]
      state.area << [7, 7]
      state.area << [8, 9]
      state.area << [7, 8]
      state.area << [7, 9]
      state.area << [6, 4]
      state.area << [7, 3]
      state.area << [7, 4]
      state.area << [6, 5]
      state.area << [7, 5]
      state.area << [8, 5]
      state.area << [8, 4]
      state.area << [1, 1]
      state.area << [0, 1]
      state.area << [0, 2]
      state.area << [1, 2]
      state.area << [2, 2]
      state.area << [2, 1]
      state.area << [2, 3]
      state.area << [1, 3]
      state.area << [1, 4]
      state.area << [2, 4]
      state.area << [2, 5]
      state.area << [1, 5]
      state.area << [2, 6]
      state.area << [3, 6]
      state.area << [4, 6]
      state.area << [4, 7]
      state.area << [4, 8]
      state.area << [5, 8]
      state.area << [5, 9]
      state.area << [6, 9]
      state.area << [7, 10]
      state.area << [7, 11]
      state.area << [7, 12]
      state.area << [7, 12]
      state.area << [7, 13]
      state.area << [8, 13]
      state.area << [9, 13]
      state.area << [10, 13]
      state.area << [11, 13]
      state.area << [12, 13]
      state.area << [12, 12]
      state.area << [8, 12]
      state.area << [9, 12]
      state.area << [10, 12]
      state.area << [11, 12]
      state.area << [12, 11]
      state.area << [13, 11]
      state.area << [13, 10]
      state.area << [13, 9]
      state.area << [13, 8]
      state.area << [13, 7]
      state.area << [13, 6]
      state.area << [12, 6]
      state.area << [14, 6]
      state.area << [14, 5]
      state.area << [13, 5]
      state.area << [12, 5]
      state.area << [12, 4]
      state.area << [13, 4]
      state.area << [14, 4]
      state.area << [1, 6]
      state.area << [6, 6]
    end

    # Starts with an empty dungeon collection, and adds dungeon cells into it.
    def derive_dungeon_from_area
      state.dungeon = [] # starts as empty collection

      state.area.each do |a| # for each element of the area collection
        state.dungeon << state.new_entity(:dungeon_cell) do |d| # declares each dungeon cell as new entity
          d.x = a.x # dungeon cell position using coordinates from area
          d.y = a.y
          d.is_visible = false # cell is not visible
          d.alpha = 0 # not transparent at all
          d.border = [left_margin   + a.x * grid_size,
                      bottom_margin + a.y * grid_size,
                      grid_size,
                      grid_size,
                      *blue,
                      255] # sets border definition for dungeon cell
          d # returns dungeon cell
        end
      end
    end

    def left_margin
      40  # sets left margin
    end

    def bottom_margin
      60 # sets bottom margin
    end

    def grid_size
      40 # sets size of grid square
    end

    # Updates the line of sight by calling the thick_line_of_sight method and
    # adding dungeon cells to the newly_visible collection
    def update_line_of_sight
      variations = [-1, 0, 1]
      # creates collection of newly visible dungeon cells
      newly_visible = variations.product(variations).flat_map do |rise, run| # combo of all elements
        thick_line_of_sight state.x, state.y, rise, run, 15, # calls thick_line_of_sight method
                            lambda { |x, y| dungeon_cell_exists? x, y } # checks whether or not cell exists
      end.uniq# removes duplicates

      state.dungeon.each do |d| # perform action on each element of dungeons collection
        d.is_visible = newly_visible.find { |v| v.x == d.x && v.y == d.y } # finds match inside newly_visible collection
      end
    end

    #Returns a boolean value
    def dungeon_cell_exists? x, y
      # Finds cell coordinates inside dungeon collection to determine if dungeon cell exists
      state.dungeon.find { |d| d.x == x && d.y == y }
    end

    # Calls line_of_sight method to add elements to result collection
    def thick_line_of_sight start_x, start_y, rise, run, distance, cell_exists_lambda
      result = []
      result += line_of_sight start_x, start_y, rise, run, distance, cell_exists_lambda
      result += line_of_sight start_x - 1, start_y, rise, run, distance, cell_exists_lambda # one left
      result += line_of_sight start_x + 1, start_y, rise, run, distance, cell_exists_lambda # one right
      result
    end

    # Adds points to the result collection to create the player's line of sight
    def line_of_sight start_x, start_y, rise, run, distance, cell_exists_lambda
      result = [] # starts as empty collection
      points = points_on_line start_x, start_y, rise, run, distance # calls points_on_line method
      points.each do |p| # for each point in collection
        if cell_exists_lambda.call(p.x, p.y) # if the cell exists
          result << p # add it to result collection
        else # if cell does not exist
          return result # return result collection as it is
        end
      end

      result # return result collection
    end

    # Finds the coordinates of the points on the line by performing calculations
    def points_on_line start_x, start_y, rise, run, distance
      distance.times.map do |i| # perform an action
        [start_x + run * i, start_y + rise * i] # definition of point
      end
    end

    def render_canvas
      return
      outputs.borders << state.canvas.map do |c| # on each element of canvas collection
        c.border # outputs border
      end
    end

    # Outputs the dungeon cells.
    def render_dungeon
      outputs.solids << [0, 0, grid.w, grid.h] # outputs black background for grid

      # Sets the alpha value (opacity) for each dungeon cell and calls the cell_border method.
      outputs.borders << state.dungeon.map do |d| # for each element in dungeon collection
        d.alpha += if d.is_visible # if cell is visible
                   255.fdiv(30) # increment opacity (transparency)
                 else # if cell is not visible
                   255.fdiv(600) * -1 # decrease opacity
                 end
        d.alpha = d.alpha.cap_min_max(0, 255)
        cell_border d.x, d.y, [*blue, d.alpha] # sets blue border using alpha value
      end.reject_nil
    end

    # Sets definition of a cell border using the parameters
    def cell_border x, y, color = nil
      [left_margin   + x * grid_size,
      bottom_margin + y * grid_size,
      grid_size,
      grid_size,
      *color]
    end

    # Sets the values for the player and outputs it as a label
    def render_player
      outputs.labels << [grid_x(state.x) + 20, # positions "@" text in center of grid square
                       grid_y(state.y) + 35,
                       "@", # player is represented by a white "@" character
                       1, 1, *white]
    end

    def grid_x x
      left_margin + x * grid_size # positions horizontally on grid
    end

    def grid_y y
      bottom_margin + y * grid_size # positions vertically on grid
    end

    # Outputs enemies onto the screen.
    def render_enemies
      state.enemies.map do |e| # for each enemy in the collection
        alpha = 255 # set opacity (full transparency)

        # Outputs an enemy using a label.
        outputs.labels << [
                     left_margin + 20 +  e.x * grid_size, # positions enemy's "r" text in center of grid square
                     bottom_margin + 35 + e.y * grid_size,
                     "r", # enemy's text
                     1, 1, *white, alpha]

        # Creates a red border around an enemy.
        outputs.borders << [grid_x(e.x), grid_y(e.y), grid_size, grid_size, *red]
      end
    end

    #White labels are output for the cell coordinates of each element in the dungeon collection.
    def print_cell_coordinates
      return unless state.debug
      state.dungeon.each do |d|
        outputs.labels << [grid_x(d.x) + 2,
                           grid_y(d.y) - 2,
                           "#{d.x},#{d.y}",
                           -2, 0, *white]
      end
    end

    # Adds new elements into the canvas collection and sets their values.
    def calc_canvas
      return if state.canvas.length > 0 # return if canvas collection has at least one element
      15.times do |x| # 15 times perform an action
        15.times do |y|
          state.canvas << state.new_entity(:canvas) do |c| # declare canvas element as new entity
            c.x = x # set position
            c.y = y
            c.border = [left_margin   + x * grid_size,
                        bottom_margin + y * grid_size,
                        grid_size,
                        grid_size,
                        *white, 30] # sets border definition
          end
        end
      end
    end

    # Updates x and y values of the player, and updates player's line of sight
    def input_move
      x, y, x_diff, y_diff = input_target_cell

      return unless dungeon_cell_exists? x, y # player can't move there if a dungeon cell doesn't exist in that location
      return if enemy_at x, y # player can't move there if there is an enemy in that location

      state.x += x_diff # increments x by x_diff (so player moves left or right)
      state.y += y_diff # same with y and y_diff ( so player moves up or down)
      update_line_of_sight # updates visible cells
    end

    def enemy_at x, y
      # Finds if coordinates exist in enemies collection and enemy is not dead
      state.enemies.find { |e| e.x == x && e.y == y && !e.is_dead }
    end

    #M oves the user based on their keyboard input and sets values for target cell
    def input_target_cell
      if inputs.keyboard.key_down.up # if "up" key is in "down" state
        [state.x, state.y + 1,  0,  1] # user moves up
      elsif inputs.keyboard.key_down.down # if "down" key is pressed
        [state.x, state.y - 1,  0, -1] # user moves down
      elsif inputs.keyboard.key_down.left # if "left" key is pressed
        [state.x - 1, state.y, -1,  0] # user moves left
      elsif inputs.keyboard.key_down.right # if "right" key is pressed
        [state.x + 1, state.y,  1,  0] # user moves right
      else
        nil  # otherwise, empty
      end
    end

    # Goes through the canvas collection to find if the mouse was clicked inside of the borders of an element.
    def input_click_map
      return unless inputs.mouse.click # return unless the mouse is clicked
      canvas_entry = state.canvas.find do |c| # find element from canvas collection that meets requirements
        inputs.mouse.click.inside_rect? c.border # find border that mouse was clicked inside of
      end
      puts canvas_entry # prints canvas_entry value
    end

    # Sets the definition of a label using the parameters.
    def label text, x, y, color = nil
      color ||= white # color is initialized to white
      [x, y, text, 1, 1, *color] # sets label definition
    end

    def green
      [60, 200, 100] # sets color saturation to shade of green
    end

    def blue
      [50, 50, 210] # sets color saturation to shade of blue
    end

    def white
      [255, 255, 255] # sets color saturation to white
    end

    def red
      [230, 80, 80] # sets color saturation to shade of red
    end

    def orange
      [255, 80, 60] # sets color saturation to shade of orange
    end

    def pink
      [255, 0, 200] # sets color saturation to shade of pink
    end

    def gray
      [75, 75, 75] # sets color saturation to shade of gray
    end

    # Recolors the border using the parameters.
    def recolor_border border, r, g, b
      border[4] = r
      border[5] = g
      border[6] = b
      border
    end

    # Returns a boolean value.
    def visible? cell
      # finds cell's coordinates inside visible_cells collections to determine if cell is visible
      state.visible_cells.find { |c| c.x == cell.x && c.y == cell.y}
    end

    # Exports dungeon by printing dungeon cell coordinates
    def export_dungeon
      state.dungeon.each do |d| # on each element of dungeon collection
        puts "state.dungeon << [#{d.x}, #{d.y}]" # prints cell coordinates
      end
    end

    def distance_to_cell cell
      distance_to state.x, cell.x, state.y, cell.y # calls distance_to method
    end

    def distance_to from_x, x, from_y, y
      (from_x - x).abs + (from_y - y).abs # finds distance between two cells using coordinates
    end
  end

  $game = Game.new

  def tick args
    $game.args    = args
    $game.state   = args.state
    $game.inputs  = args.inputs
    $game.outputs = args.outputs
    $game.grid    = args.grid
    $game.tick
  end

```
