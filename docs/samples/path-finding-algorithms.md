### Breadth First Search - main.rb
```ruby
  # ./samples/13_path_finding_algorithms/01_breadth_first_search/app/main.rb
  # Contributors outside of DragonRuby who also hold Copyright:
  # - Sujay Vadlakonda: https://github.com/sujayvadlakonda

  # A visual demonstration of a breadth first search
  # Inspired by https://www.redblobgames.com/pathfinding/a-star/introduction.html

  # An animation that can respond to user input in real time

  # A breadth first search expands in all directions one step at a time
  # The frontier is a queue of cells to be expanded from
  # The visited hash allows quick lookups of cells that have been expanded from
  # The walls hash allows quick lookup of whether a cell is a wall

  # The breadth first search starts by adding the red star to the frontier array
  # and marking it as visited
  # Each step a cell is removed from the front of the frontier array (queue)
  # Unless the neighbor is a wall or visited, it is added to the frontier array
  # The neighbor is then marked as visited

  # The frontier is blue
  # Visited cells are light brown
  # Walls are camo green
  # Even when walls are visited, they will maintain their wall color

  # The star can be moved by clicking and dragging
  # Walls can be added and removed by clicking and dragging

  class BreadthFirstSearch
    attr_gtk

    def initialize(args)
      # Variables to edit the size and appearance of the grid
      # Freely customizable to user's liking
      args.state.grid.width     = 30
      args.state.grid.height    = 15
      args.state.grid.cell_size = 40

      # Stores which step of the animation is being rendered
      # When the user moves the star or messes with the walls,
      # the breadth first search is recalculated up to this step
      args.state.anim_steps = 0

      # At some step the animation will end,
      # and further steps won't change anything (the whole grid will be explored)
      # This step is roughly the grid's width * height
      # When anim_steps equals max_steps no more calculations will occur
      # and the slider will be at the end
      args.state.max_steps  = args.state.grid.width * args.state.grid.height

      # Whether the animation should play or not
      # If true, every tick moves anim_steps forward one
      # Pressing the stepwise animation buttons will pause the animation
      args.state.play       = true

      # The location of the star and walls of the grid
      # They can be modified to have a different initial grid
      # Walls are stored in a hash for quick look up when doing the search
      args.state.star       = [0, 0]
      args.state.walls      = {
        [3, 3] => true,
        [3, 4] => true,
        [3, 5] => true,
        [3, 6] => true,
        [3, 7] => true,
        [3, 8] => true,
        [3, 9] => true,
        [3, 10] => true,
        [3, 11] => true,
        [4, 3] => true,
        [4, 4] => true,
        [4, 5] => true,
        [4, 6] => true,
        [4, 7] => true,
        [4, 8] => true,
        [4, 9] => true,
        [4, 10] => true,
        [4, 11] => true,

        [13, 0] => true,
        [13, 1] => true,
        [13, 2] => true,
        [13, 3] => true,
        [13, 4] => true,
        [13, 5] => true,
        [13, 6] => true,
        [13, 7] => true,
        [13, 8] => true,
        [13, 9] => true,
        [13, 10] => true,
        [14, 0] => true,
        [14, 1] => true,
        [14, 2] => true,
        [14, 3] => true,
        [14, 4] => true,
        [14, 5] => true,
        [14, 6] => true,
        [14, 7] => true,
        [14, 8] => true,
        [14, 9] => true,
        [14, 10] => true,

        [21, 8] => true,
        [21, 9] => true,
        [21, 10] => true,
        [21, 11] => true,
        [21, 12] => true,
        [21, 13] => true,
        [21, 14] => true,
        [22, 8] => true,
        [22, 9] => true,
        [22, 10] => true,
        [22, 11] => true,
        [22, 12] => true,
        [22, 13] => true,
        [22, 14] => true,
        [23, 8] => true,
        [23, 9] => true,
        [24, 8] => true,
        [24, 9] => true,
        [25, 8] => true,
        [25, 9] => true,
      }

      # Variables that are used by the breadth first search
      # Storing cells that the search has visited, prevents unnecessary steps
      # Expanding the frontier of the search in order makes the search expand
      # from the center outward
      args.state.visited    = {}
      args.state.frontier   = []


      # What the user is currently editing on the grid
      # Possible values are: :none, :slider, :star, :remove_wall, :add_wall

      # We store this value, because we want to remember the value even when
      # the user's cursor is no longer over what they're interacting with, but
      # they are still clicking down on the mouse.
      args.state.click_and_drag = :none

      # Store the rects of the buttons that control the animation
      # They are here for user customization
      # Editing these might require recentering the text inside them
      # Those values can be found in the render_button methods

      args.state.buttons.left   = { x: 450, y: 600, w: 50,  h: 50 }
      args.state.buttons.center = { x: 500, y: 600, w: 200, h: 50 }
      args.state.buttons.right  = { x: 700, y: 600, w: 50,  h: 50 }

      # The variables below are related to the slider
      # They allow the user to customize them
      # They also give a central location for the render and input methods to get
      # information from
      # x & y are the coordinates of the leftmost part of the slider line
      args.state.slider.x = 400
      args.state.slider.y = 675
      # This is the width of the line
      args.state.slider.w = 360
      # This is the offset for the circle
      # Allows the center of the circle to be on the line,
      # as opposed to the upper right corner
      args.state.slider.offset = 20
      # This is the spacing between each of the notches on the slider
      # Notches are places where the circle can rest on the slider line
      # There needs to be a notch for each step before the maximum number of steps
      args.state.slider.spacing = args.state.slider.w.to_f / args.state.max_steps.to_f
    end

    # This method is called every frame/tick
    # Every tick, the current state of the search is rendered on the screen,
    # User input is processed, and
    # The next step in the search is calculated
    def tick
      render
      input
      # If animation is playing, and max steps have not been reached
      # Move the search a step forward
      if state.play && state.anim_steps < state.max_steps
        # Variable that tells the program what step to recalculate up to
        state.anim_steps += 1
        calc
      end
    end

    # Draws everything onto the screen
    def render
      render_buttons
      render_slider

      render_background
      render_visited
      render_frontier
      render_walls
      render_star
    end

    # The methods below subdivide the task of drawing everything to the screen

    # Draws the buttons that control the animation step and state
    def render_buttons
      render_left_button
      render_center_button
      render_right_button
    end

    # Draws the button which steps the search backward
    # Shows the user where to click to move the search backward
    def render_left_button
      # Draws the gray button, and a black border
      # The border separates the buttons visually
      outputs.solids  << buttons.left.merge(gray)
      outputs.borders << buttons.left

      # Renders an explanatory label in the center of the button
      # Explains to the user what the button does
      # If the button size is changed, the label might need to be edited as well
      # to keep the label in the center of the button
      label_x = buttons.left[:x] + 20
      label_y = buttons.left[:y] + 35
      outputs.labels << { x: label_x, y: label_y, text: '<' }
    end

    def render_center_button
      # Draws the gray button, and a black border
      # The border separates the buttons visually
      outputs.solids  << buttons.center.merge(gray)
      outputs.borders << buttons.center

      # Renders an explanatory label in the center of the button
      # Explains to the user what the button does
      # If the button size is changed, the label might need to be edited as well
      # to keep the label in the center of the button
      label_x = buttons.center[:x] + 37
      label_y = buttons.center[:y] + 35
      label_text = state.play ? "Pause Animation" : "Play Animation"
      outputs.labels << { x: label_x, y: label_y, text: label_text }
    end

    def render_right_button
      # Draws the gray button, and a black border
      # The border separates the buttons visually
      outputs.solids  << buttons.right.merge(gray)
      outputs.borders << buttons.right

      # Renders an explanatory label in the center of the button
      # Explains to the user what the button does
      label_x = buttons.right[:x] + 20
      label_y = buttons.right[:y] + 35
      outputs.labels << { x: label_x, y: label_y, text: ">" }
    end

    # Draws the slider so the user can move it and see the progress of the search
    def render_slider
      # Using a solid instead of a line, hides the line under the circle of the slider
      # Draws the line
      outputs.solids << {
        x: slider.x,
        y: slider.y,
        w: slider.w,
        h: 2
      }
      # The circle needs to be offset so that the center of the circle
      # overlaps the line instead of the upper right corner of the circle
      # The circle's x value is also moved based on the current seach step
      circle_x = (slider.x - slider.offset) + (state.anim_steps * slider.spacing)
      circle_y = (slider.y - slider.offset)
      outputs.sprites << {
        x: circle_x,
        y: circle_y,
        w: 37,
        h: 37,
        path: 'circle-white.png'
      }
    end

    # Draws what the grid looks like with nothing on it
    def render_background
      render_unvisited
      render_grid_lines
    end

    # Draws a rectangle the size of the entire grid to represent unvisited cells
    def render_unvisited
      rect = { x: 0, y: 0, w: grid.width, h: grid.height }
      rect = rect.transform_values { |v| v * grid.cell_size }
      outputs.solids << rect.merge(unvisited_color)
    end

    # Draws grid lines to show the division of the grid into cells
    def render_grid_lines
      outputs.lines << (0..grid.width).map { |x| vertical_line(x) }
      outputs.lines << (0..grid.height).map { |y| horizontal_line(y) }
    end

    # Easy way to draw vertical lines given an index
    def vertical_line x
      line = { x: x, y: 0, w: 0, h: grid.height }
      line.transform_values { |v| v * grid.cell_size }
    end

    # Easy way to draw horizontal lines given an index
    def horizontal_line y
      line = { x: 0, y: y, w: grid.width, h: 0 }
      line.transform_values { |v| v * grid.cell_size }
    end

    # Draws the area that is going to be searched from
    # The frontier is the most outward parts of the search
    def render_frontier
      outputs.solids << state.frontier.map do |cell|
        render_cell cell, frontier_color
      end
    end

    # Draws the walls
    def render_walls
      outputs.solids << state.walls.map do |wall|
        render_cell wall, wall_color
      end
    end

    # Renders cells that have been searched in the appropriate color
    def render_visited
      outputs.solids << state.visited.map do |cell|
        render_cell cell, visited_color
      end
    end

    # Renders the star
    def render_star
      outputs.sprites << render_cell(state.star, { path: 'star.png' })
    end

    def render_cell cell, attrs
      {
        x: cell.x * grid.cell_size,
        y: cell.y * grid.cell_size,
        w: grid.cell_size,
        h: grid.cell_size
      }.merge attrs
    end

    # In code, the cells are represented as 1x1 rectangles
    # When drawn, the cells are larger than 1x1 rectangles
    # This method is used to scale up cells, and lines
    # Objects are scaled up according to the grid.cell_size variable
    # This allows for easy customization of the visual scale of the grid
    def scale_up(cell)
      # Prevents the original value of cell from being edited
      cell = cell.clone

      # If cell is just an x and y coordinate
      if cell.size == 2
        # Add a width and height of 1
        cell << 1
        cell << 1
      end

      # Scale all the values up
      cell.map! { |value| value * grid.cell_size }

      # Returns the scaled up cell
      cell
    end

    # This method processes user input every tick
    # This method allows the user to use the buttons, slider, and edit the grid
    # There are 2 types of input:
    #   Button Input
    #   Click and Drag Input
    #
    #   Button Input is used for the backward step and forward step buttons
    #   Input is detected by mouse up within the bounds of the rect
    #
    #   Click and Drag Input is used for moving the star, adding walls,
    #   removing walls, and the slider
    #
    #   When the mouse is down on the star, the click_and_drag variable is set to :star
    #   While click_and_drag equals :star, the cursor's position is used to calculate the
    #   appropriate drag behavior
    #
    #   When the mouse goes up click_and_drag is set to :none
    #
    #   A variable has to be used because the star has to continue being edited even
    #   when the cursor is no longer over the star
    #
    #   Similar things occur for the other Click and Drag inputs
    def input
      # Checks whether any of the buttons are being clicked
      input_buttons

      # The detection and processing of click and drag inputs are separate
      # The program has to remember that the user is dragging an object
      # even when the mouse is no longer over that object
      detect_click_and_drag
      process_click_and_drag
    end

    # Detects and Process input for each button
    def input_buttons
      input_left_button
      input_center_button
      input_next_step_button
    end

    # Checks if the previous step button is clicked
    # If it is, it pauses the animation and moves the search one step backward
    def input_left_button
      if left_button_clicked?
        state.play = false
        state.anim_steps -= 1
        recalculate
      end
    end

    # Controls the play/pause button
    # Inverses whether the animation is playing or not when clicked
    def input_center_button
      if center_button_clicked? or inputs.keyboard.key_down.space
        state.play = !state.play
      end
    end

    # Checks if the next step button is clicked
    # If it is, it pauses the animation and moves the search one step forward
    def input_next_step_button
      if right_button_clicked?
        state.play = false
        state.anim_steps += 1
        calc
      end
    end

    # Determines what the user is editing and stores the value
    # Storing the value allows the user to continue the same edit as long as the
    # mouse left click is held
    def detect_click_and_drag
      if inputs.mouse.up
        state.click_and_drag = :none
      elsif star_clicked?
        state.click_and_drag = :star
      elsif wall_clicked?
        state.click_and_drag = :remove_wall
      elsif grid_clicked?
        state.click_and_drag = :add_wall
      elsif slider_clicked?
        state.click_and_drag = :slider
      end
    end

    # Processes click and drag based on what the user is currently dragging
    def process_click_and_drag
      if state.click_and_drag == :star
        input_star
      elsif state.click_and_drag == :remove_wall
        input_remove_wall
      elsif state.click_and_drag == :add_wall
        input_add_wall
      elsif state.click_and_drag == :slider
        input_slider
      end
    end

    # Moves the star to the grid closest to the mouse
    # Only recalculates the search if the star changes position
    # Called whenever the user is editing the star (puts mouse down on star)
    def input_star
      old_star = state.star.clone
      state.star = cell_closest_to_mouse
      unless old_star == state.star
        recalculate
      end
    end

    # Removes walls that are under the cursor
    def input_remove_wall
      # The mouse needs to be inside the grid, because we only want to remove walls
      # the cursor is directly over
      # Recalculations should only occur when a wall is actually deleted
      if mouse_inside_grid?
        if state.walls.key?(cell_closest_to_mouse)
          state.walls.delete(cell_closest_to_mouse)
          recalculate
        end
      end
    end

    # Adds walls at cells under the cursor
    def input_add_wall
      if mouse_inside_grid?
        unless state.walls.key?(cell_closest_to_mouse)
          state.walls[cell_closest_to_mouse] = true
          recalculate
        end
      end
    end

    # This method is called when the user is editing the slider
    # It pauses the animation and moves the white circle to the closest integer point
    # on the slider
    # Changes the step of the search to be animated
    def input_slider
      state.play = false
      mouse_x = inputs.mouse.point.x

      # Bounds the mouse_x to the closest x value on the slider line
      mouse_x = slider.x if mouse_x < slider.x
      mouse_x = slider.x + slider.w if mouse_x > slider.x + slider.w

      # Sets the current search step to the one represented by the mouse x value
      # The slider's circle moves due to the render_slider method using anim_steps
      state.anim_steps = ((mouse_x - slider.x) / slider.spacing).to_i

      recalculate
    end

    # Whenever the user edits the grid,
    # The search has to be recalculated upto the current step
    # with the current grid as the initial state of the grid
    def recalculate
      # Resets the search
      state.frontier = []
      state.visited = {}

      # Moves the animation forward one step at a time
      state.anim_steps.times { calc }
    end


    # This method moves the search forward one step
    # When the animation is playing it is called every tick
    # And called whenever the current step of the animation needs to be recalculated

    # Moves the search forward one step
    # Parameter called_from_tick is true if it is called from the tick method
    # It is false when the search is being recalculated after user editing the grid
    def calc

      # The setup to the search
      # Runs once when the there is no frontier or visited cells
      if state.frontier.empty? && state.visited.empty?
        state.frontier << state.star
        state.visited[state.star] = true
      end

      # A step in the search
      unless state.frontier.empty?
        # Takes the next frontier cell
        new_frontier = state.frontier.shift
        # For each of its neighbors
        adjacent_neighbors(new_frontier).each do |neighbor|
          # That have not been visited and are not walls
          unless state.visited.key?(neighbor) || state.walls.key?(neighbor)
            # Add them to the frontier and mark them as visited
            state.frontier << neighbor
            state.visited[neighbor] = true
          end
        end
      end
    end


    # Returns a list of adjacent cells
    # Used to determine what the next cells to be added to the frontier are
    def adjacent_neighbors(cell)
      neighbors = []

      neighbors << [cell.x, cell.y + 1] unless cell.y == grid.height - 1
      neighbors << [cell.x + 1, cell.y] unless cell.x == grid.width - 1
      neighbors << [cell.x, cell.y - 1] unless cell.y == 0
      neighbors << [cell.x - 1, cell.y] unless cell.x == 0

      neighbors
    end

    # When the user grabs the star and puts their cursor to the far right
    # and moves up and down, the star is supposed to move along the grid as well
    # Finding the cell closest to the mouse helps with this
    def cell_closest_to_mouse
      # Closest cell to the mouse
      x = (inputs.mouse.point.x / grid.cell_size).to_i
      y = (inputs.mouse.point.y / grid.cell_size).to_i
      # Bound x and y to the grid
      x = grid.width - 1 if x > grid.width - 1
      y = grid.height - 1 if y > grid.height - 1
      # Return closest cell
      [x, y]
    end

    # These methods detect when the buttons are clicked
    def left_button_clicked?
      inputs.mouse.up && inputs.mouse.point.inside_rect?(buttons.left)
    end

    def center_button_clicked?
      inputs.mouse.up && inputs.mouse.point.inside_rect?(buttons.center)
    end

    def right_button_clicked?
      inputs.mouse.up && inputs.mouse.point.inside_rect?(buttons.right)
    end

    # Signal that the user is going to be moving the slider
    # Is the mouse down on the circle of the slider?
    def slider_clicked?
      circle_x = (slider.x - slider.offset) + (state.anim_steps * slider.spacing)
      circle_y = (slider.y - slider.offset)
      circle_rect = [circle_x, circle_y, 37, 37]
      inputs.mouse.down && inputs.mouse.point.inside_rect?(circle_rect)
    end

    # Signal that the user is going to be moving the star
    def star_clicked?
      inputs.mouse.down && inputs.mouse.point.inside_rect?(scale_up(state.star))
    end

    # Signal that the user is going to be removing walls
    def wall_clicked?
      inputs.mouse.down && mouse_inside_a_wall?
    end

    # Signal that the user is going to be adding walls
    def grid_clicked?
      inputs.mouse.down && mouse_inside_grid?
    end

    # Returns whether the mouse is inside of a wall
    # Part of the condition that checks whether the user is removing a wall
    def mouse_inside_a_wall?
      state.walls.each_key do | wall |
        return true if inputs.mouse.point.inside_rect?(scale_up([wall.x, wall.y]))
      end

      false
    end

    # Returns whether the mouse is inside of a grid
    # Part of the condition that checks whether the user is adding a wall
    def mouse_inside_grid?
      inputs.mouse.point.inside_rect?(scale_up([0, 0, grid.width, grid.height]))
    end

    # Light brown
    def unvisited_color
      { r: 221, g: 212, b: 213 }
    end

    # Dark Brown
    def visited_color
      { r: 204, g: 191, b: 179 }
    end

    # Blue
    def frontier_color
      { r: 103, g: 136, b: 204 }
    end

    # Camo Green
    def wall_color
      { r: 134, g: 134, b: 120 }
    end

    # Button Background
    def gray
      { r: 190, g: 190, b: 190 }
    end

    # These methods make the code more concise
    def grid
      state.grid
    end

    def buttons
      state.buttons
    end

    def slider
      state.slider
    end
  end

  # Method that is called by DragonRuby periodically
  # Used for updating animations and calculations
  def tick args

    # Pressing r will reset the application
    if args.inputs.keyboard.key_down.r
      args.gtk.reset
      reset
      return
    end

    # Every tick, new args are passed, and the Breadth First Search tick is called
    $breadth_first_search ||= BreadthFirstSearch.new(args)
    $breadth_first_search.args = args
    $breadth_first_search.tick
  end


  def reset
    $breadth_first_search = nil
  end

```

### Detailed Breadth First Search - main.rb
```ruby
  # ./samples/13_path_finding_algorithms/02_detailed_breadth_first_search/app/main.rb
  # Contributors outside of DragonRuby who also hold Copyright:
  # - Sujay Vadlakonda: https://github.com/sujayvadlakonda

  # A visual demonstration of a breadth first search
  # Inspired by https://www.redblobgames.com/pathfinding/a-star/introduction.html

  # An animation that can respond to user input in real time

  # A breadth first search expands in all directions one step at a time
  # The frontier is a queue of cells to be expanded from
  # The visited hash allows quick lookups of cells that have been expanded from
  # The walls hash allows quick lookup of whether a cell is a wall

  # The breadth first search starts by adding the red star to the frontier array
  # and marking it as visited
  # Each step a cell is removed from the front of the frontier array (queue)
  # Unless the neighbor is a wall or visited, it is added to the frontier array
  # The neighbor is then marked as visited

  # The frontier is blue
  # Visited cells are light brown
  # Walls are camo green
  # Even when walls are visited, they will maintain their wall color

  # This search numbers the order in which new cells are explored
  # The next cell from where the search will continue is highlighted yellow
  # And the cells that will be considered for expansion are in semi-transparent green

  # The star can be moved by clicking and dragging
  # Walls can be added and removed by clicking and dragging

  class DetailedBreadthFirstSearch
    attr_gtk

    def initialize(args)
      # Variables to edit the size and appearance of the grid
      # Freely customizable to user's liking
      args.state.grid.width     = 9
      args.state.grid.height    = 4
      args.state.grid.cell_size = 90

      # Stores which step of the animation is being rendered
      # When the user moves the star or messes with the walls,
      # the breadth first search is recalculated up to this step
      args.state.anim_steps = 0

      # At some step the animation will end,
      # and further steps won't change anything (the whole grid will be explored)
      # This step is roughly the grid's width * height
      # When anim_steps equals max_steps no more calculations will occur
      # and the slider will be at the end
      args.state.max_steps  = args.state.grid.width * args.state.grid.height

      # The location of the star and walls of the grid
      # They can be modified to have a different initial grid
      # Walls are stored in a hash for quick look up when doing the search
      args.state.star       = [3, 2]
      args.state.walls      = {}

      # Variables that are used by the breadth first search
      # Storing cells that the search has visited, prevents unnecessary steps
      # Expanding the frontier of the search in order makes the search expand
      # from the center outward
      args.state.visited    = {}
      args.state.frontier   = []
      args.state.cell_numbers = []



      # What the user is currently editing on the grid
      # Possible values are: :none, :slider, :star, :remove_wall, :add_wall

      # We store this value, because we want to remember the value even when
      # the user's cursor is no longer over what they're interacting with, but
      # they are still clicking down on the mouse.
      args.state.click_and_drag = :none

      # The x, y, w, h values for the buttons
      # Allow easy movement of the buttons location
      # A centralized location to get values to detect input and draw the buttons
      # Editing these values might mean needing to edit the label offsets
      # which can be found in the appropriate render button methods
      args.state.buttons.left  = [450, 600, 160, 50]
      args.state.buttons.right = [610, 600, 160, 50]

      # The variables below are related to the slider
      # They allow the user to customize them
      # They also give a central location for the render and input methods to get
      # information from
      # x & y are the coordinates of the leftmost part of the slider line
      args.state.slider.x = 400
      args.state.slider.y = 675
      # This is the width of the line
      args.state.slider.w = 360
      # This is the offset for the circle
      # Allows the center of the circle to be on the line,
      # as opposed to the upper right corner
      args.state.slider.offset = 20
      # This is the spacing between each of the notches on the slider
      # Notches are places where the circle can rest on the slider line
      # There needs to be a notch for each step before the maximum number of steps
      args.state.slider.spacing = args.state.slider.w.to_f / args.state.max_steps.to_f
    end

    # This method is called every frame/tick
    # Every tick, the current state of the search is rendered on the screen,
    # User input is processed, and
    def tick
      render
      input
    end

    # This method is called from tick and renders everything every tick
    def render
      render_buttons
      render_slider

      render_background
      render_visited
      render_frontier
      render_walls
      render_star

      render_highlights
      render_cell_numbers
    end

    # The methods below subdivide the task of drawing everything to the screen

    # Draws the buttons that move the search backward or forward
    # These buttons are rendered so the user knows where to click to move the search
    def render_buttons
      render_left_button
      render_right_button
    end

    # Renders the button which steps the search backward
    # Shows the user where to click to move the search backward
    def render_left_button
      # Draws the gray button, and a black border
      # The border separates the buttons visually
      outputs.solids  << [buttons.left, gray]
      outputs.borders << [buttons.left]

      # Renders an explanatory label in the center of the button
      # Explains to the user what the button does
      label_x = buttons.left.x + 05
      label_y = buttons.left.y + 35
      outputs.labels  << [label_x, label_y, "< Step backward"]
    end

    # Renders the button which steps the search forward
    # Shows the user where to click to move the search forward
    def render_right_button
      # Draws the gray button, and a black border
      # The border separates the buttons visually
      outputs.solids  << [buttons.right, gray]
      outputs.borders << [buttons.right]

      # Renders an explanatory label in the center of the button
      # Explains to the user what the button does
      label_x = buttons.right.x + 10
      label_y = buttons.right.y + 35
      outputs.labels  << [label_x, label_y, "Step forward >"]
    end

    # Draws the slider so the user can move it and see the progress of the search
    def render_slider
      # Using primitives hides the line under the white circle of the slider
      # Draws the line
      outputs.primitives << [slider.x, slider.y, slider.x + slider.w, slider.y].line
      # The circle needs to be offset so that the center of the circle
      # overlaps the line instead of the upper right corner of the circle
      # The circle's x value is also moved based on the current seach step
      circle_x = (slider.x - slider.offset) + (state.anim_steps * slider.spacing)
      circle_y = (slider.y - slider.offset)
      circle_rect = [circle_x, circle_y, 37, 37]
      outputs.primitives << [circle_rect, 'circle-white.png'].sprite
    end

    # Draws what the grid looks like with nothing on it
    # Which is a bunch of unvisited cells
    # Drawn first so other things can draw on top of it
    def render_background
      render_unvisited

      # The grid lines make the cells appear separate
      render_grid_lines
    end

    # Draws a rectangle the size of the entire grid to represent unvisited cells
    # Unvisited cells are the default cell
    def render_unvisited
      background = [0, 0, grid.width, grid.height]
      outputs.solids << scale_up(background).merge(unvisited_color)
    end

    # Draws grid lines to show the division of the grid into cells
    def render_grid_lines
      outputs.lines << (0..grid.width).map do |x|
        scale_up(vertical_line(x)).merge(grid_line_color)
      end
      outputs.lines << (0..grid.height).map do |y|
        scale_up(horizontal_line(y)).merge(grid_line_color)
      end
    end

    # Easy way to get a vertical line given an index
    def vertical_line column
      [column, 0, 0, grid.height]
    end

    # Easy way to get a horizontal line given an index
    def horizontal_line row
      [0, row, grid.width, 0]
    end

    # Draws the area that is going to be searched from
    # The frontier is the most outward parts of the search
    def render_frontier
      state.frontier.each do |cell|
        outputs.solids << scale_up(cell).merge(frontier_color)
      end
    end

    # Draws the walls
    def render_walls
      state.walls.each_key do |wall|
        outputs.solids << scale_up(wall).merge(wall_color)
      end
    end

    # Renders cells that have been searched in the appropriate color
    def render_visited
      state.visited.each_key do |cell|
        outputs.solids << scale_up(cell).merge(visited_color)
      end
    end

    # Renders the star
    def render_star
      outputs.sprites << scale_up(state.star).merge({ path: 'star.png' })
    end

    # Cells have a number rendered in them based on when they were explored
    # This is based off of their index in the cell_numbers array
    # Cells are added to this array the same time they are added to the frontier array
    def render_cell_numbers
      state.cell_numbers.each_with_index do |cell, index|
        # Math that approx centers the number in the cell
        label_x = (cell.x * grid.cell_size) + grid.cell_size / 2 - 5
        label_y = (cell.y * grid.cell_size) + (grid.cell_size / 2) + 5

        outputs.labels << [label_x, label_y, (index + 1).to_s]
      end
    end

    # The next frontier to be expanded is highlighted yellow
    # Its adjacent non-wall neighbors have their border highlighted green
    # This is to show the user how the search expands
    def render_highlights
      return if state.frontier.empty?

      # Highlight the next frontier to be expanded yellow
      next_frontier = state.frontier[0]
      outputs.solids << scale_up(next_frontier).merge(highlighter_yellow)

      # Neighbors have a semi-transparent green layer over them
      # Unless the neighbor is a wall
      adjacent_neighbors(next_frontier).each do |neighbor|
        unless state.walls.key?(neighbor)
          outputs.solids << scale_up(neighbor).merge(highlighter_green)
        end
      end
    end


    # Cell Size is used when rendering to allow the grid to be scaled up or down
    # Cells in the frontier array and visited hash and walls hash are stored as x & y
    # Scaling up cells and lines when rendering allows omitting of width and height
    def scale_up(cell)
      if cell.size == 2
        return {
          x: cell.x * grid.cell_size,
          y: cell.y * grid.cell_size,
          w: grid.cell_size,
          h: grid.cell_size
        }
      else
        return {
          x: cell.x * grid.cell_size,
          y: cell.y * grid.cell_size,
          w: cell.w * grid.cell_size,
          h: cell.h * grid.cell_size
        }
      end
    end


    # This method processes user input every tick
    # This method allows the user to use the buttons, slider, and edit the grid
    # There are 2 types of input:
    #   Button Input
    #   Click and Drag Input
    #
    #   Button Input is used for the backward step and forward step buttons
    #   Input is detected by mouse up within the bounds of the rect
    #
    #   Click and Drag Input is used for moving the star, adding walls,
    #   removing walls, and the slider
    #
    #   When the mouse is down on the star, the click_and_drag variable is set to :star
    #   While click_and_drag equals :star, the cursor's position is used to calculate the
    #   appropriate drag behavior
    #
    #   When the mouse goes up click_and_drag is set to :none
    #
    #   A variable has to be used because the star has to continue being edited even
    #   when the cursor is no longer over the star
    #
    #   Similar things occur for the other Click and Drag inputs
    def input
      # Processes inputs for the buttons
      input_buttons

      # Detects which if any click and drag input is occurring
      detect_click_and_drag

      # Does the appropriate click and drag input based on the click_and_drag variable
      process_click_and_drag
    end

    # Detects and Process input for each button
    def input_buttons
      input_left_button
      input_right_button
    end

    # Checks if the previous step button is clicked
    # If it is, it pauses the animation and moves the search one step backward
    def input_left_button
      if left_button_clicked?
        unless state.anim_steps == 0
          state.anim_steps -= 1
          recalculate
        end
      end
    end

    # Checks if the next step button is clicked
    # If it is, it pauses the animation and moves the search one step forward
    def input_right_button
      if right_button_clicked?
        unless state.anim_steps == state.max_steps
          state.anim_steps += 1
          # Although normally recalculate would be called here
          # because the right button only moves the search forward
          # We can just do that
          calc
        end
      end
    end

    # Whenever the user edits the grid,
    # The search has to be recalculated upto the current step

    def recalculate
      # Resets the search
      state.frontier = []
      state.visited = {}
      state.cell_numbers = []

      # Moves the animation forward one step at a time
      state.anim_steps.times { calc }
    end


    # Determines what the user is clicking and planning on dragging
    # Click and drag input is initiated by a click on the appropriate item
    # and ended by mouse up
    # Storing the value allows the user to continue the same edit as long as the
    # mouse left click is held
    def detect_click_and_drag
      if inputs.mouse.up
        state.click_and_drag = :none
      elsif star_clicked?
        state.click_and_drag = :star
      elsif wall_clicked?
        state.click_and_drag = :remove_wall
      elsif grid_clicked?
        state.click_and_drag = :add_wall
      elsif slider_clicked?
        state.click_and_drag = :slider
      end
    end

    # Processes input based on what the user is currently dragging
    def process_click_and_drag
      if state.click_and_drag == :slider
        input_slider
      elsif state.click_and_drag == :star
        input_star
      elsif state.click_and_drag == :remove_wall
        input_remove_wall
      elsif state.click_and_drag == :add_wall
        input_add_wall
      end
    end

    # This method is called when the user is dragging the slider
    # It moves the current animation step to the point represented by the slider
    def input_slider
      mouse_x = inputs.mouse.point.x

      # Bounds the mouse_x to the closest x value on the slider line
      mouse_x = slider.x if mouse_x < slider.x
      mouse_x = slider.x + slider.w if mouse_x > slider.x + slider.w

      # Sets the current search step to the one represented by the mouse x value
      # The slider's circle moves due to the render_slider method using anim_steps
      state.anim_steps = ((mouse_x - slider.x) / slider.spacing).to_i

      recalculate
    end

    # Moves the star to the grid closest to the mouse
    # Only recalculates the search if the star changes position
    # Called whenever the user is dragging the star
    def input_star
      old_star = state.star.clone
      state.star = cell_closest_to_mouse
      unless old_star == state.star
        recalculate
      end
    end

    # Removes walls that are under the cursor
    def input_remove_wall
      # The mouse needs to be inside the grid, because we only want to remove walls
      # the cursor is directly over
      # Recalculations should only occur when a wall is actually deleted
      if mouse_inside_grid?
        if state.walls.key?(cell_closest_to_mouse)
          state.walls.delete(cell_closest_to_mouse)
          recalculate
        end
      end
    end

    # Adds walls at cells under the cursor
    def input_add_wall
      # Adds a wall to the hash
      # We can use the grid closest to mouse, because the cursor is inside the grid
      if mouse_inside_grid?
        unless state.walls.key?(cell_closest_to_mouse)
          state.walls[cell_closest_to_mouse] = true
          recalculate
        end
      end
    end

    # This method moves the search forward one step
    # When the animation is playing it is called every tick
    # And called whenever the current step of the animation needs to be recalculated

    # Moves the search forward one step
    # Parameter called_from_tick is true if it is called from the tick method
    # It is false when the search is being recalculated after user editing the grid
    def calc
      # The setup to the search
      # Runs once when the there is no frontier or visited cells
      if state.frontier.empty? && state.visited.empty?
        state.frontier << state.star
        state.visited[state.star] = true
      end

      # A step in the search
      unless state.frontier.empty?
        # Takes the next frontier cell
        new_frontier = state.frontier.shift
        # For each of its neighbors
        adjacent_neighbors(new_frontier).each do |neighbor|
          # That have not been visited and are not walls
          unless state.visited.key?(neighbor) || state.walls.key?(neighbor)
            # Add them to the frontier and mark them as visited
            state.frontier << neighbor
            state.visited[neighbor] = true

            # Also assign them a frontier number
            state.cell_numbers << neighbor
          end
        end
      end
    end


    # Returns a list of adjacent cells
    # Used to determine what the next cells to be added to the frontier are
    def adjacent_neighbors cell
      neighbors = []

      neighbors << [cell.x, cell.y + 1] unless cell.y == grid.height - 1
      neighbors << [cell.x + 1, cell.y] unless cell.x == grid.width - 1
      neighbors << [cell.x, cell.y - 1] unless cell.y == 0
      neighbors << [cell.x - 1, cell.y] unless cell.x == 0

      neighbors
    end

    # When the user grabs the star and puts their cursor to the far right
    # and moves up and down, the star is supposed to move along the grid as well
    # Finding the grid closest to the mouse helps with this
    def cell_closest_to_mouse
      x = (inputs.mouse.point.x / grid.cell_size).to_i
      y = (inputs.mouse.point.y / grid.cell_size).to_i
      x = grid.width - 1 if x > grid.width - 1
      y = grid.height - 1 if y > grid.height - 1
      [x, y]
    end


    # These methods detect when the buttons are clicked
    def left_button_clicked?
      (inputs.mouse.up && inputs.mouse.point.inside_rect?(buttons.left)) || inputs.keyboard.key_up.left
    end

    def right_button_clicked?
      (inputs.mouse.up && inputs.mouse.point.inside_rect?(buttons.right)) || inputs.keyboard.key_up.right
    end

    # Signal that the user is going to be moving the slider
    def slider_clicked?
      circle_x = (slider.x - slider.offset) + (state.anim_steps * slider.spacing)
      circle_y = (slider.y - slider.offset)
      circle_rect = [circle_x, circle_y, 37, 37]
      inputs.mouse.down && inputs.mouse.point.inside_rect?(circle_rect)
    end

    # Signal that the user is going to be moving the star
    def star_clicked?
      inputs.mouse.down && inputs.mouse.point.inside_rect?(scale_up(state.star))
    end

    # Signal that the user is going to be removing walls
    def wall_clicked?
      inputs.mouse.down && mouse_inside_a_wall?
    end

    # Signal that the user is going to be adding walls
    def grid_clicked?
      inputs.mouse.down && mouse_inside_grid?
    end

    # Returns whether the mouse is inside of a wall
    # Part of the condition that checks whether the user is removing a wall
    def mouse_inside_a_wall?
      state.walls.each_key do | wall |
        return true if inputs.mouse.point.inside_rect?(scale_up(wall))
      end

      false
    end

    # Returns whether the mouse is inside of a grid
    # Part of the condition that checks whether the user is adding a wall
    def mouse_inside_grid?
      inputs.mouse.point.inside_rect?(scale_up([0, 0, grid.width, grid.height]))
    end

    # These methods provide handy aliases to colors

    # Light brown
    def unvisited_color
      { r: 221, g: 212, b: 213 }
    end

    # Black
    def grid_line_color
      { r: 255, g: 255, b: 255 }
    end

    # Dark Brown
    def visited_color
      { r: 204, g: 191, b: 179 }
    end

    # Blue
    def frontier_color
      { r: 103, g: 136, b: 204 }
    end

    # Camo Green
    def wall_color
      { r: 134, g: 134, b: 120 }
    end

    # Next frontier to be expanded
    def highlighter_yellow
      { r: 214, g: 231, b: 125 }
    end

    # The neighbors of the next frontier to be expanded
    def highlighter_green
      { r: 65, g: 191, b: 127, a: 70 }
    end

    # Button background
    def gray
      [190, 190, 190]
    end

    # These methods make the code more concise
    def grid
      state.grid
    end

    def buttons
      state.buttons
    end

    def slider
      state.slider
    end
  end


  def tick args
    # Pressing r resets the program
    if args.inputs.keyboard.key_down.r
      args.gtk.reset
      reset
      return
    end

    $detailed_breadth_first_search ||= DetailedBreadthFirstSearch.new(args)
    $detailed_breadth_first_search.args = args
    $detailed_breadth_first_search.tick
  end


  def reset
    $detailed_breadth_first_search = nil
  end

```

### Breadcrumbs - main.rb
```ruby
  # ./samples/13_path_finding_algorithms/03_breadcrumbs/app/main.rb
  # Contributors outside of DragonRuby who also hold Copyright:
  # - Sujay Vadlakonda: https://github.com/sujayvadlakonda

  # This program is inspired by https://www.redblobgames.com/pathfinding/a-star/introduction.html

  class Breadcrumbs
    attr_gtk

    # This method is called every frame/tick
    # Every tick, the current state of the search is rendered on the screen,
    # User input is processed, and
    # The next step in the search is calculated
    def tick
      defaults
      # If the grid has not been searched
      if search.came_from.empty?
        calc
        # Calc Path
      end
      render
      input
    end

    def defaults
      # Variables to edit the size and appearance of the grid
      # Freely customizable to user's liking
      grid.width     ||= 30
      grid.height    ||= 15
      grid.cell_size ||= 40
      grid.rect      ||= [0, 0, grid.width, grid.height]

      # The location of the star and walls of the grid
      # They can be modified to have a different initial grid
      # Walls are stored in a hash for quick look up when doing the search
      grid.star   ||= [2, 8]
      grid.target ||= [10, 5]
      grid.walls  ||= {
        [3, 3] => true,
        [3, 4] => true,
        [3, 5] => true,
        [3, 6] => true,
        [3, 7] => true,
        [3, 8] => true,
        [3, 9] => true,
        [3, 10] => true,
        [3, 11] => true,
        [4, 3] => true,
        [4, 4] => true,
        [4, 5] => true,
        [4, 6] => true,
        [4, 7] => true,
        [4, 8] => true,
        [4, 9] => true,
        [4, 10] => true,
        [4, 11] => true,
        [13, 0] => true,
        [13, 1] => true,
        [13, 2] => true,
        [13, 3] => true,
        [13, 4] => true,
        [13, 5] => true,
        [13, 6] => true,
        [13, 7] => true,
        [13, 8] => true,
        [13, 9] => true,
        [13, 10] => true,
        [14, 0] => true,
        [14, 1] => true,
        [14, 2] => true,
        [14, 3] => true,
        [14, 4] => true,
        [14, 5] => true,
        [14, 6] => true,
        [14, 7] => true,
        [14, 8] => true,
        [14, 9] => true,
        [14, 10] => true,
        [21, 8] => true,
        [21, 9] => true,
        [21, 10] => true,
        [21, 11] => true,
        [21, 12] => true,
        [21, 13] => true,
        [21, 14] => true,
        [22, 8] => true,
        [22, 9] => true,
        [22, 10] => true,
        [22, 11] => true,
        [22, 12] => true,
        [22, 13] => true,
        [22, 14] => true,
        [23, 8] => true,
        [23, 9] => true,
        [24, 8] => true,
        [24, 9] => true,
        [25, 8] => true,
        [25, 9] => true,
      }

      # Variables that are used by the breadth first search
      # Storing cells that the search has visited, prevents unnecessary steps
      # Expanding the frontier of the search in order makes the search expand
      # from the center outward

      # The cells from which the search is to expand
      search.frontier              ||= []
      # A hash of where each cell was expanded from
      # The key is a cell, and the value is the cell it came from
      search.came_from             ||= {}
      # Cells that are part of the path from the target to the star
      search.path                  ||= {}

      # What the user is currently editing on the grid
      # We store this value, because we want to remember the value even when
      # the user's cursor is no longer over what they're interacting with, but
      # they are still clicking down on the mouse.
      state.current_input ||= :none
    end

    def calc
      # Setup the search to start from the star
      search.frontier << grid.star
      search.came_from[grid.star] = nil

      # Until there are no more cells to expand from
      until search.frontier.empty?
        # Takes the next frontier cell
        new_frontier = search.frontier.shift
        # For each of its neighbors
        adjacent_neighbors(new_frontier).each do |neighbor|
          # That have not been visited and are not walls
          unless search.came_from.has_key?(neighbor) || grid.walls.has_key?(neighbor)
            # Add them to the frontier and mark them as visited in the first grid
            # Unless the target has been visited
            # Add the neighbor to the frontier and remember which cell it came from
            search.frontier << neighbor
            search.came_from[neighbor] = new_frontier
          end
        end
      end
    end


    # Draws everything onto the screen
    def render
      render_background
      # render_heat_map
      render_walls
      # render_path
      # render_labels
      render_arrows
      render_star
      render_target
      unless grid.walls.has_key?(grid.target)
        render_trail
      end
    end

    def render_trail(current_cell=grid.target)
      return if current_cell == grid.star
      parent_cell = search.came_from[current_cell]
      if current_cell && parent_cell
        outputs.lines << [(current_cell.x + 0.5) * grid.cell_size, (current_cell.y + 0.5) * grid.cell_size,
        (parent_cell.x + 0.5) * grid.cell_size, (parent_cell.y + 0.5) * grid.cell_size, purple]

      end
      render_trail(parent_cell)
    end

    def render_arrows
      search.came_from.each do |child, parent|
        if parent && child
          arrow_cell = [(child.x + parent.x) / 2, (child.y + parent.y) / 2]
          if parent.x > child.x # If the parent cell is to the right of the child cell
            # Point arrow right
            outputs.sprites << scale_up(arrow_cell).merge({ path: 'arrow.png', angle: 0})
          elsif parent.x < child.x # If the parent cell is to the right of the child cell
            outputs.sprites << scale_up(arrow_cell).merge({ path: 'arrow.png', angle: 180})
          elsif parent.y > child.y # If the parent cell is to the right of the child cell
            outputs.sprites << scale_up(arrow_cell).merge({ path: 'arrow.png', angle: 90})
          elsif parent.y < child.y # If the parent cell is to the right of the child cell
            outputs.sprites << scale_up(arrow_cell).merge({ path: 'arrow.png', angle: 270})
          end
        end
      end
    end

    # The methods below subdivide the task of drawing everything to the screen

    # Draws what the grid looks like with nothing on it
    def render_background
      render_unvisited
      render_grid_lines
    end

    # Draws both grids
    def render_unvisited
      outputs.solids << scale_up(grid.rect).merge(unvisited_color)
    end

    # Draws grid lines to show the division of the grid into cells
    def render_grid_lines
      outputs.lines << (0..grid.width).map { |x| vertical_line(x) }
      outputs.lines << (0..grid.height).map { |y| horizontal_line(y) }
    end

    # Easy way to draw vertical lines given an index
    def vertical_line x
      line = { x: x, y: 0, w: 0, h: grid.height }
      line.transform_values { |v| v * grid.cell_size }
    end

    # Easy way to draw horizontal lines given an index
    def horizontal_line y
      line = { x: 0, y: y, w: grid.width, h: 0 }
      line.transform_values { |v| v * grid.cell_size }
    end

    # Draws the walls on both grids
    def render_walls
      outputs.solids << grid.walls.map do |key, value|
        scale_up(key).merge(wall_color)
      end
    end

    # Renders the star on both grids
    def render_star
      outputs.sprites << scale_up(grid.star).merge({ path: 'star.png' })
    end

    # Renders the target on both grids
    def render_target
      outputs.sprites << scale_up(grid.target).merge({ path: 'target.png'})
    end

    # Labels the grids
    def render_labels
      outputs.labels << [200, 625, "Without early exit"]
    end

    # Renders the path based off of the search.path hash
    def render_path
      # If the star and target are disconnected there will only be one path
      # The path should not render in that case
      unless search.path.size == 1
        search.path.each_key do | cell |
          # Renders path on both grids
          outputs.solids << [scale_up(cell), path_color]
        end
      end
    end

    # Calculates the path from the target to the star after the search is over
    # Relies on the came_from hash
    # Fills the search.path hash, which is later rendered on screen
    def calc_path
      endpoint = grid.target
      while endpoint
        search.path[endpoint] = true
        endpoint = search.came_from[endpoint]
      end
    end

    # In code, the cells are represented as 1x1 rectangles
    # When drawn, the cells are larger than 1x1 rectangles
    # This method is used to scale up cells, and lines
    # Objects are scaled up according to the grid.cell_size variable
    # This allows for easy customization of the visual scale of the grid
    def scale_up(cell)
      x = cell.x * grid.cell_size
      y = cell.y * grid.cell_size
      w = cell.w.zero? ? grid.cell_size : cell.w * grid.cell_size
      h = cell.h.zero? ? grid.cell_size : cell.h * grid.cell_size
      { x: x, y: y, w: w, h: h }
    end

    # This method processes user input every tick
    # Any method with "1" is related to the first grid
    # Any method with "2" is related to the second grid
    def input
      # The program has to remember that the user is dragging an object
      # even when the mouse is no longer over that object
      # So detecting input and processing input is separate
      # detect_input
      # process_input
      if inputs.mouse.up
        state.current_input = :none
      elsif star_clicked?
        state.current_input = :star
      end

      if mouse_inside_grid?
        unless grid.target == cell_closest_to_mouse
          grid.target = cell_closest_to_mouse
        end
        if state.current_input == :star
          unless grid.star == cell_closest_to_mouse
            grid.star = cell_closest_to_mouse
          end
        end
      end
    end

    # Determines what the user is editing and stores the value
    # Storing the value allows the user to continue the same edit as long as the
    # mouse left click is held
    def detect_input
      # When the mouse is up, nothing is being edited
      if inputs.mouse.up
        state.current_input = :none
      # When the star in the no second grid is clicked
      elsif star_clicked?
        state.current_input = :star
      # When the target in the no second grid is clicked
      elsif target_clicked?
        state.current_input = :target
      # When a wall in the first grid is clicked
      elsif wall_clicked?
        state.current_input = :remove_wall
      # When the first grid is clicked
      elsif grid_clicked?
        state.current_input = :add_wall
      end
    end

    # Processes click and drag based on what the user is currently dragging
    def process_input
      if state.current_input == :star
        input_star
      elsif state.current_input == :target
        input_target
      elsif state.current_input == :remove_wall
        input_remove_wall
      elsif state.current_input == :add_wall
        input_add_wall
      end
    end

    # Moves the star to the cell closest to the mouse in the first grid
    # Only resets the search if the star changes position
    # Called whenever the user is editing the star (puts mouse down on star)
    def input_star
      old_star = grid.star.clone
      grid.star = cell_closest_to_mouse
      unless old_star == grid.star
        reset_search
      end
    end

    # Moves the target to the grid closest to the mouse in the first grid
    # Only reset_searchs the search if the target changes position
    # Called whenever the user is editing the target (puts mouse down on target)
    def input_target
      old_target = grid.target.clone
      grid.target = cell_closest_to_mouse
      unless old_target == grid.target
        reset_search
      end
    end

    # Removes walls in the first grid that are under the cursor
    def input_remove_wall
      # The mouse needs to be inside the grid, because we only want to remove walls
      # the cursor is directly over
      # Recalculations should only occur when a wall is actually deleted
      if mouse_inside_grid?
        if grid.walls.key?(cell_closest_to_mouse)
          grid.walls.delete(cell_closest_to_mouse)
          reset_search
        end
      end
    end

    # Adds a wall in the first grid in the cell the mouse is over
    def input_add_wall
      if mouse_inside_grid?
        unless grid.walls.key?(cell_closest_to_mouse)
          grid.walls[cell_closest_to_mouse] = true
          reset_search
        end
      end
    end


    # Whenever the user edits the grid,
    # The search has to be reset_searchd upto the current step
    # with the current grid as the initial state of the grid
    def reset_search
      # Reset_Searchs the search
      search.frontier  = []
      search.came_from = {}
      search.path      = {}
    end


    # Returns a list of adjacent cells
    # Used to determine what the next cells to be added to the frontier are
    def adjacent_neighbors(cell)
      neighbors = []

      # Gets all the valid neighbors into the array
      # From southern neighbor, clockwise
      neighbors << [cell.x, cell.y - 1] unless cell.y == 0
      neighbors << [cell.x - 1, cell.y] unless cell.x == 0
      neighbors << [cell.x, cell.y + 1] unless cell.y == grid.height - 1
      neighbors << [cell.x + 1, cell.y] unless cell.x == grid.width - 1

      # Sorts the neighbors so the rendered path is a zigzag path
      # Cells in a diagonal direction are given priority
      # Comment this line to see the difference
      neighbors = neighbors.sort_by { |neighbor_x, neighbor_y|  proximity_to_star(neighbor_x, neighbor_y) }

      neighbors
    end

    # Finds the vertical and horizontal distance of a cell from the star
    # and returns the larger value
    # This method is used to have a zigzag pattern in the rendered path
    # A cell that is [5, 5] from the star,
    # is explored before over a cell that is [0, 7] away.
    # So, if possible, the search tries to go diagonal (zigzag) first
    def proximity_to_star(x, y)
      distance_x = (grid.star.x - x).abs
      distance_y = (grid.star.y - y).abs

      if distance_x > distance_y
        return distance_x
      else
        return distance_y
      end
    end

    # When the user grabs the star and puts their cursor to the far right
    # and moves up and down, the star is supposed to move along the grid as well
    # Finding the cell closest to the mouse helps with this
    def cell_closest_to_mouse
      # Closest cell to the mouse in the first grid
      x = (inputs.mouse.point.x / grid.cell_size).to_i
      y = (inputs.mouse.point.y / grid.cell_size).to_i
      # Bound x and y to the grid
      x = grid.width - 1 if x > grid.width - 1
      y = grid.height - 1 if y > grid.height - 1
      # Return closest cell
      [x, y]
    end

    # Signal that the user is going to be moving the star from the first grid
    def star_clicked?
      inputs.mouse.down && inputs.mouse.point.inside_rect?(scale_up(grid.star))
    end

    # Signal that the user is going to be moving the target from the first grid
    def target_clicked?
      inputs.mouse.down && inputs.mouse.point.inside_rect?(scale_up(grid.target))
    end

    # Signal that the user is going to be adding walls from the first grid
    def grid_clicked?
      inputs.mouse.down && mouse_inside_grid?
    end

    # Returns whether the mouse is inside of the first grid
    # Part of the condition that checks whether the user is adding a wall
    def mouse_inside_grid?
      inputs.mouse.point.inside_rect?(scale_up(grid.rect))
    end

    # These methods provide handy aliases to colors

    # Light brown
    def unvisited_color
      { r: 221, g: 212, b: 213 }
    end

    # Camo Green
    def wall_color
      { r: 134, g: 134, b: 120 }
    end

    # Pastel White
    def path_color
      [231, 230, 228]
    end

    def red
      [255, 0, 0]
    end

    def purple
      [149, 64, 191]
    end

    # Makes code more concise
    def grid
      state.grid
    end

    def search
      state.search
    end
  end

  # Method that is called by DragonRuby periodically
  # Used for updating animations and calculations
  def tick args

    # Pressing r will reset the application
    if args.inputs.keyboard.key_down.r
      args.gtk.reset
      reset
      return
    end

    # Every tick, new args are passed, and the Breadth First Search tick is called
    $breadcrumbs ||= Breadcrumbs.new
    $breadcrumbs.args = args
    $breadcrumbs.tick
  end


  def reset
    $breadcrumbs = nil
  end

   #  # Representation of how far away visited cells are from the star
   #  # Replaces the render_visited method
   #  # Visually demonstrates the effectiveness of early exit for pathfinding
   #  def render_heat_map
   #    # THIS CODE NEEDS SOME FIXING DUE TO REFACTORING
   #    search.came_from.each_key do | cell |
   #      distance = (grid.star.x - visited_cell.x).abs + (state.star.y - visited_cell.y).abs
   #      max_distance = grid.width + grid.height
   #      alpha = 255.to_i * distance.to_i / max_distance.to_i
   #      outputs.solids << [scale_up(visited_cell), red, alpha]
   #      # outputs.solids << [early_exit_scale_up(visited_cell), red, alpha]
   #    end
   #  end

```

### Early Exit - main.rb
```ruby
  # ./samples/13_path_finding_algorithms/04_early_exit/app/main.rb
  # Contributors outside of DragonRuby who also hold Copyright:
  # - Sujay Vadlakonda: https://github.com/sujayvadlakonda

  # Comparison of a breadth first search with and without early exit
  # Inspired by https://www.redblobgames.com/pathfinding/a-star/introduction.html

  # Demonstrates the exploration difference caused by early exit
  # Also demonstrates how breadth first search is used for path generation

  # The left grid is a breadth first search without early exit
  # The right grid is a breadth first search with early exit
  # The red squares represent how far the search expanded
  # The darker the red, the farther the search proceeded
  # Comparison of the heat map reveals how much searching can be saved by early exit
  # The white path shows path generation via breadth first search
  class EarlyExitBreadthFirstSearch
    attr_gtk

    # This method is called every frame/tick
    # Every tick, the current state of the search is rendered on the screen,
    # User input is processed, and
    # The next step in the search is calculated
    def tick
      defaults
      # If the grid has not been searched
      if state.visited.empty?
        # Complete the search
        state.max_steps.times { step }
        # And calculate the path
        calc_path
      end
      render
      input
    end

    def defaults
      # Variables to edit the size and appearance of the grid
      # Freely customizable to user's liking
      grid.width     ||= 15
      grid.height    ||= 15
      grid.cell_size ||= 40
      grid.rect      ||= [0, 0, grid.width, grid.height]

      # At some step the animation will end,
      # and further steps won't change anything (the whole grid.widthill be explored)
      # This step is roughly the grid's width * height
      # When anim_steps equals max_steps no more calculations will occur
      # and the slider will be at the end
      state.max_steps  ||= args.state.grid.width * args.state.grid.height

      # The location of the star and walls of the grid
      # They can be modified to have a different initial grid
      # Walls are stored in a hash for quick look up when doing the search
      state.star   ||= [2, 8]
      state.target ||= [10, 5]
      state.walls  ||= {}

      # Variables that are used by the breadth first search
      # Storing cells that the search has visited, prevents unnecessary steps
      # Expanding the frontier of the search in order makes the search expand
      # from the center outward

      # Visited cells in the first grid
      state.visited               ||= {}
      # Visited cells in the second grid
      state.early_exit_visited    ||= {}
      # The cells from which the search is to expand
      state.frontier              ||= []
      # A hash of where each cell was expanded from
      # The key is a cell, and the value is the cell it came from
      state.came_from             ||= {}
      # Cells that are part of the path from the target to the star
      state.path                  ||= {}

      # What the user is currently editing on the grid
      # We store this value, because we want to remember the value even when
      # the user's cursor is no longer over what they're interacting with, but
      # they are still clicking down on the mouse.
      state.current_input ||= :none
    end

    # Draws everything onto the screen
    def render
      render_background
      render_heat_map
      render_walls
      render_path
      render_star
      render_target
      render_labels
    end

    # The methods below subdivide the task of drawing everything to the screen

    # Draws what the grid looks like with nothing on it
    def render_background
      render_unvisited
      render_grid_lines
    end

    # Draws both grids
    def render_unvisited
      outputs.solids << scale_up(grid.rect).merge(unvisited_color)
      outputs.solids << early_exit_scale_up(grid.rect).merge(unvisited_color)
    end

    # Draws grid lines to show the division of the grid into cells
    def render_grid_lines
      outputs.lines << (0..grid.width).map { |x| vertical_line(x) }
      outputs.lines << (0..grid.width).map { |x| early_exit_vertical_line(x) }
      outputs.lines << (0..grid.height).map { |y| horizontal_line(y) }
      outputs.lines << (0..grid.height).map { |y| early_exit_horizontal_line(y) }
    end

    # Easy way to draw vertical lines given an index
    def vertical_line x
      line = { x: x, y: 0, w: 0, h: grid.height }
      line.transform_values { |v| v * grid.cell_size }
    end

    # Easy way to draw horizontal lines given an index
    def horizontal_line y
      line = { x: 0, y: y, w: grid.width, h: 0 }
      line.transform_values { |v| v * grid.cell_size }
    end

    # Easy way to draw vertical lines given an index
    def early_exit_vertical_line x
      vertical_line(x + grid.width + 1)
    end

    # Easy way to draw horizontal lines given an index
    def early_exit_horizontal_line y
      line = { x: grid.width + 1, y: y, w: grid.width, h: 0 }
      line.transform_values { |v| v * grid.cell_size }
    end

    # Draws the walls on both grids
    def render_walls
      state.walls.each_key do |wall|
        outputs.solids << scale_up(wall).merge(wall_color)
        outputs.solids << early_exit_scale_up(wall).merge(wall_color)
      end
    end

    # Renders the star on both grids
    def render_star
      outputs.sprites << scale_up(state.star).merge({path: 'star.png'})
      outputs.sprites << early_exit_scale_up(state.star).merge({path: 'star.png'})
    end

    # Renders the target on both grids
    def render_target
      outputs.sprites << scale_up(state.target).merge({path: 'target.png'})
      outputs.sprites << early_exit_scale_up(state.target).merge({path: 'target.png'})
    end

    # Labels the grids
    def render_labels
      outputs.labels << [200, 625, "Without early exit"]
      outputs.labels << [875, 625, "With early exit"]
    end

    # Renders the path based off of the state.path hash
    def render_path
      # If the star and target are disconnected there will only be one path
      # The path should not render in that case
      unless state.path.size == 1
        state.path.each_key do | cell |
          # Renders path on both grids
          outputs.solids << scale_up(cell).merge(path_color)
          outputs.solids << early_exit_scale_up(cell).merge(path_color)
        end
      end
    end

    # Calculates the path from the target to the star after the search is over
    # Relies on the came_from hash
    # Fills the state.path hash, which is later rendered on screen
    def calc_path
      endpoint = state.target
      while endpoint
        state.path[endpoint] = true
        endpoint = state.came_from[endpoint]
      end
    end

    # Representation of how far away visited cells are from the star
    # Replaces the render_visited method
    # Visually demonstrates the effectiveness of early exit for pathfinding
    def render_heat_map
      state.visited.each_key do | visited_cell |
        distance = (state.star.x - visited_cell.x).abs + (state.star.y - visited_cell.y).abs
        max_distance = grid.width + grid.height
        alpha = 255.to_i * distance.to_i / max_distance.to_i
        heat_color = red.merge({a: alpha })
        outputs.solids << scale_up(visited_cell).merge(heat_color)
      end

      state.early_exit_visited.each_key do | visited_cell |
        distance = (state.star.x - visited_cell.x).abs + (state.star.y - visited_cell.y).abs
        max_distance = grid.width + grid.height
        alpha = 255.to_i * distance.to_i / max_distance.to_i
        heat_color = red.merge({a: alpha })
        outputs.solids << early_exit_scale_up(visited_cell).merge(heat_color)
      end
    end

    # Translates the given cell grid.width + 1 to the right and then scales up
    # Used to draw cells for the second grid
    # This method does not work for lines,
    # so separate methods exist for the grid lines
    def early_exit_scale_up(cell)
      cell_clone = cell.clone
      cell_clone.x += grid.width + 1
      scale_up(cell_clone)
    end

    # In code, the cells are represented as 1x1 rectangles
    # When drawn, the cells are larger than 1x1 rectangles
    # This method is used to scale up cells, and lines
    # Objects are scaled up according to the grid.cell_size variable
    # This allows for easy customization of the visual scale of the grid
    def scale_up(cell)
      if cell.size == 2
        return {
          x: cell.x * grid.cell_size,
          y: cell.y * grid.cell_size,
          w: grid.cell_size,
          h: grid.cell_size
        }
      else
        return {
          x: cell.x * grid.cell_size,
          y: cell.y * grid.cell_size,
          w: cell.w * grid.cell_size,
          h: cell.h * grid.cell_size
        }
      end
    end

    # This method processes user input every tick
    # Any method with "1" is related to the first grid
    # Any method with "2" is related to the second grid
    def input
      # The program has to remember that the user is dragging an object
      # even when the mouse is no longer over that object
      # So detecting input and processing input is separate
      detect_input
      process_input
    end

    # Determines what the user is editing and stores the value
    # Storing the value allows the user to continue the same edit as long as the
    # mouse left click is held
    def detect_input
      # When the mouse is up, nothing is being edited
      if inputs.mouse.up
        state.current_input = :none
      # When the star in the no second grid is clicked
      elsif star_clicked?
        state.current_input = :star
      # When the star in the second grid is clicked
      elsif star2_clicked?
        state.current_input = :star2
      # When the target in the no second grid is clicked
      elsif target_clicked?
        state.current_input = :target
      # When the target in the second grid is clicked
      elsif target2_clicked?
        state.current_input = :target2
      # When a wall in the first grid is clicked
      elsif wall_clicked?
        state.current_input = :remove_wall
      # When a wall in the second grid is clicked
      elsif wall2_clicked?
        state.current_input = :remove_wall2
      # When the first grid is clicked
      elsif grid_clicked?
        state.current_input = :add_wall
      # When the second grid is clicked
      elsif grid2_clicked?
        state.current_input = :add_wall2
      end
    end

    # Processes click and drag based on what the user is currently dragging
    def process_input
      if state.current_input == :star
        input_star
      elsif state.current_input == :star2
        input_star2
      elsif state.current_input == :target
        input_target
      elsif state.current_input == :target2
        input_target2
      elsif state.current_input == :remove_wall
        input_remove_wall
      elsif state.current_input == :remove_wall2
        input_remove_wall2
      elsif state.current_input == :add_wall
        input_add_wall
      elsif state.current_input == :add_wall2
        input_add_wall2
      end
    end

    # Moves the star to the cell closest to the mouse in the first grid
    # Only resets the search if the star changes position
    # Called whenever the user is editing the star (puts mouse down on star)
    def input_star
      old_star = state.star.clone
      state.star = cell_closest_to_mouse
      unless old_star == state.star
        reset_search
      end
    end

    # Moves the star to the cell closest to the mouse in the second grid
    # Only resets the search if the star changes position
    # Called whenever the user is editing the star (puts mouse down on star)
    def input_star2
      old_star = state.star.clone
      state.star = cell_closest_to_mouse2
      unless old_star == state.star
        reset_search
      end
    end

    # Moves the target to the grid closest to the mouse in the first grid
    # Only reset_searchs the search if the target changes position
    # Called whenever the user is editing the target (puts mouse down on target)
    def input_target
      old_target = state.target.clone
      state.target = cell_closest_to_mouse
      unless old_target == state.target
        reset_search
      end
    end

    # Moves the target to the cell closest to the mouse in the second grid
    # Only reset_searchs the search if the target changes position
    # Called whenever the user is editing the target (puts mouse down on target)
    def input_target2
      old_target = state.target.clone
      state.target = cell_closest_to_mouse2
      unless old_target == state.target
        reset_search
      end
    end

    # Removes walls in the first grid that are under the cursor
    def input_remove_wall
      # The mouse needs to be inside the grid, because we only want to remove walls
      # the cursor is directly over
      # Recalculations should only occur when a wall is actually deleted
      if mouse_inside_grid?
        if state.walls.key?(cell_closest_to_mouse)
          state.walls.delete(cell_closest_to_mouse)
          reset_search
        end
      end
    end

    # Removes walls in the second grid that are under the cursor
    def input_remove_wall2
      # The mouse needs to be inside the grid, because we only want to remove walls
      # the cursor is directly over
      # Recalculations should only occur when a wall is actually deleted
      if mouse_inside_grid2?
        if state.walls.key?(cell_closest_to_mouse2)
          state.walls.delete(cell_closest_to_mouse2)
          reset_search
        end
      end
    end

    # Adds a wall in the first grid in the cell the mouse is over
    def input_add_wall
      if mouse_inside_grid?
        unless state.walls.key?(cell_closest_to_mouse)
          state.walls[cell_closest_to_mouse] = true
          reset_search
        end
      end
    end


    # Adds a wall in the second grid in the cell the mouse is over
    def input_add_wall2
      if mouse_inside_grid2?
        unless state.walls.key?(cell_closest_to_mouse2)
          state.walls[cell_closest_to_mouse2] = true
          reset_search
        end
      end
    end

    # Whenever the user edits the grid,
    # The search has to be reset_searchd upto the current step
    # with the current grid as the initial state of the grid
    def reset_search
      # Reset_Searchs the search
      state.frontier  = []
      state.visited   = {}
      state.early_exit_visited   = {}
      state.came_from = {}
      state.path      = {}
    end

    # Moves the search forward one step
    def step
      # The setup to the search
      # Runs once when there are no visited cells
      if state.visited.empty?
        state.visited[state.star] = true
        state.early_exit_visited[state.star] = true
        state.frontier << state.star
        state.came_from[state.star] = nil
      end

      # A step in the search
      unless state.frontier.empty?
        # Takes the next frontier cell
        new_frontier = state.frontier.shift
        # For each of its neighbors
        adjacent_neighbors(new_frontier).each do |neighbor|
          # That have not been visited and are not walls
          unless state.visited.key?(neighbor) || state.walls.key?(neighbor)
            # Add them to the frontier and mark them as visited in the first grid
            state.visited[neighbor] = true
            # Unless the target has been visited
            unless state.visited.key?(state.target)
              # Mark the neighbor as visited in the second grid as well
              state.early_exit_visited[neighbor] = true
            end

            # Add the neighbor to the frontier and remember which cell it came from
            state.frontier << neighbor
            state.came_from[neighbor] = new_frontier
          end
        end
      end
    end


    # Returns a list of adjacent cells
    # Used to determine what the next cells to be added to the frontier are
    def adjacent_neighbors(cell)
      neighbors = []

      # Gets all the valid neighbors into the array
      # From southern neighbor, clockwise
      neighbors << [cell.x, cell.y - 1] unless cell.y == 0
      neighbors << [cell.x - 1, cell.y] unless cell.x == 0
      neighbors << [cell.x, cell.y + 1] unless cell.y == grid.height - 1
      neighbors << [cell.x + 1, cell.y] unless cell.x == grid.width - 1

      # Sorts the neighbors so the rendered path is a zigzag path
      # Cells in a diagonal direction are given priority
      # Comment this line to see the difference
      neighbors = neighbors.sort_by { |neighbor_x, neighbor_y|  proximity_to_star(neighbor_x, neighbor_y) }

      neighbors
    end

    # Finds the vertical and horizontal distance of a cell from the star
    # and returns the larger value
    # This method is used to have a zigzag pattern in the rendered path
    # A cell that is [5, 5] from the star,
    # is explored before over a cell that is [0, 7] away.
    # So, if possible, the search tries to go diagonal (zigzag) first
    def proximity_to_star(x, y)
      distance_x = (state.star.x - x).abs
      distance_y = (state.star.y - y).abs

      if distance_x > distance_y
        return distance_x
      else
        return distance_y
      end
    end

    # When the user grabs the star and puts their cursor to the far right
    # and moves up and down, the star is supposed to move along the grid as well
    # Finding the cell closest to the mouse helps with this
    def cell_closest_to_mouse
      # Closest cell to the mouse in the first grid
      x = (inputs.mouse.point.x / grid.cell_size).to_i
      y = (inputs.mouse.point.y / grid.cell_size).to_i
      # Bound x and y to the grid
      x = grid.width - 1 if x > grid.width - 1
      y = grid.height - 1 if y > grid.height - 1
      # Return closest cell
      [x, y]
    end

    # When the user grabs the star and puts their cursor to the far right
    # and moves up and down, the star is supposed to move along the grid as well
    # Finding the cell closest to the mouse in the second grid helps with this
    def cell_closest_to_mouse2
      # Closest cell grid to the mouse in the second
      x = (inputs.mouse.point.x / grid.cell_size).to_i
      y = (inputs.mouse.point.y / grid.cell_size).to_i
      # Translate the cell to the first grid
      x -= grid.width + 1
      # Bound x and y to the first grid
      x = grid.width - 1 if x > grid.width - 1
      y = grid.height - 1 if y > grid.height - 1
      # Return closest cell
      [x, y]
    end

    # Signal that the user is going to be moving the star from the first grid
    def star_clicked?
      inputs.mouse.down && inputs.mouse.point.inside_rect?(scale_up(state.star))
    end

    # Signal that the user is going to be moving the star from the second grid
    def star2_clicked?
      inputs.mouse.down && inputs.mouse.point.inside_rect?(early_exit_scale_up(state.star))
    end

    # Signal that the user is going to be moving the target from the first grid
    def target_clicked?
      inputs.mouse.down && inputs.mouse.point.inside_rect?(scale_up(state.target))
    end

    # Signal that the user is going to be moving the target from the second grid
    def target2_clicked?
      inputs.mouse.down && inputs.mouse.point.inside_rect?(early_exit_scale_up(state.target))
    end

    # Signal that the user is going to be removing walls from the first grid
    def wall_clicked?
      inputs.mouse.down && mouse_inside_wall?
    end

    # Signal that the user is going to be removing walls from the second grid
    def wall2_clicked?
      inputs.mouse.down && mouse_inside_wall2?
    end

    # Signal that the user is going to be adding walls from the first grid
    def grid_clicked?
      inputs.mouse.down && mouse_inside_grid?
    end

    # Signal that the user is going to be adding walls from the second grid
    def grid2_clicked?
      inputs.mouse.down && mouse_inside_grid2?
    end

    # Returns whether the mouse is inside of a wall in the first grid
    # Part of the condition that checks whether the user is removing a wall
    def mouse_inside_wall?
      state.walls.each_key do | wall |
        return true if inputs.mouse.point.inside_rect?(scale_up(wall))
      end

      false
    end

    # Returns whether the mouse is inside of a wall in the second grid
    # Part of the condition that checks whether the user is removing a wall
    def mouse_inside_wall2?
      state.walls.each_key do | wall |
        return true if inputs.mouse.point.inside_rect?(early_exit_scale_up(wall))
      end

      false
    end

    # Returns whether the mouse is inside of the first grid
    # Part of the condition that checks whether the user is adding a wall
    def mouse_inside_grid?
      inputs.mouse.point.inside_rect?(scale_up(grid.rect))
    end

    # Returns whether the mouse is inside of the second grid
    # Part of the condition that checks whether the user is adding a wall
    def mouse_inside_grid2?
      inputs.mouse.point.inside_rect?(early_exit_scale_up(grid.rect))
    end

    # These methods provide handy aliases to colors

    # Light brown
    def unvisited_color
      [221, 212, 213]
      { r: 221, g: 212, b: 213 }
    end

    # Camo Green
    def wall_color
      { r: 134, g: 134, b: 120 }
    end

    # Pastel White
    def path_color
      { r: 231, g: 230, b: 228 }
    end

    def red
      { r: 255, g: 0, b: 0 }
    end

    # Makes code more concise
    def grid
      state.grid
    end
  end

  # Method that is called by DragonRuby periodically
  # Used for updating animations and calculations
  def tick args

    # Pressing r will reset the application
    if args.inputs.keyboard.key_down.r
      args.gtk.reset
      reset
      return
    end

    # Every tick, new args are passed, and the Breadth First Search tick is called
    $early_exit_breadth_first_search ||= EarlyExitBreadthFirstSearch.new
    $early_exit_breadth_first_search.args = args
    $early_exit_breadth_first_search.tick
  end


  def reset
    $early_exit_breadth_first_search = nil
  end

```

### Dijkstra - main.rb
```ruby
  # ./samples/13_path_finding_algorithms/05_dijkstra/app/main.rb
  # Contributors outside of DragonRuby who also hold Copyright:
  # - Sujay Vadlakonda: https://github.com/sujayvadlakonda

  # Demonstrates how Dijkstra's Algorithm allows movement costs to be considered

  # Inspired by https://www.redblobgames.com/pathfinding/a-star/introduction.html

  # The first grid is a breadth first search with an early exit.
  # It shows a heat map of all the cells that were visited by the search and their relative distance.

  # The second grid is an implementation of Dijkstra's algorithm.
  # Light green cells have 5 times the movement cost of regular cells.
  # The heat map will darken based on movement cost.

  # Dark green cells are walls, and the search cannot go through them.
  class Movement_Costs
    attr_gtk

    # This method is called every frame/tick
    # Every tick, the current state of the search is rendered on the screen,
    # User input is processed, and
    # The next step in the search is calculated
    def tick
      defaults
      render
      input
      calc
    end

    def defaults
      # Variables to edit the size and appearance of the grid
      # Freely customizable to user's liking
      grid.width     ||= 10
      grid.height    ||= 10
      grid.cell_size ||= 60
      grid.rect      ||= [0, 0, grid.width, grid.height]

      # The location of the star and walls of the grid
      # They can be modified to have a different initial grid
      # Walls are stored in a hash for quick look up when doing the search
      state.star   ||= [1, 5]
      state.target ||= [8, 4]
      state.walls  ||= {[1, 1] => true, [2, 1] => true, [3, 1] => true, [1, 2] => true, [2, 2] => true, [3, 2] => true}
      state.hills  ||= {
        [4, 1] => true,
        [5, 1] => true,
        [4, 2] => true,
        [5, 2] => true,
        [6, 2] => true,
        [4, 3] => true,
        [5, 3] => true,
        [6, 3] => true,
        [3, 4] => true,
        [4, 4] => true,
        [5, 4] => true,
        [6, 4] => true,
        [7, 4] => true,
        [3, 5] => true,
        [4, 5] => true,
        [5, 5] => true,
        [6, 5] => true,
        [7, 5] => true,
        [4, 6] => true,
        [5, 6] => true,
        [6, 6] => true,
        [7, 6] => true,
        [4, 7] => true,
        [5, 7] => true,
        [6, 7] => true,
        [4, 8] => true,
        [5, 8] => true,
      }

      # What the user is currently editing on the grid
      # We store this value, because we want to remember the value even when
      # the user's cursor is no longer over what they're interacting with, but
      # they are still clicking down on the mouse.
      state.user_input ||= :none

      # Values that are used for the breadth first search
      # Keeping track of what cells were visited prevents counting cells multiple times
      breadth_first_search.visited    ||= {}
      # The cells from which the breadth first search will expand
      breadth_first_search.frontier   ||= []
      # Keeps track of which cell all cells were searched from
      # Used to recreate the path from the target to the star
      breadth_first_search.came_from  ||= {}

      # Keeps track of the movement cost so far to be at a cell
      # Allows the costs of new cells to be quickly calculated
      # Also doubles as a way to check if cells have already been visited
      dijkstra_search.cost_so_far ||= {}
      # The cells from which the Dijkstra search will expand
      dijkstra_search.frontier    ||= []
      # Keeps track of which cell all cells were searched from
      # Used to recreate the path from the target to the star
      dijkstra_search.came_from   ||= {}
    end

    # Draws everything onto the screen
    def render
      render_background

      render_heat_maps

      render_star
      render_target
      render_hills
      render_walls

      render_paths
    end
    # The methods below subdivide the task of drawing everything to the screen

    # Draws what the grid looks like with nothing on it
    def render_background
      render_unvisited
      render_grid_lines
      render_labels
    end

    # Draws two rectangles the size of the grid in the default cell color
    # Used as part of the background
    def render_unvisited
      outputs.solids << scale_up(grid.rect).merge(unvisited_color)
      outputs.solids << move_and_scale_up(grid.rect).merge(unvisited_color)
    end

    # Draws grid lines to show the division of the grid into cells
    def render_grid_lines
      outputs.lines << (0..grid.width).map { |x| vertical_line(x) }
      outputs.lines << (0..grid.width).map { |x| shifted_vertical_line(x) }
      outputs.lines << (0..grid.height).map { |y| horizontal_line(y) }
      outputs.lines << (0..grid.height).map { |y| shifted_horizontal_line(y) }
    end

    # A line the size of the grid, multiplied by the cell size for rendering
    def vertical_line x
      line = { x: x, y: 0, w: 0, h: grid.height }
      line.transform_values { |v| v * grid.cell_size }
    end

    # A line the size of the grid, multiplied by the cell size for rendering
    def horizontal_line y
      line = { x: 0, y: y, w: grid.width, h: 0 }
      line.transform_values { |v| v * grid.cell_size }
    end

    # Translate vertical line by the size of the grid and 1
    def shifted_vertical_line x
      vertical_line(x + grid.width + 1)
    end

    # Get horizontal line and shift to the right
    def shifted_horizontal_line y
      line = { x: grid.width + 1, y: y, w: grid.width, h: 0 }
      line.transform_values { |v| v * grid.cell_size }
    end

    # Labels the grids
    def render_labels
      outputs.labels << [175, 650, "Number of steps", 3]
      outputs.labels << [925, 650, "Distance", 3]
    end

    def render_paths
      render_breadth_first_search_path
      render_dijkstra_path
    end

    def render_heat_maps
      render_breadth_first_search_heat_map
      render_dijkstra_heat_map
    end

    # This heat map shows the cells explored by the breadth first search and how far they are from the star.
    def render_breadth_first_search_heat_map
      # For each cell explored
      breadth_first_search.visited.each_key do | visited_cell |
        # Find its distance from the star
        distance = (state.star.x - visited_cell.x).abs + (state.star.y - visited_cell.y).abs
        max_distance = grid.width + grid.height
        # Get it as a percent of the maximum distance and scale to 255 for use as an alpha value
        alpha = 255.to_i * distance.to_i / max_distance.to_i
        heat_color = red.merge({a: alpha })
        outputs.solids << scale_up(visited_cell).merge(heat_color)
      end
    end

    def render_breadth_first_search_path
      # If the search found the target
      if breadth_first_search.visited.has_key?(state.target)
        # Start from the target
        endpoint = state.target
        # And the cell it came from
        next_endpoint = breadth_first_search.came_from[endpoint]
        while endpoint && next_endpoint
          # Draw a path between these two cells
          path = get_path_between(endpoint, next_endpoint)
          outputs.solids << scale_up(path).merge(path_color)
          # And get the next pair of cells
          endpoint = next_endpoint
          next_endpoint = breadth_first_search.came_from[endpoint]
          # Continue till there are no more cells
        end
      end
    end

    def render_dijkstra_heat_map
      dijkstra_search.cost_so_far.each do |visited_cell, cost|
        max_cost = (grid.width + grid.height) #* 5
        alpha = 255.to_i * cost.to_i / max_cost.to_i
        heat_color = red.merge({a: alpha})
        outputs.solids << move_and_scale_up(visited_cell).merge(heat_color)
      end
    end

    def render_dijkstra_path
      # If the search found the target
      if dijkstra_search.came_from.has_key?(state.target)
        # Get the target and the cell it came from
        endpoint = state.target
        next_endpoint = dijkstra_search.came_from[endpoint]
        while endpoint && next_endpoint
          # Draw a path between them
          path = get_path_between(endpoint, next_endpoint)
          outputs.solids << move_and_scale_up(path).merge(path_color)

          # Shift one cell down the path
          endpoint = next_endpoint
          next_endpoint = dijkstra_search.came_from[endpoint]

          # Repeat till the end of the path
        end
      end
    end

    # Renders the star on both grids
    def render_star
      outputs.sprites << scale_up(state.star).merge({path: 'star.png'})
      outputs.sprites << move_and_scale_up(state.star).merge({path: 'star.png'})
    end

    # Renders the target on both grids
    def render_target
      outputs.sprites << scale_up(state.target).merge({path: 'target.png'})
      outputs.sprites << move_and_scale_up(state.target).merge({path: 'target.png'})
    end

    def render_hills
      state.hills.each_key do |hill|
        outputs.solids << scale_up(hill).merge(hill_color)
        outputs.solids << move_and_scale_up(hill).merge(hill_color)
      end
    end

    # Draws the walls on both grids
    def render_walls
      state.walls.each_key do |wall|
        outputs.solids << scale_up(wall).merge(wall_color)
        outputs.solids << move_and_scale_up(wall).merge(wall_color)
      end
    end

    def get_path_between(cell_one, cell_two)
      path = nil
      if cell_one.x == cell_two.x
        if cell_one.y < cell_two.y
          path = [cell_one.x + 0.3, cell_one.y + 0.3, 0.4, 1.4]
        else
          path = [cell_two.x + 0.3, cell_two.y + 0.3, 0.4, 1.4]
        end
      else
        if cell_one.x < cell_two.x
          path = [cell_one.x + 0.3, cell_one.y + 0.3, 1.4, 0.4]
        else
          path = [cell_two.x + 0.3, cell_two.y + 0.3, 1.4, 0.4]
        end
      end
      path
    end

    # Translates the given cell grid.width + 1 to the right and then scales up
    # Used to draw cells for the second grid
    # This method does not work for lines,
    # so separate methods exist for the grid lines
    def move_and_scale_up(cell)
      cell_clone = cell.clone
      cell_clone.x += grid.width + 1
      scale_up(cell_clone)
    end

    # In code, the cells are represented as 1x1 rectangles
    # When drawn, the cells are larger than 1x1 rectangles
    # This method is used to scale up cells, and lines
    # Objects are scaled up according to the grid.cell_size variable
    # This allows for easy customization of the visual scale of the grid
    def scale_up(cell)
      if cell.size == 2
        return {
          x: cell.x * grid.cell_size,
          y: cell.y * grid.cell_size,
          w: grid.cell_size,
          h: grid.cell_size
        }
      else
        return {
          x: cell.x * grid.cell_size,
          y: cell.y * grid.cell_size,
          w: cell.w * grid.cell_size,
          h: cell.h * grid.cell_size
        }
      end
    end

    # Handles user input every tick so the grid can be edited
    # Separate input detection and processing is needed
    # For example: Adding walls is started by clicking down on a hill,
    # but the mouse doesn't need to remain over hills to add walls
    def input
      # If the mouse was lifted this tick
      if inputs.mouse.up
        # Set current input to none
        state.user_input = :none
      end

      # If the mouse was clicked this tick
      if inputs.mouse.down
        # Determine what the user is editing and edit the state.user_input variable
        determine_input
      end

      # Process user input based on user_input variable and current mouse position
      process_input
    end

    # Determines what the user is editing and stores the value
    # This method is called the tick the mouse is clicked
    # Storing the value allows the user to continue the same edit as long as the
    # mouse left click is held
    def determine_input
      # If the mouse is over the star in the first grid
      if mouse_over_star?
        # The user is editing the star from the first grid
        state.user_input = :star
      # If the mouse is over the star in the second grid
      elsif mouse_over_star2?
        # The user is editing the star from the second grid
        state.user_input = :star2
      # If the mouse is over the target in the first grid
      elsif mouse_over_target?
        # The user is editing the target from the first grid
        state.user_input = :target
      # If the mouse is over the target in the second grid
      elsif mouse_over_target2?
        # The user is editing the target from the second grid
        state.user_input = :target2
      # If the mouse is over a wall in the first grid
      elsif mouse_over_wall?
        # The user is removing a wall from the first grid
        state.user_input = :remove_wall
      # If the mouse is over a wall in the second grid
      elsif mouse_over_wall2?
        # The user is removing a wall from the second grid
        state.user_input = :remove_wall2
      # If the mouse is over a hill in the first grid
      elsif mouse_over_hill?
        # The user is adding a wall from the first grid
        state.user_input = :add_wall
      # If the mouse is over a hill in the second grid
      elsif mouse_over_hill2?
        # The user is adding a wall from the second grid
        state.user_input = :add_wall2
      # If the mouse is over the first grid
      elsif mouse_over_grid?
        # The user is adding a hill from the first grid
        state.user_input = :add_hill
      # If the mouse is over the second grid
      elsif mouse_over_grid2?
        # The user is adding a hill from the second grid
        state.user_input = :add_hill2
      end
    end

    # Processes click and drag based on what the user is currently dragging
    def process_input
      if state.user_input == :star
        input_star
      elsif state.user_input == :star2
        input_star2
      elsif state.user_input == :target
        input_target
      elsif state.user_input == :target2
        input_target2
      elsif state.user_input == :remove_wall
        input_remove_wall
      elsif state.user_input == :remove_wall2
        input_remove_wall2
      elsif state.user_input == :add_hill
        input_add_hill
      elsif state.user_input == :add_hill2
        input_add_hill2
      elsif state.user_input == :add_wall
        input_add_wall
      elsif state.user_input == :add_wall2
        input_add_wall2
      end
    end

    # Calculates the two searches
    def calc
      # If the searches have not started
      if breadth_first_search.visited.empty?
        # Calculate the two searches
        calc_breadth_first
        calc_dijkstra
      end
    end


    def calc_breadth_first
      # Sets up the Breadth First Search
      breadth_first_search.visited[state.star]   = true
      breadth_first_search.frontier              << state.star
      breadth_first_search.came_from[state.star] = nil

      until breadth_first_search.frontier.empty?
        return if breadth_first_search.visited.key?(state.target)
        # A step in the search
        # Takes the next frontier cell
        new_frontier = breadth_first_search.frontier.shift
        # For each of its neighbors
        adjacent_neighbors(new_frontier).each do | neighbor |
          # That have not been visited and are not walls
          unless breadth_first_search.visited.key?(neighbor) || state.walls.key?(neighbor)
            # Add them to the frontier and mark them as visited in the first grid
            breadth_first_search.visited[neighbor] = true
            breadth_first_search.frontier << neighbor
            # Remember which cell the neighbor came from
            breadth_first_search.came_from[neighbor] = new_frontier
          end
        end
      end
    end

    # Calculates the Dijkstra Search from the beginning to the end

    def calc_dijkstra
      # The initial values for the Dijkstra search
      dijkstra_search.frontier                << [state.star, 0]
      dijkstra_search.came_from[state.star]   = nil
      dijkstra_search.cost_so_far[state.star] = 0

      # Until their are no more cells to be explored
      until dijkstra_search.frontier.empty?
        # Get the next cell to be explored from
        # We get the first element of the array which is the cell. The second element is the priority.
        current = dijkstra_search.frontier.shift[0]

        # Stop the search if we found the target
        return if current == state.target

        # For each of the neighbors
        adjacent_neighbors(current).each do | neighbor |
          # Unless this cell is a wall or has already been explored.
          unless dijkstra_search.came_from.key?(neighbor) or state.walls.key?(neighbor)
            # Calculate the movement cost of getting to this cell and memo
            new_cost = dijkstra_search.cost_so_far[current] + cost(neighbor)
            dijkstra_search.cost_so_far[neighbor] = new_cost

            # Add this neighbor to the cells too be explored
            dijkstra_search.frontier << [neighbor, new_cost]
            dijkstra_search.came_from[neighbor] = current
          end
        end

        # Sort the frontier so exploration occurs that have a low cost so far.
        # My implementation of a priority queue
        dijkstra_search.frontier = dijkstra_search.frontier.sort_by {|cell, priority| priority}
      end
    end

    def cost(cell)
      return 5 if state.hills.key? cell
      1
    end




    # Moves the star to the cell closest to the mouse in the first grid
    # Only resets the search if the star changes position
    # Called whenever the user is editing the star (puts mouse down on star)
    def input_star
      old_star = state.star.clone
      unless cell_closest_to_mouse == state.target
        state.star = cell_closest_to_mouse
      end
      unless old_star == state.star
        reset_search
      end
    end

    # Moves the star to the cell closest to the mouse in the second grid
    # Only resets the search if the star changes position
    # Called whenever the user is editing the star (puts mouse down on star)
    def input_star2
      old_star = state.star.clone
      unless cell_closest_to_mouse2 == state.target
        state.star = cell_closest_to_mouse2
      end
      unless old_star == state.star
        reset_search
      end
    end

    # Moves the target to the grid closest to the mouse in the first grid
    # Only reset_searchs the search if the target changes position
    # Called whenever the user is editing the target (puts mouse down on target)
    def input_target
      old_target = state.target.clone
      unless cell_closest_to_mouse == state.star
        state.target = cell_closest_to_mouse
      end
      unless old_target == state.target
        reset_search
      end
    end

    # Moves the target to the cell closest to the mouse in the second grid
    # Only reset_searchs the search if the target changes position
    # Called whenever the user is editing the target (puts mouse down on target)
    def input_target2
      old_target = state.target.clone
      unless cell_closest_to_mouse2 == state.star
        state.target = cell_closest_to_mouse2
      end
      unless old_target == state.target
        reset_search
      end
    end

    # Removes walls in the first grid that are under the cursor
    def input_remove_wall
      # The mouse needs to be inside the grid, because we only want to remove walls
      # the cursor is directly over
      # Recalculations should only occur when a wall is actually deleted
      if mouse_over_grid?
        if state.walls.key?(cell_closest_to_mouse) or state.hills.key?(cell_closest_to_mouse)
          state.walls.delete(cell_closest_to_mouse)
          state.hills.delete(cell_closest_to_mouse)
          reset_search
        end
      end
    end

    # Removes walls in the second grid that are under the cursor
    def input_remove_wall2
      # The mouse needs to be inside the grid, because we only want to remove walls
      # the cursor is directly over
      # Recalculations should only occur when a wall is actually deleted
      if mouse_over_grid2?
        if state.walls.key?(cell_closest_to_mouse2) or state.hills.key?(cell_closest_to_mouse2)
          state.walls.delete(cell_closest_to_mouse2)
          state.hills.delete(cell_closest_to_mouse2)
          reset_search
        end
      end
    end

    # Adds a hill in the first grid in the cell the mouse is over
    def input_add_hill
      if mouse_over_grid?
        unless state.hills.key?(cell_closest_to_mouse)
          state.hills[cell_closest_to_mouse] = true
          reset_search
        end
      end
    end


    # Adds a hill in the second grid in the cell the mouse is over
    def input_add_hill2
      if mouse_over_grid2?
        unless state.hills.key?(cell_closest_to_mouse2)
          state.hills[cell_closest_to_mouse2] = true
          reset_search
        end
      end
    end

    # Adds a wall in the first grid in the cell the mouse is over
    def input_add_wall
      if mouse_over_grid?
        unless state.walls.key?(cell_closest_to_mouse)
          state.hills.delete(cell_closest_to_mouse)
          state.walls[cell_closest_to_mouse] = true
          reset_search
        end
      end
    end

    # Adds a wall in the second grid in the cell the mouse is over
    def input_add_wall2
      if mouse_over_grid2?
        unless state.walls.key?(cell_closest_to_mouse2)
          state.hills.delete(cell_closest_to_mouse2)
          state.walls[cell_closest_to_mouse2] = true
          reset_search
        end
      end
    end

    # Whenever the user edits the grid,
    # The search has to be reset_searchd upto the current step
    # with the current grid as the initial state of the grid
    def reset_search
      breadth_first_search.visited    = {}
      breadth_first_search.frontier   = []
      breadth_first_search.came_from  = {}

      dijkstra_search.frontier    = []
      dijkstra_search.came_from   = {}
      dijkstra_search.cost_so_far = {}
    end



    # Returns a list of adjacent cells
    # Used to determine what the next cells to be added to the frontier are
    def adjacent_neighbors(cell)
      neighbors = []

      # Gets all the valid neighbors into the array
      # From southern neighbor, clockwise
      neighbors << [cell.x    , cell.y - 1] unless cell.y == 0
      neighbors << [cell.x - 1, cell.y    ] unless cell.x == 0
      neighbors << [cell.x    , cell.y + 1] unless cell.y == grid.height - 1
      neighbors << [cell.x + 1, cell.y    ] unless cell.x == grid.width - 1

      # Sorts the neighbors so the rendered path is a zigzag path
      # Cells in a diagonal direction are given priority
      # Comment this line to see the difference
      neighbors = neighbors.sort_by { |neighbor_x, neighbor_y|  proximity_to_star(neighbor_x, neighbor_y) }

      neighbors
    end

    # Finds the vertical and horizontal distance of a cell from the star
    # and returns the larger value
    # This method is used to have a zigzag pattern in the rendered path
    # A cell that is [5, 5] from the star,
    # is explored before over a cell that is [0, 7] away.
    # So, if possible, the search tries to go diagonal (zigzag) first
    def proximity_to_star(x, y)
      distance_x = (state.star.x - x).abs
      distance_y = (state.star.y - y).abs

      if distance_x > distance_y
        return distance_x
      else
        return distance_y
      end
    end

    # When the user grabs the star and puts their cursor to the far right
    # and moves up and down, the star is supposed to move along the grid as well
    # Finding the cell closest to the mouse helps with this
    def cell_closest_to_mouse
      # Closest cell to the mouse in the first grid
      x = (inputs.mouse.point.x / grid.cell_size).to_i
      y = (inputs.mouse.point.y / grid.cell_size).to_i
      # Bound x and y to the grid
      x = grid.width - 1 if x > grid.width - 1
      y = grid.height - 1 if y > grid.height - 1
      # Return closest cell
      [x, y]
    end

    # When the user grabs the star and puts their cursor to the far right
    # and moves up and down, the star is supposed to move along the grid as well
    # Finding the cell closest to the mouse in the second grid helps with this
    def cell_closest_to_mouse2
      # Closest cell grid to the mouse in the second
      x = (inputs.mouse.point.x / grid.cell_size).to_i
      y = (inputs.mouse.point.y / grid.cell_size).to_i
      # Translate the cell to the first grid
      x -= grid.width + 1
      # Bound x and y to the first grid
      x = 0 if x < 0
      y = 0 if y < 0
      x = grid.width - 1 if x > grid.width - 1
      y = grid.height - 1 if y > grid.height - 1
      # Return closest cell
      [x, y]
    end

    # Signal that the user is going to be moving the star from the first grid
    def mouse_over_star?
      inputs.mouse.point.inside_rect?(scale_up(state.star))
    end

    # Signal that the user is going to be moving the star from the second grid
    def mouse_over_star2?
      inputs.mouse.point.inside_rect?(move_and_scale_up(state.star))
    end

    # Signal that the user is going to be moving the target from the first grid
    def mouse_over_target?
      inputs.mouse.point.inside_rect?(scale_up(state.target))
    end

    # Signal that the user is going to be moving the target from the second grid
    def mouse_over_target2?
      inputs.mouse.point.inside_rect?(move_and_scale_up(state.target))
    end

    # Signal that the user is going to be removing walls from the first grid
    def mouse_over_wall?
      state.walls.each_key do | wall |
        return true if inputs.mouse.point.inside_rect?(scale_up(wall))
      end

      false
    end

    # Signal that the user is going to be removing walls from the second grid
    def mouse_over_wall2?
      state.walls.each_key do | wall |
        return true if inputs.mouse.point.inside_rect?(move_and_scale_up(wall))
      end

      false
    end

    # Signal that the user is going to be removing hills from the first grid
    def mouse_over_hill?
      state.hills.each_key do | hill |
        return true if inputs.mouse.point.inside_rect?(scale_up(hill))
      end

      false
    end

    # Signal that the user is going to be removing hills from the second grid
    def mouse_over_hill2?
      state.hills.each_key do | hill |
        return true if inputs.mouse.point.inside_rect?(move_and_scale_up(hill))
      end

      false
    end

    # Signal that the user is going to be adding walls from the first grid
    def mouse_over_grid?
      inputs.mouse.point.inside_rect?(scale_up(grid.rect))
    end

    # Signal that the user is going to be adding walls from the second grid
    def mouse_over_grid2?
      inputs.mouse.point.inside_rect?(move_and_scale_up(grid.rect))
    end

    # These methods provide handy aliases to colors

    # Light brown
    def unvisited_color
      { r: 221, g: 212, b: 213 }
    end

    # Camo Green
    def wall_color
      { r: 134, g: 134, b: 120 }
    end

    # Pastel White
    def path_color
      { r: 231, g: 230, b: 228 }
    end

    def red
      { r: 255, g: 0, b: 0 }
    end

    # A Green
    def hill_color
      { r: 139, g: 173, b: 132 }
    end

    # Makes code more concise
    def grid
      state.grid
    end

    def breadth_first_search
      state.breadth_first_search
    end

    def dijkstra_search
      state.dijkstra_search
    end
  end

  # Method that is called by DragonRuby periodically
  # Used for updating animations and calculations
  def tick args

    # Pressing r will reset the application
    if args.inputs.keyboard.key_down.r
      args.gtk.reset
      reset
      return
    end

    # Every tick, new args are passed, and the Dijkstra tick method is called
    $movement_costs ||= Movement_Costs.new
    $movement_costs.args = args
    $movement_costs.tick
  end


  def reset
    $movement_costs = nil
  end

```

### Heuristic - main.rb
```ruby
  # ./samples/13_path_finding_algorithms/06_heuristic/app/main.rb
  # Contributors outside of DragonRuby who also hold Copyright:
  # - Sujay Vadlakonda: https://github.com/sujayvadlakonda

  # This program is inspired by https://www.redblobgames.com/pathfinding/a-star/introduction.html
  # The effectiveness of the Heuristic search algorithm is shown through this demonstration.
  # Notice that both searches find the shortest path
  # The heuristic search, however, explores less of the grid, and is therefore faster.
  # The heuristic search prioritizes searching cells that are closer to the target.
  # Make sure to look at the Heuristic with walls program to see some of the downsides of the heuristic algorithm.

  class Heuristic
    attr_gtk

    def tick
      defaults
      render
      input
      # If animation is playing, and max steps have not been reached
      # Move the search a step forward
      if state.play && state.current_step < state.max_steps
        # Variable that tells the program what step to recalculate up to
        state.current_step += 1
        move_searches_one_step_forward
      end
    end

    def defaults
      # Variables to edit the size and appearance of the grid
      # Freely customizable to user's liking
      grid.width     ||= 15
      grid.height    ||= 15
      grid.cell_size ||= 40
      grid.rect      ||= [0, 0, grid.width, grid.height]

      grid.star      ||= [0, 2]
      grid.target    ||= [14, 12]
      grid.walls     ||= {}
      # There are no hills in the Heuristic Search Demo

      # What the user is currently editing on the grid
      # We store this value, because we want to remember the value even when
      # the user's cursor is no longer over what they're interacting with, but
      # they are still clicking down on the mouse.
      state.user_input ||= :none

      # These variables allow the breadth first search to take place
      # Came_from is a hash with a key of a cell and a value of the cell that was expanded from to find the key.
      # Used to prevent searching cells that have already been found
      # and to trace a path from the target back to the starting point.
      # Frontier is an array of cells to expand the search from.
      # The search is over when there are no more cells to search from.
      # Path stores the path from the target to the star, once the target has been found
      # It prevents calculating the path every tick.
      bfs.came_from  ||= {}
      bfs.frontier   ||= []
      bfs.path       ||= []

      heuristic.came_from ||= {}
      heuristic.frontier  ||= []
      heuristic.path      ||= []

      # Stores which step of the animation is being rendered
      # When the user moves the star or messes with the walls,
      # the searches are recalculated up to this step
      unless state.current_step
        state.current_step = 0
      end

      # At some step the animation will end,
      # and further steps won't change anything (the whole grid will be explored)
      # This step is roughly the grid's width * height
      # When anim_steps equals max_steps no more calculations will occur
      # and the slider will be at the end
      state.max_steps = grid.width * grid.height

      # Whether the animation should play or not
      # If true, every tick moves anim_steps forward one
      # Pressing the stepwise animation buttons will pause the animation
      # An if statement instead of the ||= operator is used for assigning a boolean value.
      # The || operator does not differentiate between nil and false.
      if state.play == nil
        state.play = false
      end

      # Store the rects of the buttons that control the animation
      # They are here for user customization
      # Editing these might require recentering the text inside them
      # Those values can be found in the render_button methods
      buttons.left   = [470, 600, 50, 50]
      buttons.center = [520, 600, 200, 50]
      buttons.right  = [720, 600, 50, 50]

      # The variables below are related to the slider
      # They allow the user to customize them
      # They also give a central location for the render and input methods to get
      # information from
      # x & y are the coordinates of the leftmost part of the slider line
      slider.x = 440
      slider.y = 675
      # This is the width of the line
      slider.w = 360
      # This is the offset for the circle
      # Allows the center of the circle to be on the line,
      # as opposed to the upper right corner
      slider.offset = 20
      # This is the spacing between each of the notches on the slider
      # Notches are places where the circle can rest on the slider line
      # There needs to be a notch for each step before the maximum number of steps
      slider.spacing = slider.w.to_f / state.max_steps.to_f
    end

    # All methods with render draw stuff on the screen
    # UI has buttons, the slider, and labels
    # The search specific rendering occurs in the respective methods
    def render
      render_ui
      render_bfs
      render_heuristic
    end

    def render_ui
      render_buttons
      render_slider
      render_labels
    end

    def render_buttons
      render_left_button
      render_center_button
      render_right_button
    end

    def render_bfs
      render_bfs_grid
      render_bfs_star
      render_bfs_target
      render_bfs_visited
      render_bfs_walls
      render_bfs_frontier
      render_bfs_path
    end

    def render_heuristic
      render_heuristic_grid
      render_heuristic_star
      render_heuristic_target
      render_heuristic_visited
      render_heuristic_walls
      render_heuristic_frontier
      render_heuristic_path
    end

    # This method handles user input every tick
    def input
      # Check and handle button input
      input_buttons

      # If the mouse was lifted this tick
      if inputs.mouse.up
        # Set current input to none
        state.user_input = :none
      end

      # If the mouse was clicked this tick
      if inputs.mouse.down
        # Determine what the user is editing and appropriately edit the state.user_input variable
        determine_input
      end

      # Process user input based on user_input variable and current mouse position
      process_input
    end

    # Determines what the user is editing
    # This method is called when the mouse is clicked down
    def determine_input
      if mouse_over_slider?
        state.user_input = :slider
      # If the mouse is over the star in the first grid
      elsif bfs_mouse_over_star?
        # The user is editing the star from the first grid
        state.user_input = :bfs_star
      # If the mouse is over the star in the second grid
      elsif heuristic_mouse_over_star?
        # The user is editing the star from the second grid
        state.user_input = :heuristic_star
      # If the mouse is over the target in the first grid
      elsif bfs_mouse_over_target?
        # The user is editing the target from the first grid
        state.user_input = :bfs_target
      # If the mouse is over the target in the second grid
      elsif heuristic_mouse_over_target?
        # The user is editing the target from the second grid
        state.user_input = :heuristic_target
      # If the mouse is over a wall in the first grid
      elsif bfs_mouse_over_wall?
        # The user is removing a wall from the first grid
        state.user_input = :bfs_remove_wall
      # If the mouse is over a wall in the second grid
      elsif heuristic_mouse_over_wall?
        # The user is removing a wall from the second grid
        state.user_input = :heuristic_remove_wall
      # If the mouse is over the first grid
      elsif bfs_mouse_over_grid?
        # The user is adding a wall from the first grid
        state.user_input = :bfs_add_wall
      # If the mouse is over the second grid
      elsif heuristic_mouse_over_grid?
        # The user is adding a wall from the second grid
        state.user_input = :heuristic_add_wall
      end
    end

    # Processes click and drag based on what the user is currently dragging
    def process_input
      if state.user_input == :slider
        process_input_slider
      elsif state.user_input == :bfs_star
        process_input_bfs_star
      elsif state.user_input == :heuristic_star
        process_input_heuristic_star
      elsif state.user_input == :bfs_target
        process_input_bfs_target
      elsif state.user_input == :heuristic_target
        process_input_heuristic_target
      elsif state.user_input == :bfs_remove_wall
        process_input_bfs_remove_wall
      elsif state.user_input == :heuristic_remove_wall
        process_input_heuristic_remove_wall
      elsif state.user_input == :bfs_add_wall
        process_input_bfs_add_wall
      elsif state.user_input == :heuristic_add_wall
        process_input_heuristic_add_wall
      end
    end

    def render_slider
      # Using primitives hides the line under the white circle of the slider
      # Draws the line
      outputs.primitives << [slider.x, slider.y, slider.x + slider.w, slider.y].line
      # The circle needs to be offset so that the center of the circle
      # overlaps the line instead of the upper right corner of the circle
      # The circle's x value is also moved based on the current seach step
      circle_x = (slider.x - slider.offset) + (state.current_step * slider.spacing)
      circle_y = (slider.y - slider.offset)
      circle_rect = [circle_x, circle_y, 37, 37]
      outputs.primitives << [circle_rect, 'circle-white.png'].sprite
    end

    def render_labels
      outputs.labels << [205, 625, "Breadth First Search"]
      outputs.labels << [820, 625, "Heuristic Best-First Search"]
    end

    def render_left_button
      # Draws the button_color button, and a black border
      # The border separates the buttons visually
      outputs.solids  << [buttons.left, button_color]
      outputs.borders << [buttons.left]

      # Renders an explanatory label in the center of the button
      # Explains to the user what the button does
      # If the button size is changed, the label might need to be edited as well
      # to keep the label in the center of the button
      label_x = buttons.left.x + 20
      label_y = buttons.left.y + 35
      outputs.labels  << [label_x, label_y, "<"]
    end

    def render_center_button
      # Draws the button_color button, and a black border
      # The border separates the buttons visually
      outputs.solids  << [buttons.center, button_color]
      outputs.borders << [buttons.center]

      # Renders an explanatory label in the center of the button
      # Explains to the user what the button does
      # If the button size is changed, the label might need to be edited as well
      # to keep the label in the center of the button
      label_x    = buttons.center.x + 37
      label_y    = buttons.center.y + 35
      label_text = state.play ? "Pause Animation" : "Play Animation"
      outputs.labels << [label_x, label_y, label_text]
    end

    def render_right_button
      # Draws the button_color button, and a black border
      # The border separates the buttons visually
      outputs.solids  << [buttons.right, button_color]
      outputs.borders << [buttons.right]

      # Renders an explanatory label in the center of the button
      # Explains to the user what the button does
      label_x = buttons.right.x + 20
      label_y = buttons.right.y + 35
      outputs.labels  << [label_x, label_y, ">"]
    end

    def render_bfs_grid
      # A large rect the size of the grid
      outputs.solids << bfs_scale_up(grid.rect).merge(default_color)

      outputs.lines << (0..grid.width).map { |x| bfs_vertical_line(x) }
      outputs.lines << (0..grid.height).map { |y| bfs_horizontal_line(y) }
    end

    def render_heuristic_grid
      # A large rect the size of the grid
      outputs.solids << heuristic_scale_up(grid.rect).merge(default_color)

      outputs.lines << (0..grid.width).map { |x| heuristic_vertical_line(x) }
      outputs.lines << (0..grid.height).map { |y| heuristic_horizontal_line(y) }
    end

    # Returns a vertical line for a column of the first grid
    def bfs_vertical_line x
      line = { x: x, y: 0, w: 0, h: grid.height }
      line.transform_values { |v| v * grid.cell_size }
    end

    # Returns a horizontal line for a column of the first grid
    def bfs_horizontal_line y
      line = { x: 0, y: y, w: grid.width, h: 0 }
      line.transform_values { |v| v * grid.cell_size }
    end

    # Returns a vertical line for a column of the second grid
    def heuristic_vertical_line x
      bfs_vertical_line(x + grid.width + 1)
    end

    # Returns a horizontal line for a column of the second grid
    def heuristic_horizontal_line y
      line = { x: grid.width + 1, y: y, w: grid.width, h: 0 }
      line.transform_values { |v| v * grid.cell_size }
    end

    # Renders the star on the first grid
    def render_bfs_star
      outputs.sprites << bfs_scale_up(grid.star).merge({ path: 'star.png' })
    end

    # Renders the star on the second grid
    def render_heuristic_star
      outputs.sprites << heuristic_scale_up(grid.star).merge({ path: 'star.png' })
    end

    # Renders the target on the first grid
    def render_bfs_target
      outputs.sprites << bfs_scale_up(grid.target).merge({ path: 'target.png' })
    end

    # Renders the target on the second grid
    def render_heuristic_target
      outputs.sprites << heuristic_scale_up(grid.target).merge({ path: 'target.png' })
    end

    # Renders the walls on the first grid
    def render_bfs_walls
      outputs.solids << grid.walls.map do |key, value|
        bfs_scale_up(key).merge(wall_color)
      end
    end

    # Renders the walls on the second grid
    def render_heuristic_walls
      outputs.solids << grid.walls.map do |key, value|
        heuristic_scale_up(key).merge(wall_color)
      end
    end

    # Renders the visited cells on the first grid
    def render_bfs_visited
      outputs.solids << bfs.came_from.map do |key, value|
        bfs_scale_up(key).merge(visited_color)
      end
    end

    # Renders the visited cells on the second grid
    def render_heuristic_visited
      outputs.solids << heuristic.came_from.map do |key, value|
        heuristic_scale_up(key).merge(visited_color)
      end
    end

    # Renders the frontier cells on the first grid
    def render_bfs_frontier
      outputs.solids << bfs.frontier.map do |cell|
        bfs_scale_up(cell).merge(frontier_color)
      end
    end

    # Renders the frontier cells on the second grid
    def render_heuristic_frontier
      outputs.solids << heuristic.frontier.map do |cell|
        heuristic_scale_up(cell).merge(frontier_color)
      end
    end

    # Renders the path found by the breadth first search on the first grid
    def render_bfs_path
      outputs.solids << bfs.path.map do |path|
        bfs_scale_up(path).merge(path_color)
      end
    end

    # Renders the path found by the heuristic search on the second grid
    def render_heuristic_path
      outputs.solids << heuristic.path.map do |path|
        heuristic_scale_up(path).merge(path_color)
      end
    end

    # Returns the rect for the path between two cells based on their relative positions
    def get_path_between(cell_one, cell_two)
      path = nil

      # If cell one is above cell two
      if cell_one.x == cell_two.x && cell_one.y > cell_two.y
        # Path starts from the center of cell two and moves upward to the center of cell one
        path = [cell_two.x + 0.3, cell_two.y + 0.3, 0.4, 1.4]
      # If cell one is below cell two
      elsif cell_one.x == cell_two.x && cell_one.y < cell_two.y
        # Path starts from the center of cell one and moves upward to the center of cell two
        path = [cell_one.x + 0.3, cell_one.y + 0.3, 0.4, 1.4]
      # If cell one is to the left of cell two
      elsif cell_one.x > cell_two.x && cell_one.y == cell_two.y
        # Path starts from the center of cell two and moves rightward to the center of cell one
        path = [cell_two.x + 0.3, cell_two.y + 0.3, 1.4, 0.4]
      # If cell one is to the right of cell two
      elsif cell_one.x < cell_two.x && cell_one.y == cell_two.y
        # Path starts from the center of cell one and moves rightward to the center of cell two
        path = [cell_one.x + 0.3, cell_one.y + 0.3, 1.4, 0.4]
      end

      path
    end

    # In code, the cells are represented as 1x1 rectangles
    # When drawn, the cells are larger than 1x1 rectangles
    # This method is used to scale up cells, and lines
    # Objects are scaled up according to the grid.cell_size variable
    # This allows for easy customization of the visual scale of the grid
    # This method scales up cells for the first grid
    def bfs_scale_up(cell)
      x = cell.x * grid.cell_size
      y = cell.y * grid.cell_size
      w = cell.w.zero? ? grid.cell_size : cell.w * grid.cell_size
      h = cell.h.zero? ? grid.cell_size : cell.h * grid.cell_size
      {x: x, y: y, w: w, h: h}
      # {x:, y:, w:, h:}
    end

    # Translates the given cell grid.width + 1 to the right and then scales up
    # Used to draw cells for the second grid
    # This method does not work for lines,
    # so separate methods exist for the grid lines
    def heuristic_scale_up(cell)
      # Prevents the original value of cell from being edited
      cell = cell.clone
      # Translates the cell to the second grid equivalent
      cell.x += grid.width + 1
      # Proceeds as if scaling up for the first grid
      bfs_scale_up(cell)
    end

    # Checks and handles input for the buttons
    # Called when the mouse is lifted
    def input_buttons
      input_left_button
      input_center_button
      input_right_button
    end

    # Checks if the previous step button is clicked
    # If it is, it pauses the animation and moves the search one step backward
    def input_left_button
      if left_button_clicked?
        state.play = false
        state.current_step -= 1
        recalculate_searches
      end
    end

    # Controls the play/pause button
    # Inverses whether the animation is playing or not when clicked
    def input_center_button
      if center_button_clicked? || inputs.keyboard.key_down.space
        state.play = !state.play
      end
    end

    # Checks if the next step button is clicked
    # If it is, it pauses the animation and moves the search one step forward
    def input_right_button
      if right_button_clicked?
        state.play = false
        state.current_step += 1
        move_searches_one_step_forward
      end
    end

    # These methods detect when the buttons are clicked
    def left_button_clicked?
      inputs.mouse.point.inside_rect?(buttons.left) && inputs.mouse.up
    end

    def center_button_clicked?
      inputs.mouse.point.inside_rect?(buttons.center) && inputs.mouse.up
    end

    def right_button_clicked?
      inputs.mouse.point.inside_rect?(buttons.right) && inputs.mouse.up
    end


    # Signal that the user is going to be moving the slider
    # Is the mouse over the circle of the slider?
    def mouse_over_slider?
      circle_x = (slider.x - slider.offset) + (state.current_step * slider.spacing)
      circle_y = (slider.y - slider.offset)
      circle_rect = [circle_x, circle_y, 37, 37]
      inputs.mouse.point.inside_rect?(circle_rect)
    end

    # Signal that the user is going to be moving the star from the first grid
    def bfs_mouse_over_star?
      inputs.mouse.point.inside_rect?(bfs_scale_up(grid.star))
    end

    # Signal that the user is going to be moving the star from the second grid
    def heuristic_mouse_over_star?
      inputs.mouse.point.inside_rect?(heuristic_scale_up(grid.star))
    end

    # Signal that the user is going to be moving the target from the first grid
    def bfs_mouse_over_target?
      inputs.mouse.point.inside_rect?(bfs_scale_up(grid.target))
    end

    # Signal that the user is going to be moving the target from the second grid
    def heuristic_mouse_over_target?
      inputs.mouse.point.inside_rect?(heuristic_scale_up(grid.target))
    end

    # Signal that the user is going to be removing walls from the first grid
    def bfs_mouse_over_wall?
      grid.walls.each_key do |wall|
        return true if inputs.mouse.point.inside_rect?(bfs_scale_up(wall))
      end

      false
    end

    # Signal that the user is going to be removing walls from the second grid
    def heuristic_mouse_over_wall?
      grid.walls.each_key do |wall|
        return true if inputs.mouse.point.inside_rect?(heuristic_scale_up(wall))
      end

      false
    end

    # Signal that the user is going to be adding walls from the first grid
    def bfs_mouse_over_grid?
      inputs.mouse.point.inside_rect?(bfs_scale_up(grid.rect))
    end

    # Signal that the user is going to be adding walls from the second grid
    def heuristic_mouse_over_grid?
      inputs.mouse.point.inside_rect?(heuristic_scale_up(grid.rect))
    end

    # This method is called when the user is editing the slider
    # It pauses the animation and moves the white circle to the closest integer point
    # on the slider
    # Changes the step of the search to be animated
    def process_input_slider
      state.play = false
      mouse_x = inputs.mouse.point.x

      # Bounds the mouse_x to the closest x value on the slider line
      mouse_x = slider.x if mouse_x < slider.x
      mouse_x = slider.x + slider.w if mouse_x > slider.x + slider.w

      # Sets the current search step to the one represented by the mouse x value
      # The slider's circle moves due to the render_slider method using anim_steps
      state.current_step = ((mouse_x - slider.x) / slider.spacing).to_i

      recalculate_searches
    end

    # Moves the star to the cell closest to the mouse in the first grid
    # Only resets the search if the star changes position
    # Called whenever the user is editing the star (puts mouse down on star)
    def process_input_bfs_star
      old_star = grid.star.clone
      unless bfs_cell_closest_to_mouse == grid.target
        grid.star = bfs_cell_closest_to_mouse
      end
      unless old_star == grid.star
        recalculate_searches
      end
    end

    # Moves the star to the cell closest to the mouse in the second grid
    # Only resets the search if the star changes position
    # Called whenever the user is editing the star (puts mouse down on star)
    def process_input_heuristic_star
      old_star = grid.star.clone
      unless heuristic_cell_closest_to_mouse == grid.target
        grid.star = heuristic_cell_closest_to_mouse
      end
      unless old_star == grid.star
        recalculate_searches
      end
    end

    # Moves the target to the grid closest to the mouse in the first grid
    # Only recalculate_searchess the search if the target changes position
    # Called whenever the user is editing the target (puts mouse down on target)
    def process_input_bfs_target
      old_target = grid.target.clone
      unless bfs_cell_closest_to_mouse == grid.star
        grid.target = bfs_cell_closest_to_mouse
      end
      unless old_target == grid.target
        recalculate_searches
      end
    end

    # Moves the target to the cell closest to the mouse in the second grid
    # Only recalculate_searchess the search if the target changes position
    # Called whenever the user is editing the target (puts mouse down on target)
    def process_input_heuristic_target
      old_target = grid.target.clone
      unless heuristic_cell_closest_to_mouse == grid.star
        grid.target = heuristic_cell_closest_to_mouse
      end
      unless old_target == grid.target
        recalculate_searches
      end
    end

    # Removes walls in the first grid that are under the cursor
    def process_input_bfs_remove_wall
      # The mouse needs to be inside the grid, because we only want to remove walls
      # the cursor is directly over
      # Recalculations should only occur when a wall is actually deleted
      if bfs_mouse_over_grid?
        if grid.walls.key?(bfs_cell_closest_to_mouse)
          grid.walls.delete(bfs_cell_closest_to_mouse)
          recalculate_searches
        end
      end
    end

    # Removes walls in the second grid that are under the cursor
    def process_input_heuristic_remove_wall
      # The mouse needs to be inside the grid, because we only want to remove walls
      # the cursor is directly over
      # Recalculations should only occur when a wall is actually deleted
      if heuristic_mouse_over_grid?
        if grid.walls.key?(heuristic_cell_closest_to_mouse)
          grid.walls.delete(heuristic_cell_closest_to_mouse)
          recalculate_searches
        end
      end
    end
    # Adds a wall in the first grid in the cell the mouse is over
    def process_input_bfs_add_wall
      if bfs_mouse_over_grid?
        unless grid.walls.key?(bfs_cell_closest_to_mouse)
          grid.walls[bfs_cell_closest_to_mouse] = true
          recalculate_searches
        end
      end
    end

    # Adds a wall in the second grid in the cell the mouse is over
    def process_input_heuristic_add_wall
      if heuristic_mouse_over_grid?
        unless grid.walls.key?(heuristic_cell_closest_to_mouse)
          grid.walls[heuristic_cell_closest_to_mouse] = true
          recalculate_searches
        end
      end
    end

    # When the user grabs the star and puts their cursor to the far right
    # and moves up and down, the star is supposed to move along the grid as well
    # Finding the cell closest to the mouse helps with this
    def bfs_cell_closest_to_mouse
      # Closest cell to the mouse in the first grid
      x = (inputs.mouse.point.x / grid.cell_size).to_i
      y = (inputs.mouse.point.y / grid.cell_size).to_i
      # Bound x and y to the grid
      x = grid.width - 1 if x > grid.width - 1
      y = grid.height - 1 if y > grid.height - 1
      # Return closest cell
      [x, y]
    end

    # When the user grabs the star and puts their cursor to the far right
    # and moves up and down, the star is supposed to move along the grid as well
    # Finding the cell closest to the mouse in the second grid helps with this
    def heuristic_cell_closest_to_mouse
      # Closest cell grid to the mouse in the second
      x = (inputs.mouse.point.x / grid.cell_size).to_i
      y = (inputs.mouse.point.y / grid.cell_size).to_i
      # Translate the cell to the first grid
      x -= grid.width + 1
      # Bound x and y to the first grid
      x = 0 if x < 0
      y = 0 if y < 0
      x = grid.width - 1 if x > grid.width - 1
      y = grid.height - 1 if y > grid.height - 1
      # Return closest cell
      [x, y]
    end

    def recalculate_searches
      # Reset the searches
      bfs.came_from    = {}
      bfs.frontier     = []
      bfs.path         = []
      heuristic.came_from = {}
      heuristic.frontier  = []
      heuristic.path      = []

      # Move the searches forward to the current step
      state.current_step.times { move_searches_one_step_forward }
    end

    def move_searches_one_step_forward
      bfs_one_step_forward
      heuristic_one_step_forward
    end

    def bfs_one_step_forward
      return if bfs.came_from.key?(grid.target)

      # Only runs at the beginning of the search as setup.
      if bfs.came_from.empty?
        bfs.frontier << grid.star
        bfs.came_from[grid.star] = nil
      end

      # A step in the search
      unless bfs.frontier.empty?
        # Takes the next frontier cell
        new_frontier = bfs.frontier.shift
        # For each of its neighbors
        adjacent_neighbors(new_frontier).each do |neighbor|
          # That have not been visited and are not walls
          unless bfs.came_from.key?(neighbor) || grid.walls.key?(neighbor)
            # Add them to the frontier and mark them as visited
            bfs.frontier << neighbor
            bfs.came_from[neighbor] = new_frontier
          end
        end
      end

      # Sort the frontier so that cells that are in a zigzag pattern are prioritized over those in an line
      # Comment this line and let a path generate to see the difference
      bfs.frontier = bfs.frontier.sort_by { |cell| proximity_to_star(cell) }

      # If the search found the target
      if bfs.came_from.key?(grid.target)
        # Calculate the path between the target and star
        bfs_calc_path
      end
    end

    # Calculates the path between the target and star for the breadth first search
    # Only called when the breadth first search finds the target
    def bfs_calc_path
      # Start from the target
      endpoint = grid.target
      # And the cell it came from
      next_endpoint = bfs.came_from[endpoint]
      while endpoint && next_endpoint
        # Draw a path between these two cells and store it
        path = get_path_between(endpoint, next_endpoint)
        bfs.path << path
        # And get the next pair of cells
        endpoint = next_endpoint
        next_endpoint = bfs.came_from[endpoint]
        # Continue till there are no more cells
      end
    end

    # Moves the heuristic search forward one step
    # Can be called from tick while the animation is playing
    # Can also be called when recalculating the searches after the user edited the grid
    def heuristic_one_step_forward
      # Stop the search if the target has been found
      return if heuristic.came_from.key?(grid.target)

      # If the search has not begun
      if heuristic.came_from.empty?
        # Setup the search to begin from the star
        heuristic.frontier << grid.star
        heuristic.came_from[grid.star] = nil
      end

      # One step in the heuristic search

      # Unless there are no more cells to explore from
      unless heuristic.frontier.empty?
        # Get the next cell to explore from
        new_frontier = heuristic.frontier.shift
        # For each of its neighbors
        adjacent_neighbors(new_frontier).each do |neighbor|
          # That have not been visited and are not walls
          unless heuristic.came_from.key?(neighbor) || grid.walls.key?(neighbor)
            # Add them to the frontier and mark them as visited
            heuristic.frontier << neighbor
            heuristic.came_from[neighbor] = new_frontier
          end
        end
      end

      # Sort the frontier so that cells that are in a zigzag pattern are prioritized over those in an line
      heuristic.frontier = heuristic.frontier.sort_by { |cell| proximity_to_star(cell) }
      # Sort the frontier so cells that are close to the target are then prioritized
      heuristic.frontier = heuristic.frontier.sort_by { |cell| heuristic_heuristic(cell) }

      # If the search found the target
      if heuristic.came_from.key?(grid.target)
        # Calculate the path between the target and star
        heuristic_calc_path
      end
    end

    # Returns one-dimensional absolute distance between cell and target
    # Returns a number to compare distances between cells and the target
    def heuristic_heuristic(cell)
      (grid.target.x - cell.x).abs + (grid.target.y - cell.y).abs
    end

    # Calculates the path between the target and star for the heuristic search
    # Only called when the heuristic search finds the target
    def heuristic_calc_path
      # Start from the target
      endpoint = grid.target
      # And the cell it came from
      next_endpoint = heuristic.came_from[endpoint]
      while endpoint && next_endpoint
        # Draw a path between these two cells and store it
        path = get_path_between(endpoint, next_endpoint)
        heuristic.path << path
        # And get the next pair of cells
        endpoint = next_endpoint
        next_endpoint = heuristic.came_from[endpoint]
        # Continue till there are no more cells
      end
    end

    # Returns a list of adjacent cells
    # Used to determine what the next cells to be added to the frontier are
    def adjacent_neighbors(cell)
      neighbors = []

      # Gets all the valid neighbors into the array
      # From southern neighbor, clockwise
      neighbors << [cell.x    , cell.y - 1] unless cell.y == 0
      neighbors << [cell.x - 1, cell.y    ] unless cell.x == 0
      neighbors << [cell.x    , cell.y + 1] unless cell.y == grid.height - 1
      neighbors << [cell.x + 1, cell.y    ] unless cell.x == grid.width - 1

      neighbors
    end

    # Finds the vertical and horizontal distance of a cell from the star
    # and returns the larger value
    # This method is used to have a zigzag pattern in the rendered path
    # A cell that is [5, 5] from the star,
    # is explored before over a cell that is [0, 7] away.
    # So, if possible, the search tries to go diagonal (zigzag) first
    def proximity_to_star(cell)
      distance_x = (grid.star.x - cell.x).abs
      distance_y = (grid.star.y - cell.y).abs

      [distance_x, distance_y].max
    end

    # Methods that allow code to be more concise. Subdivides args.state, which is where all variables are stored.
    def grid
      state.grid
    end

    def buttons
      state.buttons
    end

    def slider
      state.slider
    end

    def bfs
      state.bfs
    end

    def heuristic
      state.heuristic
    end

    # Descriptive aliases for colors
    def default_color
      { r: 221, g: 212, b: 213 }
    end

    def wall_color
      { r: 134, g: 134, b: 120 }
    end

    def visited_color
      { r: 204, g: 191, b: 179 }
    end

    def frontier_color
      { r: 103, g: 136, b: 204, a: 200 }
    end

    def path_color
      { r: 231, g: 230, b: 228 }
    end

    def button_color
      [190, 190, 190] # Gray
    end
  end
  # Method that is called by DragonRuby periodically
  # Used for updating animations and calculations
  def tick args

    # Pressing r will reset the application
    if args.inputs.keyboard.key_down.r
      args.gtk.reset
      reset
      return
    end

    # Every tick, new args are passed, and the Breadth First Search tick is called
    $heuristic ||= Heuristic.new
    $heuristic.args = args
    $heuristic.tick
  end


  def reset
    $heuristic = nil
  end

```

### Heuristic With Walls - main.rb
```ruby
  # ./samples/13_path_finding_algorithms/07_heuristic_with_walls/app/main.rb
  # Contributors outside of DragonRuby who also hold Copyright:
  # - Sujay Vadlakonda: https://github.com/sujayvadlakonda

  # This program is inspired by https://www.redblobgames.com/pathfinding/a-star/introduction.html

  # This time the heuristic search still explored less of the grid, hence finishing faster.
  # However, it did not find the shortest path between the star and the target.

  # The only difference between this app and Heuristic is the change of the starting position.

  class Heuristic_With_Walls
    attr_gtk

    def tick
      defaults
      render
      input
      # If animation is playing, and max steps have not been reached
      # Move the search a step forward
      if state.play && state.current_step < state.max_steps
        # Variable that tells the program what step to recalculate up to
        state.current_step += 1
        move_searches_one_step_forward
      end
    end

    def defaults
      # Variables to edit the size and appearance of the grid
      # Freely customizable to user's liking
      grid.width     ||= 15
      grid.height    ||= 15
      grid.cell_size ||= 40
      grid.rect      ||= [0, 0, grid.width, grid.height]

      grid.star      ||= [0, 2]
      grid.target    ||= [14, 12]
      grid.walls     ||= {
        [2, 2] => true,
        [3, 2] => true,
        [4, 2] => true,
        [5, 2] => true,
        [6, 2] => true,
        [7, 2] => true,
        [8, 2] => true,
        [9, 2] => true,
        [10, 2] => true,
        [11, 2] => true,
        [12, 2] => true,
        [12, 3] => true,
        [12, 4] => true,
        [12, 5] => true,
        [12, 6] => true,
        [12, 7] => true,
        [12, 8] => true,
        [12, 9] => true,
        [12, 10] => true,
        [12, 11] => true,
        [12, 12] => true,
        [2, 12] => true,
        [3, 12] => true,
        [4, 12] => true,
        [5, 12] => true,
        [6, 12] => true,
        [7, 12] => true,
        [8, 12] => true,
        [9, 12] => true,
        [10, 12] => true,
        [11, 12] => true,
        [12, 12] => true
      }
      # There are no hills in the Heuristic Search Demo

      # What the user is currently editing on the grid
      # We store this value, because we want to remember the value even when
      # the user's cursor is no longer over what they're interacting with, but
      # they are still clicking down on the mouse.
      state.user_input ||= :none

      # These variables allow the breadth first search to take place
      # Came_from is a hash with a key of a cell and a value of the cell that was expanded from to find the key.
      # Used to prevent searching cells that have already been found
      # and to trace a path from the target back to the starting point.
      # Frontier is an array of cells to expand the search from.
      # The search is over when there are no more cells to search from.
      # Path stores the path from the target to the star, once the target has been found
      # It prevents calculating the path every tick.
      bfs.came_from  ||= {}
      bfs.frontier   ||= []
      bfs.path       ||= []

      heuristic.came_from ||= {}
      heuristic.frontier  ||= []
      heuristic.path      ||= []

      # Stores which step of the animation is being rendered
      # When the user moves the star or messes with the walls,
      # the searches are recalculated up to this step
      unless state.current_step
        state.current_step = 0
      end

      # At some step the animation will end,
      # and further steps won't change anything (the whole grid will be explored)
      # This step is roughly the grid's width * height
      # When anim_steps equals max_steps no more calculations will occur
      # and the slider will be at the end
      state.max_steps = grid.width * grid.height

      # Whether the animation should play or not
      # If true, every tick moves anim_steps forward one
      # Pressing the stepwise animation buttons will pause the animation
      # An if statement instead of the ||= operator is used for assigning a boolean value.
      # The || operator does not differentiate between nil and false.
      if state.play == nil
        state.play = false
      end

      # Store the rects of the buttons that control the animation
      # They are here for user customization
      # Editing these might require recentering the text inside them
      # Those values can be found in the render_button methods
      buttons.left   = [470, 600, 50, 50]
      buttons.center = [520, 600, 200, 50]
      buttons.right  = [720, 600, 50, 50]

      # The variables below are related to the slider
      # They allow the user to customize them
      # They also give a central location for the render and input methods to get
      # information from
      # x & y are the coordinates of the leftmost part of the slider line
      slider.x = 440
      slider.y = 675
      # This is the width of the line
      slider.w = 360
      # This is the offset for the circle
      # Allows the center of the circle to be on the line,
      # as opposed to the upper right corner
      slider.offset = 20
      # This is the spacing between each of the notches on the slider
      # Notches are places where the circle can rest on the slider line
      # There needs to be a notch for each step before the maximum number of steps
      slider.spacing = slider.w.to_f / state.max_steps.to_f
    end

    # All methods with render draw stuff on the screen
    # UI has buttons, the slider, and labels
    # The search specific rendering occurs in the respective methods
    def render
      render_ui
      render_bfs
      render_heuristic
    end

    def render_ui
      render_buttons
      render_slider
      render_labels
    end

    def render_buttons
      render_left_button
      render_center_button
      render_right_button
    end

    def render_bfs
      render_bfs_grid
      render_bfs_star
      render_bfs_target
      render_bfs_visited
      render_bfs_walls
      render_bfs_frontier
      render_bfs_path
    end

    def render_heuristic
      render_heuristic_grid
      render_heuristic_star
      render_heuristic_target
      render_heuristic_visited
      render_heuristic_walls
      render_heuristic_frontier
      render_heuristic_path
    end

    # This method handles user input every tick
    def input
      # Check and handle button input
      input_buttons

      # If the mouse was lifted this tick
      if inputs.mouse.up
        # Set current input to none
        state.user_input = :none
      end

      # If the mouse was clicked this tick
      if inputs.mouse.down
        # Determine what the user is editing and appropriately edit the state.user_input variable
        determine_input
      end

      # Process user input based on user_input variable and current mouse position
      process_input
    end

    # Determines what the user is editing
    # This method is called when the mouse is clicked down
    def determine_input
      if mouse_over_slider?
        state.user_input = :slider
      # If the mouse is over the star in the first grid
      elsif bfs_mouse_over_star?
        # The user is editing the star from the first grid
        state.user_input = :bfs_star
      # If the mouse is over the star in the second grid
      elsif heuristic_mouse_over_star?
        # The user is editing the star from the second grid
        state.user_input = :heuristic_star
      # If the mouse is over the target in the first grid
      elsif bfs_mouse_over_target?
        # The user is editing the target from the first grid
        state.user_input = :bfs_target
      # If the mouse is over the target in the second grid
      elsif heuristic_mouse_over_target?
        # The user is editing the target from the second grid
        state.user_input = :heuristic_target
      # If the mouse is over a wall in the first grid
      elsif bfs_mouse_over_wall?
        # The user is removing a wall from the first grid
        state.user_input = :bfs_remove_wall
      # If the mouse is over a wall in the second grid
      elsif heuristic_mouse_over_wall?
        # The user is removing a wall from the second grid
        state.user_input = :heuristic_remove_wall
      # If the mouse is over the first grid
      elsif bfs_mouse_over_grid?
        # The user is adding a wall from the first grid
        state.user_input = :bfs_add_wall
      # If the mouse is over the second grid
      elsif heuristic_mouse_over_grid?
        # The user is adding a wall from the second grid
        state.user_input = :heuristic_add_wall
      end
    end

    # Processes click and drag based on what the user is currently dragging
    def process_input
      if state.user_input == :slider
        process_input_slider
      elsif state.user_input == :bfs_star
        process_input_bfs_star
      elsif state.user_input == :heuristic_star
        process_input_heuristic_star
      elsif state.user_input == :bfs_target
        process_input_bfs_target
      elsif state.user_input == :heuristic_target
        process_input_heuristic_target
      elsif state.user_input == :bfs_remove_wall
        process_input_bfs_remove_wall
      elsif state.user_input == :heuristic_remove_wall
        process_input_heuristic_remove_wall
      elsif state.user_input == :bfs_add_wall
        process_input_bfs_add_wall
      elsif state.user_input == :heuristic_add_wall
        process_input_heuristic_add_wall
      end
    end

    def render_slider
      # Using primitives hides the line under the white circle of the slider
      # Draws the line
      outputs.primitives << [slider.x, slider.y, slider.x + slider.w, slider.y].line
      # The circle needs to be offset so that the center of the circle
      # overlaps the line instead of the upper right corner of the circle
      # The circle's x value is also moved based on the current seach step
      circle_x = (slider.x - slider.offset) + (state.current_step * slider.spacing)
      circle_y = (slider.y - slider.offset)
      circle_rect = [circle_x, circle_y, 37, 37]
      outputs.primitives << [circle_rect, 'circle-white.png'].sprite
    end

    def render_labels
      outputs.labels << [205, 625, "Breadth First Search"]
      outputs.labels << [820, 625, "Heuristic Best-First Search"]
    end

    def render_left_button
      # Draws the button_color button, and a black border
      # The border separates the buttons visually
      outputs.solids  << [buttons.left, button_color]
      outputs.borders << [buttons.left]

      # Renders an explanatory label in the center of the button
      # Explains to the user what the button does
      # If the button size is changed, the label might need to be edited as well
      # to keep the label in the center of the button
      label_x = buttons.left.x + 20
      label_y = buttons.left.y + 35
      outputs.labels  << [label_x, label_y, "<"]
    end

    def render_center_button
      # Draws the button_color button, and a black border
      # The border separates the buttons visually
      outputs.solids  << [buttons.center, button_color]
      outputs.borders << [buttons.center]

      # Renders an explanatory label in the center of the button
      # Explains to the user what the button does
      # If the button size is changed, the label might need to be edited as well
      # to keep the label in the center of the button
      label_x    = buttons.center.x + 37
      label_y    = buttons.center.y + 35
      label_text = state.play ? "Pause Animation" : "Play Animation"
      outputs.labels << [label_x, label_y, label_text]
    end

    def render_right_button
      # Draws the button_color button, and a black border
      # The border separates the buttons visually
      outputs.solids  << [buttons.right, button_color]
      outputs.borders << [buttons.right]

      # Renders an explanatory label in the center of the button
      # Explains to the user what the button does
      label_x = buttons.right.x + 20
      label_y = buttons.right.y + 35
      outputs.labels  << [label_x, label_y, ">"]
    end

    def render_bfs_grid
      # A large rect the size of the grid
      outputs.solids << bfs_scale_up(grid.rect).merge(default_color)

      outputs.lines << (0..grid.width).map { |x| bfs_vertical_line(x) }
      outputs.lines << (0..grid.height).map { |y| bfs_horizontal_line(y) }
    end

    def render_heuristic_grid
      # A large rect the size of the grid
      outputs.solids << heuristic_scale_up(grid.rect).merge(default_color)

      outputs.lines << (0..grid.width).map { |x| heuristic_vertical_line(x) }
      outputs.lines << (0..grid.height).map { |y| heuristic_horizontal_line(y) }
    end

    # Returns a vertical line for a column of the first grid
    def bfs_vertical_line x
      line = { x: x, y: 0, w: 0, h: grid.height }
      line.transform_values { |v| v * grid.cell_size }
    end

    # Returns a horizontal line for a column of the first grid
    def bfs_horizontal_line y
      line = { x: 0, y: y, w: grid.width, h: 0 }
      line.transform_values { |v| v * grid.cell_size }
    end

    # Returns a vertical line for a column of the second grid
    def heuristic_vertical_line x
      bfs_vertical_line(x + grid.width + 1)
    end

    # Returns a horizontal line for a column of the second grid
    def heuristic_horizontal_line y
      line = { x: grid.width + 1, y: y, w: grid.width, h: 0 }
      line.transform_values { |v| v * grid.cell_size }
    end

    # Renders the star on the first grid
    def render_bfs_star
      outputs.sprites << bfs_scale_up(grid.star).merge({ path: 'star.png' })
    end

    # Renders the star on the second grid
    def render_heuristic_star
      outputs.sprites << heuristic_scale_up(grid.star).merge({ path: 'star.png' })
    end

    # Renders the target on the first grid
    def render_bfs_target
      outputs.sprites << bfs_scale_up(grid.target).merge({ path: 'target.png' })
    end

    # Renders the target on the second grid
    def render_heuristic_target
      outputs.sprites << heuristic_scale_up(grid.target).merge({ path: 'target.png' })
    end

    # Renders the walls on the first grid
    def render_bfs_walls
      outputs.solids << grid.walls.map do |key, value|
        bfs_scale_up(key).merge(wall_color)
      end
    end

    # Renders the walls on the second grid
    def render_heuristic_walls
      outputs.solids << grid.walls.map do |key, value|
        heuristic_scale_up(key).merge(wall_color)
      end
    end

    # Renders the visited cells on the first grid
    def render_bfs_visited
      outputs.solids << bfs.came_from.map do |key, value|
        bfs_scale_up(key).merge(visited_color)
      end
    end

    # Renders the visited cells on the second grid
    def render_heuristic_visited
      outputs.solids << heuristic.came_from.map do |key, value|
        heuristic_scale_up(key).merge(visited_color)
      end
    end

    # Renders the frontier cells on the first grid
    def render_bfs_frontier
      outputs.solids << bfs.frontier.map do |cell|
        bfs_scale_up(cell).merge(frontier_color)
      end
    end

    # Renders the frontier cells on the second grid
    def render_heuristic_frontier
      outputs.solids << heuristic.frontier.map do |cell|
        heuristic_scale_up(cell).merge(frontier_color)
      end
    end

    # Renders the path found by the breadth first search on the first grid
    def render_bfs_path
      outputs.solids << bfs.path.map do |path|
        bfs_scale_up(path).merge(path_color)
      end
    end

    # Renders the path found by the heuristic search on the second grid
    def render_heuristic_path
      outputs.solids << heuristic.path.map do |path|
        heuristic_scale_up(path).merge(path_color)
      end
    end

    # Returns the rect for the path between two cells based on their relative positions
    def get_path_between(cell_one, cell_two)
      path = nil

      # If cell one is above cell two
      if cell_one.x == cell_two.x && cell_one.y > cell_two.y
        # Path starts from the center of cell two and moves upward to the center of cell one
        path = [cell_two.x + 0.3, cell_two.y + 0.3, 0.4, 1.4]
      # If cell one is below cell two
      elsif cell_one.x == cell_two.x && cell_one.y < cell_two.y
        # Path starts from the center of cell one and moves upward to the center of cell two
        path = [cell_one.x + 0.3, cell_one.y + 0.3, 0.4, 1.4]
      # If cell one is to the left of cell two
      elsif cell_one.x > cell_two.x && cell_one.y == cell_two.y
        # Path starts from the center of cell two and moves rightward to the center of cell one
        path = [cell_two.x + 0.3, cell_two.y + 0.3, 1.4, 0.4]
      # If cell one is to the right of cell two
      elsif cell_one.x < cell_two.x && cell_one.y == cell_two.y
        # Path starts from the center of cell one and moves rightward to the center of cell two
        path = [cell_one.x + 0.3, cell_one.y + 0.3, 1.4, 0.4]
      end

      path
    end

    # In code, the cells are represented as 1x1 rectangles
    # When drawn, the cells are larger than 1x1 rectangles
    # This method is used to scale up cells, and lines
    # Objects are scaled up according to the grid.cell_size variable
    # This allows for easy customization of the visual scale of the grid
    # This method scales up cells for the first grid
    def bfs_scale_up(cell)
      x = cell.x * grid.cell_size
      y = cell.y * grid.cell_size
      w = cell.w.zero? ? grid.cell_size : cell.w * grid.cell_size
      h = cell.h.zero? ? grid.cell_size : cell.h * grid.cell_size
      {x: x, y: y, w: w, h: h}
      # {x:, y:, w:, h:}
    end

    # Translates the given cell grid.width + 1 to the right and then scales up
    # Used to draw cells for the second grid
    # This method does not work for lines,
    # so separate methods exist for the grid lines
    def heuristic_scale_up(cell)
      # Prevents the original value of cell from being edited
      cell = cell.clone
      # Translates the cell to the second grid equivalent
      cell.x += grid.width + 1
      # Proceeds as if scaling up for the first grid
      bfs_scale_up(cell)
    end

    # Checks and handles input for the buttons
    # Called when the mouse is lifted
    def input_buttons
      input_left_button
      input_center_button
      input_right_button
    end

    # Checks if the previous step button is clicked
    # If it is, it pauses the animation and moves the search one step backward
    def input_left_button
      if left_button_clicked?
        state.play = false
        state.current_step -= 1
        recalculate_searches
      end
    end

    # Controls the play/pause button
    # Inverses whether the animation is playing or not when clicked
    def input_center_button
      if center_button_clicked? || inputs.keyboard.key_down.space
        state.play = !state.play
      end
    end

    # Checks if the next step button is clicked
    # If it is, it pauses the animation and moves the search one step forward
    def input_right_button
      if right_button_clicked?
        state.play = false
        state.current_step += 1
        move_searches_one_step_forward
      end
    end

    # These methods detect when the buttons are clicked
    def left_button_clicked?
      inputs.mouse.point.inside_rect?(buttons.left) && inputs.mouse.up
    end

    def center_button_clicked?
      inputs.mouse.point.inside_rect?(buttons.center) && inputs.mouse.up
    end

    def right_button_clicked?
      inputs.mouse.point.inside_rect?(buttons.right) && inputs.mouse.up
    end


    # Signal that the user is going to be moving the slider
    # Is the mouse over the circle of the slider?
    def mouse_over_slider?
      circle_x = (slider.x - slider.offset) + (state.current_step * slider.spacing)
      circle_y = (slider.y - slider.offset)
      circle_rect = [circle_x, circle_y, 37, 37]
      inputs.mouse.point.inside_rect?(circle_rect)
    end

    # Signal that the user is going to be moving the star from the first grid
    def bfs_mouse_over_star?
      inputs.mouse.point.inside_rect?(bfs_scale_up(grid.star))
    end

    # Signal that the user is going to be moving the star from the second grid
    def heuristic_mouse_over_star?
      inputs.mouse.point.inside_rect?(heuristic_scale_up(grid.star))
    end

    # Signal that the user is going to be moving the target from the first grid
    def bfs_mouse_over_target?
      inputs.mouse.point.inside_rect?(bfs_scale_up(grid.target))
    end

    # Signal that the user is going to be moving the target from the second grid
    def heuristic_mouse_over_target?
      inputs.mouse.point.inside_rect?(heuristic_scale_up(grid.target))
    end

    # Signal that the user is going to be removing walls from the first grid
    def bfs_mouse_over_wall?
      grid.walls.each_key do |wall|
        return true if inputs.mouse.point.inside_rect?(bfs_scale_up(wall))
      end

      false
    end

    # Signal that the user is going to be removing walls from the second grid
    def heuristic_mouse_over_wall?
      grid.walls.each_key do |wall|
        return true if inputs.mouse.point.inside_rect?(heuristic_scale_up(wall))
      end

      false
    end

    # Signal that the user is going to be adding walls from the first grid
    def bfs_mouse_over_grid?
      inputs.mouse.point.inside_rect?(bfs_scale_up(grid.rect))
    end

    # Signal that the user is going to be adding walls from the second grid
    def heuristic_mouse_over_grid?
      inputs.mouse.point.inside_rect?(heuristic_scale_up(grid.rect))
    end

    # This method is called when the user is editing the slider
    # It pauses the animation and moves the white circle to the closest integer point
    # on the slider
    # Changes the step of the search to be animated
    def process_input_slider
      state.play = false
      mouse_x = inputs.mouse.point.x

      # Bounds the mouse_x to the closest x value on the slider line
      mouse_x = slider.x if mouse_x < slider.x
      mouse_x = slider.x + slider.w if mouse_x > slider.x + slider.w

      # Sets the current search step to the one represented by the mouse x value
      # The slider's circle moves due to the render_slider method using anim_steps
      state.current_step = ((mouse_x - slider.x) / slider.spacing).to_i

      recalculate_searches
    end

    # Moves the star to the cell closest to the mouse in the first grid
    # Only resets the search if the star changes position
    # Called whenever the user is editing the star (puts mouse down on star)
    def process_input_bfs_star
      old_star = grid.star.clone
      unless bfs_cell_closest_to_mouse == grid.target
        grid.star = bfs_cell_closest_to_mouse
      end
      unless old_star == grid.star
        recalculate_searches
      end
    end

    # Moves the star to the cell closest to the mouse in the second grid
    # Only resets the search if the star changes position
    # Called whenever the user is editing the star (puts mouse down on star)
    def process_input_heuristic_star
      old_star = grid.star.clone
      unless heuristic_cell_closest_to_mouse == grid.target
        grid.star = heuristic_cell_closest_to_mouse
      end
      unless old_star == grid.star
        recalculate_searches
      end
    end

    # Moves the target to the grid closest to the mouse in the first grid
    # Only recalculate_searchess the search if the target changes position
    # Called whenever the user is editing the target (puts mouse down on target)
    def process_input_bfs_target
      old_target = grid.target.clone
      unless bfs_cell_closest_to_mouse == grid.star
        grid.target = bfs_cell_closest_to_mouse
      end
      unless old_target == grid.target
        recalculate_searches
      end
    end

    # Moves the target to the cell closest to the mouse in the second grid
    # Only recalculate_searchess the search if the target changes position
    # Called whenever the user is editing the target (puts mouse down on target)
    def process_input_heuristic_target
      old_target = grid.target.clone
      unless heuristic_cell_closest_to_mouse == grid.star
        grid.target = heuristic_cell_closest_to_mouse
      end
      unless old_target == grid.target
        recalculate_searches
      end
    end

    # Removes walls in the first grid that are under the cursor
    def process_input_bfs_remove_wall
      # The mouse needs to be inside the grid, because we only want to remove walls
      # the cursor is directly over
      # Recalculations should only occur when a wall is actually deleted
      if bfs_mouse_over_grid?
        if grid.walls.key?(bfs_cell_closest_to_mouse)
          grid.walls.delete(bfs_cell_closest_to_mouse)
          recalculate_searches
        end
      end
    end

    # Removes walls in the second grid that are under the cursor
    def process_input_heuristic_remove_wall
      # The mouse needs to be inside the grid, because we only want to remove walls
      # the cursor is directly over
      # Recalculations should only occur when a wall is actually deleted
      if heuristic_mouse_over_grid?
        if grid.walls.key?(heuristic_cell_closest_to_mouse)
          grid.walls.delete(heuristic_cell_closest_to_mouse)
          recalculate_searches
        end
      end
    end
    # Adds a wall in the first grid in the cell the mouse is over
    def process_input_bfs_add_wall
      if bfs_mouse_over_grid?
        unless grid.walls.key?(bfs_cell_closest_to_mouse)
          grid.walls[bfs_cell_closest_to_mouse] = true
          recalculate_searches
        end
      end
    end

    # Adds a wall in the second grid in the cell the mouse is over
    def process_input_heuristic_add_wall
      if heuristic_mouse_over_grid?
        unless grid.walls.key?(heuristic_cell_closest_to_mouse)
          grid.walls[heuristic_cell_closest_to_mouse] = true
          recalculate_searches
        end
      end
    end

    # When the user grabs the star and puts their cursor to the far right
    # and moves up and down, the star is supposed to move along the grid as well
    # Finding the cell closest to the mouse helps with this
    def bfs_cell_closest_to_mouse
      # Closest cell to the mouse in the first grid
      x = (inputs.mouse.point.x / grid.cell_size).to_i
      y = (inputs.mouse.point.y / grid.cell_size).to_i
      # Bound x and y to the grid
      x = grid.width - 1 if x > grid.width - 1
      y = grid.height - 1 if y > grid.height - 1
      # Return closest cell
      [x, y]
    end

    # When the user grabs the star and puts their cursor to the far right
    # and moves up and down, the star is supposed to move along the grid as well
    # Finding the cell closest to the mouse in the second grid helps with this
    def heuristic_cell_closest_to_mouse
      # Closest cell grid to the mouse in the second
      x = (inputs.mouse.point.x / grid.cell_size).to_i
      y = (inputs.mouse.point.y / grid.cell_size).to_i
      # Translate the cell to the first grid
      x -= grid.width + 1
      # Bound x and y to the first grid
      x = 0 if x < 0
      y = 0 if y < 0
      x = grid.width - 1 if x > grid.width - 1
      y = grid.height - 1 if y > grid.height - 1
      # Return closest cell
      [x, y]
    end

    def recalculate_searches
      # Reset the searches
      bfs.came_from    = {}
      bfs.frontier     = []
      bfs.path         = []
      heuristic.came_from = {}
      heuristic.frontier  = []
      heuristic.path      = []

      # Move the searches forward to the current step
      state.current_step.times { move_searches_one_step_forward }
    end

    def move_searches_one_step_forward
      bfs_one_step_forward
      heuristic_one_step_forward
    end

    def bfs_one_step_forward
      return if bfs.came_from.key?(grid.target)

      # Only runs at the beginning of the search as setup.
      if bfs.came_from.empty?
        bfs.frontier << grid.star
        bfs.came_from[grid.star] = nil
      end

      # A step in the search
      unless bfs.frontier.empty?
        # Takes the next frontier cell
        new_frontier = bfs.frontier.shift
        # For each of its neighbors
        adjacent_neighbors(new_frontier).each do |neighbor|
          # That have not been visited and are not walls
          unless bfs.came_from.key?(neighbor) || grid.walls.key?(neighbor)
            # Add them to the frontier and mark them as visited
            bfs.frontier << neighbor
            bfs.came_from[neighbor] = new_frontier
          end
        end
      end

      # Sort the frontier so that cells that are in a zigzag pattern are prioritized over those in an line
      # Comment this line and let a path generate to see the difference
      bfs.frontier = bfs.frontier.sort_by { |cell| proximity_to_star(cell) }

      # If the search found the target
      if bfs.came_from.key?(grid.target)
        # Calculate the path between the target and star
        bfs_calc_path
      end
    end

    # Calculates the path between the target and star for the breadth first search
    # Only called when the breadth first search finds the target
    def bfs_calc_path
      # Start from the target
      endpoint = grid.target
      # And the cell it came from
      next_endpoint = bfs.came_from[endpoint]
      while endpoint && next_endpoint
        # Draw a path between these two cells and store it
        path = get_path_between(endpoint, next_endpoint)
        bfs.path << path
        # And get the next pair of cells
        endpoint = next_endpoint
        next_endpoint = bfs.came_from[endpoint]
        # Continue till there are no more cells
      end
    end

    # Moves the heuristic search forward one step
    # Can be called from tick while the animation is playing
    # Can also be called when recalculating the searches after the user edited the grid
    def heuristic_one_step_forward
      # Stop the search if the target has been found
      return if heuristic.came_from.key?(grid.target)

      # If the search has not begun
      if heuristic.came_from.empty?
        # Setup the search to begin from the star
        heuristic.frontier << grid.star
        heuristic.came_from[grid.star] = nil
      end

      # One step in the heuristic search

      # Unless there are no more cells to explore from
      unless heuristic.frontier.empty?
        # Get the next cell to explore from
        new_frontier = heuristic.frontier.shift
        # For each of its neighbors
        adjacent_neighbors(new_frontier).each do |neighbor|
          # That have not been visited and are not walls
          unless heuristic.came_from.key?(neighbor) || grid.walls.key?(neighbor)
            # Add them to the frontier and mark them as visited
            heuristic.frontier << neighbor
            heuristic.came_from[neighbor] = new_frontier
          end
        end
      end

      # Sort the frontier so that cells that are in a zigzag pattern are prioritized over those in an line
      heuristic.frontier = heuristic.frontier.sort_by { |cell| proximity_to_star(cell) }
      # Sort the frontier so cells that are close to the target are then prioritized
      heuristic.frontier = heuristic.frontier.sort_by { |cell| heuristic_heuristic(cell) }

      # If the search found the target
      if heuristic.came_from.key?(grid.target)
        # Calculate the path between the target and star
        heuristic_calc_path
      end
    end

    # Returns one-dimensional absolute distance between cell and target
    # Returns a number to compare distances between cells and the target
    def heuristic_heuristic(cell)
      (grid.target.x - cell.x).abs + (grid.target.y - cell.y).abs
    end

    # Calculates the path between the target and star for the heuristic search
    # Only called when the heuristic search finds the target
    def heuristic_calc_path
      # Start from the target
      endpoint = grid.target
      # And the cell it came from
      next_endpoint = heuristic.came_from[endpoint]
      while endpoint && next_endpoint
        # Draw a path between these two cells and store it
        path = get_path_between(endpoint, next_endpoint)
        heuristic.path << path
        # And get the next pair of cells
        endpoint = next_endpoint
        next_endpoint = heuristic.came_from[endpoint]
        # Continue till there are no more cells
      end
    end

    # Returns a list of adjacent cells
    # Used to determine what the next cells to be added to the frontier are
    def adjacent_neighbors(cell)
      neighbors = []

      # Gets all the valid neighbors into the array
      # From southern neighbor, clockwise
      neighbors << [cell.x    , cell.y - 1] unless cell.y == 0
      neighbors << [cell.x - 1, cell.y    ] unless cell.x == 0
      neighbors << [cell.x    , cell.y + 1] unless cell.y == grid.height - 1
      neighbors << [cell.x + 1, cell.y    ] unless cell.x == grid.width - 1

      neighbors
    end

    # Finds the vertical and horizontal distance of a cell from the star
    # and returns the larger value
    # This method is used to have a zigzag pattern in the rendered path
    # A cell that is [5, 5] from the star,
    # is explored before over a cell that is [0, 7] away.
    # So, if possible, the search tries to go diagonal (zigzag) first
    def proximity_to_star(cell)
      distance_x = (grid.star.x - cell.x).abs
      distance_y = (grid.star.y - cell.y).abs

      [distance_x, distance_y].max
    end

    # Methods that allow code to be more concise. Subdivides args.state, which is where all variables are stored.
    def grid
      state.grid
    end

    def buttons
      state.buttons
    end

    def slider
      state.slider
    end

    def bfs
      state.bfs
    end

    def heuristic
      state.heuristic
    end

    # Descriptive aliases for colors
    def default_color
      { r: 221, g: 212, b: 213 }
    end

    def wall_color
      { r: 134, g: 134, b: 120 }
    end

    def visited_color
      { r: 204, g: 191, b: 179 }
    end

    def frontier_color
      { r: 103, g: 136, b: 204, a: 200 }
    end

    def path_color
      { r: 231, g: 230, b: 228 }
    end

    def button_color
      [190, 190, 190] # Gray
    end
  end
  # Method that is called by DragonRuby periodically
  # Used for updating animations and calculations
  def tick args

    # Pressing r will reset the application
    if args.inputs.keyboard.key_down.r
      args.gtk.reset
      reset
      return
    end

    # Every tick, new args are passed, and the Breadth First Search tick is called
    $heuristic_with_walls ||= Heuristic_With_Walls.new
    $heuristic_with_walls.args = args
    $heuristic_with_walls.tick
  end


  def reset
    $heuristic_with_walls = nil
  end

```

### A Star - main.rb
```ruby
  # ./samples/13_path_finding_algorithms/08_a_star/app/main.rb
  # Contributors outside of DragonRuby who also hold Copyright:
  # - Sujay Vadlakonda: https://github.com/sujayvadlakonda

  # This program is inspired by https://www.redblobgames.com/pathfinding/a-star/introduction.html

  # The A* Search works by incorporating both the distance from the starting point
  # and the distance from the target in its heurisitic.

  # It tends to find the correct (shortest) path even when the Greedy Best-First Search does not,
  # and it explores less of the grid, and is therefore faster, than Dijkstra's Search.

  class A_Star_Algorithm
    attr_gtk

    def tick
      defaults
      render
      input

      if dijkstra.came_from.empty?
        calc_searches
      end
    end

    def defaults
      # Variables to edit the size and appearance of the grid
      # Freely customizable to user's liking
      grid.width     ||= 15
      grid.height    ||= 15
      grid.cell_size ||= 27
      grid.rect      ||= [0, 0, grid.width, grid.height]

      grid.star      ||= [0, 2]
      grid.target    ||= [11, 13]
      grid.walls     ||= {
        [2, 2] => true,
        [3, 2] => true,
        [4, 2] => true,
        [5, 2] => true,
        [6, 2] => true,
        [7, 2] => true,
        [8, 2] => true,
        [9, 2] => true,
        [10, 2] => true,
        [11, 2] => true,
        [12, 2] => true,
        [12, 3] => true,
        [12, 4] => true,
        [12, 5] => true,
        [12, 6] => true,
        [12, 7] => true,
        [12, 8] => true,
        [12, 9] => true,
        [12, 10] => true,
        [12, 11] => true,
        [12, 12] => true,
        [5, 12] => true,
        [6, 12] => true,
        [7, 12] => true,
        [8, 12] => true,
        [9, 12] => true,
        [10, 12] => true,
        [11, 12] => true,
        [12, 12] => true
      }

      # What the user is currently editing on the grid
      # We store this value, because we want to remember the value even when
      # the user's cursor is no longer over what they're interacting with, but
      # they are still clicking down on the mouse.
      state.user_input ||= :none

      # These variables allow the breadth first search to take place
      # Came_from is a hash with a key of a cell and a value of the cell that was expanded from to find the key.
      # Used to prevent searching cells that have already been found
      # and to trace a path from the target back to the starting point.
      # Frontier is an array of cells to expand the search from.
      # The search is over when there are no more cells to search from.
      # Path stores the path from the target to the star, once the target has been found
      # It prevents calculating the path every tick.
      dijkstra.came_from   ||= {}
      dijkstra.cost_so_far ||= {}
      dijkstra.frontier    ||= []
      dijkstra.path        ||= []

      greedy.came_from ||= {}
      greedy.frontier  ||= []
      greedy.path      ||= []

      a_star.frontier    ||= []
      a_star.came_from   ||= {}
      a_star.path        ||= []
      a_star.cost_so_far ||= {}
    end

    # All methods with render draw stuff on the screen
    # UI has buttons, the slider, and labels
    # The search specific rendering occurs in the respective methods
    def render
      render_labels
      render_dijkstra
      render_greedy
      render_a_star
    end

    def render_labels
      outputs.labels << [150, 450, "Dijkstra's"]
      outputs.labels << [550, 450, "Greedy Best-First"]
      outputs.labels << [1025, 450, "A* Search"]
    end

    def render_dijkstra
      render_dijkstra_grid
      render_dijkstra_star
      render_dijkstra_target
      render_dijkstra_visited
      render_dijkstra_walls
      render_dijkstra_path
    end

    def render_greedy
      render_greedy_grid
      render_greedy_star
      render_greedy_target
      render_greedy_visited
      render_greedy_walls
      render_greedy_path
    end

    def render_a_star
      render_a_star_grid
      render_a_star_star
      render_a_star_target
      render_a_star_visited
      render_a_star_walls
      render_a_star_path
    end

    # This method handles user input every tick
    def input
      # If the mouse was lifted this tick
      if inputs.mouse.up
        # Set current input to none
        state.user_input = :none
      end

      # If the mouse was clicked this tick
      if inputs.mouse.down
        # Determine what the user is editing and appropriately edit the state.user_input variable
        determine_input
      end

      # Process user input based on user_input variable and current mouse position
      process_input
    end

    # Determines what the user is editing
    # This method is called when the mouse is clicked down
    def determine_input
      # If the mouse is over the star in the first grid
      if dijkstra_mouse_over_star?
        # The user is editing the star from the first grid
        state.user_input = :dijkstra_star
      # If the mouse is over the star in the second grid
      elsif greedy_mouse_over_star?
        # The user is editing the star from the second grid
        state.user_input = :greedy_star
      # If the mouse is over the star in the third grid
      elsif a_star_mouse_over_star?
        # The user is editing the star from the third grid
        state.user_input = :a_star_star
      # If the mouse is over the target in the first grid
      elsif dijkstra_mouse_over_target?
        # The user is editing the target from the first grid
        state.user_input = :dijkstra_target
      # If the mouse is over the target in the second grid
      elsif greedy_mouse_over_target?
        # The user is editing the target from the second grid
        state.user_input = :greedy_target
      # If the mouse is over the target in the third grid
      elsif a_star_mouse_over_target?
        # The user is editing the target from the third grid
        state.user_input = :a_star_target
      # If the mouse is over a wall in the first grid
      elsif dijkstra_mouse_over_wall?
        # The user is removing a wall from the first grid
        state.user_input = :dijkstra_remove_wall
      # If the mouse is over a wall in the second grid
      elsif greedy_mouse_over_wall?
        # The user is removing a wall from the second grid
        state.user_input = :greedy_remove_wall
      # If the mouse is over a wall in the third grid
      elsif a_star_mouse_over_wall?
        # The user is removing a wall from the third grid
        state.user_input = :a_star_remove_wall
      # If the mouse is over the first grid
      elsif dijkstra_mouse_over_grid?
        # The user is adding a wall from the first grid
        state.user_input = :dijkstra_add_wall
      # If the mouse is over the second grid
      elsif greedy_mouse_over_grid?
        # The user is adding a wall from the second grid
        state.user_input = :greedy_add_wall
      # If the mouse is over the third grid
      elsif a_star_mouse_over_grid?
        # The user is adding a wall from the third grid
        state.user_input = :a_star_add_wall
      end
    end

    # Processes click and drag based on what the user is currently dragging
    def process_input
      if state.user_input == :dijkstra_star
        process_input_dijkstra_star
      elsif state.user_input == :greedy_star
        process_input_greedy_star
      elsif state.user_input == :a_star_star
        process_input_a_star_star
      elsif state.user_input == :dijkstra_target
        process_input_dijkstra_target
      elsif state.user_input == :greedy_target
        process_input_greedy_target
      elsif state.user_input == :a_star_target
        process_input_a_star_target
      elsif state.user_input == :dijkstra_remove_wall
        process_input_dijkstra_remove_wall
      elsif state.user_input == :greedy_remove_wall
        process_input_greedy_remove_wall
      elsif state.user_input == :a_star_remove_wall
        process_input_a_star_remove_wall
      elsif state.user_input == :dijkstra_add_wall
        process_input_dijkstra_add_wall
      elsif state.user_input == :greedy_add_wall
        process_input_greedy_add_wall
      elsif state.user_input == :a_star_add_wall
        process_input_a_star_add_wall
      end
    end

    def render_dijkstra_grid
      # A large rect the size of the grid
      outputs.solids << dijkstra_scale_up(grid.rect).merge(default_color)

      outputs.lines << (0..grid.width).map { |x| dijkstra_vertical_line(x) }
      outputs.lines << (0..grid.height).map { |y| dijkstra_horizontal_line(y) }
    end

    def render_greedy_grid
      # A large rect the size of the grid
      outputs.solids << greedy_scale_up(grid.rect).merge(default_color)

      outputs.lines << (0..grid.width).map { |x| greedy_vertical_line(x) }
      outputs.lines << (0..grid.height).map { |y| greedy_horizontal_line(y) }
    end

    def render_a_star_grid
      # A large rect the size of the grid
      outputs.solids << a_star_scale_up(grid.rect).merge(default_color)

      outputs.lines << (0..grid.width).map { |x| a_star_vertical_line(x) }
      outputs.lines << (0..grid.height).map { |y| a_star_horizontal_line(y) }
    end

    # Returns a vertical line for a column of the first grid
    def dijkstra_vertical_line x
      line = { x: x, y: 0, w: 0, h: grid.height }
      line.transform_values { |v| v * grid.cell_size }
    end

    # Returns a horizontal line for a column of the first grid
    def dijkstra_horizontal_line y
      line = { x: 0, y: y, w: grid.width, h: 0 }
      line.transform_values { |v| v * grid.cell_size }
    end

    # Returns a vertical line for a column of the second grid
    def greedy_vertical_line x
      dijkstra_vertical_line(x + grid.width + 1)
    end

    # Returns a horizontal line for a column of the second grid
    def greedy_horizontal_line y
      line = { x: grid.width + 1, y: y, w: grid.width, h: 0 }
      line.transform_values { |v| v * grid.cell_size }
    end

    # Returns a vertical line for a column of the third grid
    def a_star_vertical_line x
      dijkstra_vertical_line(x + grid.width + 1 + grid.width + 1)
    end

    # Returns a horizontal line for a column of the third grid
    def a_star_horizontal_line y
      line = { x: grid.width + 1 + grid.width + 1, y: y, w: grid.width, h: 0 }
      line.transform_values { |v| v * grid.cell_size }
    end

    # Renders the star on the first grid
    def render_dijkstra_star
      outputs.sprites << dijkstra_scale_up(grid.star).merge({ path: 'star.png' })
    end

    # Renders the star on the second grid
    def render_greedy_star
      outputs.sprites << greedy_scale_up(grid.star).merge({ path: 'star.png' })
    end

    # Renders the star on the third grid
    def render_a_star_star
      outputs.sprites << a_star_scale_up(grid.star).merge({ path: 'star.png' })
    end

    # Renders the target on the first grid
    def render_dijkstra_target
      outputs.sprites << dijkstra_scale_up(grid.target).merge({ path: 'target.png' })
    end

    # Renders the target on the second grid
    def render_greedy_target
      outputs.sprites << greedy_scale_up(grid.target).merge({ path: 'target.png' })
    end

    # Renders the target on the third grid
    def render_a_star_target
      outputs.sprites << a_star_scale_up(grid.target).merge({ path: 'target.png' })
    end

    # Renders the walls on the first grid
    def render_dijkstra_walls
      outputs.solids << grid.walls.map do |key, value|
        dijkstra_scale_up(key).merge(wall_color)
      end
    end

    # Renders the walls on the second grid
    def render_greedy_walls
      outputs.solids << grid.walls.map do |key, value|
        greedy_scale_up(key).merge(wall_color)
      end
    end

    # Renders the walls on the third grid
    def render_a_star_walls
      outputs.solids << grid.walls.map do |key, value|
        a_star_scale_up(key).merge(wall_color)
      end
    end

    # Renders the visited cells on the first grid
    def render_dijkstra_visited
      outputs.solids << dijkstra.came_from.map do |key, value|
        dijkstra_scale_up(key).merge(visited_color)
      end
    end

    # Renders the visited cells on the second grid
    def render_greedy_visited
      outputs.solids << greedy.came_from.map do |key, value|
        greedy_scale_up(key).merge(visited_color)
      end
    end

    # Renders the visited cells on the third grid
    def render_a_star_visited
      outputs.solids << a_star.came_from.map do |key, value|
        a_star_scale_up(key).merge(visited_color)
      end
    end

    # Renders the path found by the breadth first search on the first grid
    def render_dijkstra_path
      outputs.solids << dijkstra.path.map do |path|
        dijkstra_scale_up(path).merge(path_color)
      end
    end

    # Renders the path found by the greedy search on the second grid
    def render_greedy_path
      outputs.solids << greedy.path.map do |path|
        greedy_scale_up(path).merge(path_color)
      end
    end

    # Renders the path found by the a_star search on the third grid
    def render_a_star_path
      outputs.solids << a_star.path.map do |path|
        a_star_scale_up(path).merge(path_color)
      end
    end

    # Returns the rect for the path between two cells based on their relative positions
    def get_path_between(cell_one, cell_two)
      path = []

      # If cell one is above cell two
      if cell_one.x == cell_two.x && cell_one.y > cell_two.y
        # Path starts from the center of cell two and moves upward to the center of cell one
        path = [cell_two.x + 0.3, cell_two.y + 0.3, 0.4, 1.4]
      # If cell one is below cell two
      elsif cell_one.x == cell_two.x && cell_one.y < cell_two.y
        # Path starts from the center of cell one and moves upward to the center of cell two
        path = [cell_one.x + 0.3, cell_one.y + 0.3, 0.4, 1.4]
      # If cell one is to the left of cell two
      elsif cell_one.x > cell_two.x && cell_one.y == cell_two.y
        # Path starts from the center of cell two and moves rightward to the center of cell one
        path = [cell_two.x + 0.3, cell_two.y + 0.3, 1.4, 0.4]
      # If cell one is to the right of cell two
      elsif cell_one.x < cell_two.x && cell_one.y == cell_two.y
        # Path starts from the center of cell one and moves rightward to the center of cell two
        path = [cell_one.x + 0.3, cell_one.y + 0.3, 1.4, 0.4]
      end

      path
    end

    # In code, the cells are represented as 1x1 rectangles
    # When drawn, the cells are larger than 1x1 rectangles
    # This method is used to scale up cells, and lines
    # Objects are scaled up according to the grid.cell_size variable
    # This allows for easy customization of the visual scale of the grid
    # This method scales up cells for the first grid
    def dijkstra_scale_up(cell)
      x = cell.x * grid.cell_size
      y = cell.y * grid.cell_size
      w = cell.w.zero? ? grid.cell_size : cell.w * grid.cell_size
      h = cell.h.zero? ? grid.cell_size : cell.h * grid.cell_size
      {x: x, y: y, w: w, h: h}
    end

    # Translates the given cell grid.width + 1 to the right and then scales up
    # Used to draw cells for the second grid
    # This method does not work for lines,
    # so separate methods exist for the grid lines
    def greedy_scale_up(cell)
      # Prevents the original value of cell from being edited
      cell = cell.clone
      # Translates the cell to the second grid equivalent
      cell.x += grid.width + 1
      # Proceeds as if scaling up for the first grid
      dijkstra_scale_up(cell)
    end

    # Translates the given cell (grid.width + 1) * 2 to the right and then scales up
    # Used to draw cells for the third grid
    # This method does not work for lines,
    # so separate methods exist for the grid lines
    def a_star_scale_up(cell)
      # Prevents the original value of cell from being edited
      cell = cell.clone
      # Translates the cell to the second grid equivalent
      cell.x += grid.width + 1
      # Translates the cell to the third grid equivalent
      cell.x += grid.width + 1
      # Proceeds as if scaling up for the first grid
      dijkstra_scale_up(cell)
    end

    # Signal that the user is going to be moving the star from the first grid
    def dijkstra_mouse_over_star?
      inputs.mouse.point.inside_rect?(dijkstra_scale_up(grid.star))
    end

    # Signal that the user is going to be moving the star from the second grid
    def greedy_mouse_over_star?
      inputs.mouse.point.inside_rect?(greedy_scale_up(grid.star))
    end

    # Signal that the user is going to be moving the star from the third grid
    def a_star_mouse_over_star?
      inputs.mouse.point.inside_rect?(a_star_scale_up(grid.star))
    end

    # Signal that the user is going to be moving the target from the first grid
    def dijkstra_mouse_over_target?
      inputs.mouse.point.inside_rect?(dijkstra_scale_up(grid.target))
    end

    # Signal that the user is going to be moving the target from the second grid
    def greedy_mouse_over_target?
      inputs.mouse.point.inside_rect?(greedy_scale_up(grid.target))
    end

    # Signal that the user is going to be moving the target from the third grid
    def a_star_mouse_over_target?
      inputs.mouse.point.inside_rect?(a_star_scale_up(grid.target))
    end

    # Signal that the user is going to be removing walls from the first grid
    def dijkstra_mouse_over_wall?
      grid.walls.each_key do | wall |
        return true if inputs.mouse.point.inside_rect?(dijkstra_scale_up(wall))
      end

      false
    end

    # Signal that the user is going to be removing walls from the second grid
    def greedy_mouse_over_wall?
      grid.walls.each_key do | wall |
        return true if inputs.mouse.point.inside_rect?(greedy_scale_up(wall))
      end

      false
    end

    # Signal that the user is going to be removing walls from the third grid
    def a_star_mouse_over_wall?
      grid.walls.each_key do | wall |
        return true if inputs.mouse.point.inside_rect?(a_star_scale_up(wall))
      end

      false
    end

    # Signal that the user is going to be adding walls from the first grid
    def dijkstra_mouse_over_grid?
      inputs.mouse.point.inside_rect?(dijkstra_scale_up(grid.rect))
    end

    # Signal that the user is going to be adding walls from the second grid
    def greedy_mouse_over_grid?
      inputs.mouse.point.inside_rect?(greedy_scale_up(grid.rect))
    end

    # Signal that the user is going to be adding walls from the third grid
    def a_star_mouse_over_grid?
      inputs.mouse.point.inside_rect?(a_star_scale_up(grid.rect))
    end

    # Moves the star to the cell closest to the mouse in the first grid
    # Only resets the search if the star changes position
    # Called whenever the user is editing the star (puts mouse down on star)
    def process_input_dijkstra_star
      old_star = grid.star.clone
      unless dijkstra_cell_closest_to_mouse == grid.target
        grid.star = dijkstra_cell_closest_to_mouse
      end
      unless old_star == grid.star
        reset_searches
      end
    end

    # Moves the star to the cell closest to the mouse in the second grid
    # Only resets the search if the star changes position
    # Called whenever the user is editing the star (puts mouse down on star)
    def process_input_greedy_star
      old_star = grid.star.clone
      unless greedy_cell_closest_to_mouse == grid.target
        grid.star = greedy_cell_closest_to_mouse
      end
      unless old_star == grid.star
        reset_searches
      end
    end

    # Moves the star to the cell closest to the mouse in the third grid
    # Only resets the search if the star changes position
    # Called whenever the user is editing the star (puts mouse down on star)
    def process_input_a_star_star
      old_star = grid.star.clone
      unless a_star_cell_closest_to_mouse == grid.target
        grid.star = a_star_cell_closest_to_mouse
      end
      unless old_star == grid.star
        reset_searches
      end
    end

    # Moves the target to the grid closest to the mouse in the first grid
    # Only reset_searchess the search if the target changes position
    # Called whenever the user is editing the target (puts mouse down on target)
    def process_input_dijkstra_target
      old_target = grid.target.clone
      unless dijkstra_cell_closest_to_mouse == grid.star
        grid.target = dijkstra_cell_closest_to_mouse
      end
      unless old_target == grid.target
        reset_searches
      end
    end

    # Moves the target to the cell closest to the mouse in the second grid
    # Only reset_searchess the search if the target changes position
    # Called whenever the user is editing the target (puts mouse down on target)
    def process_input_greedy_target
      old_target = grid.target.clone
      unless greedy_cell_closest_to_mouse == grid.star
        grid.target = greedy_cell_closest_to_mouse
      end
      unless old_target == grid.target
        reset_searches
      end
    end

    # Moves the target to the cell closest to the mouse in the third grid
    # Only reset_searchess the search if the target changes position
    # Called whenever the user is editing the target (puts mouse down on target)
    def process_input_a_star_target
      old_target = grid.target.clone
      unless a_star_cell_closest_to_mouse == grid.star
        grid.target = a_star_cell_closest_to_mouse
      end
      unless old_target == grid.target
        reset_searches
      end
    end

    # Removes walls in the first grid that are under the cursor
    def process_input_dijkstra_remove_wall
      # The mouse needs to be inside the grid, because we only want to remove walls
      # the cursor is directly over
      # Recalculations should only occur when a wall is actually deleted
      if dijkstra_mouse_over_grid?
        if grid.walls.has_key?(dijkstra_cell_closest_to_mouse)
          grid.walls.delete(dijkstra_cell_closest_to_mouse)
          reset_searches
        end
      end
    end

    # Removes walls in the second grid that are under the cursor
    def process_input_greedy_remove_wall
      # The mouse needs to be inside the grid, because we only want to remove walls
      # the cursor is directly over
      # Recalculations should only occur when a wall is actually deleted
      if greedy_mouse_over_grid?
        if grid.walls.key?(greedy_cell_closest_to_mouse)
          grid.walls.delete(greedy_cell_closest_to_mouse)
          reset_searches
        end
      end
    end

    # Removes walls in the third grid that are under the cursor
    def process_input_a_star_remove_wall
      # The mouse needs to be inside the grid, because we only want to remove walls
      # the cursor is directly over
      # Recalculations should only occur when a wall is actually deleted
      if a_star_mouse_over_grid?
        if grid.walls.key?(a_star_cell_closest_to_mouse)
          grid.walls.delete(a_star_cell_closest_to_mouse)
          reset_searches
        end
      end
    end

    # Adds a wall in the first grid in the cell the mouse is over
    def process_input_dijkstra_add_wall
      if dijkstra_mouse_over_grid?
        unless grid.walls.key?(dijkstra_cell_closest_to_mouse)
          grid.walls[dijkstra_cell_closest_to_mouse] = true
          reset_searches
        end
      end
    end

    # Adds a wall in the second grid in the cell the mouse is over
    def process_input_greedy_add_wall
      if greedy_mouse_over_grid?
        unless grid.walls.key?(greedy_cell_closest_to_mouse)
          grid.walls[greedy_cell_closest_to_mouse] = true
          reset_searches
        end
      end
    end

    # Adds a wall in the third grid in the cell the mouse is over
    def process_input_a_star_add_wall
      if a_star_mouse_over_grid?
        unless grid.walls.key?(a_star_cell_closest_to_mouse)
          grid.walls[a_star_cell_closest_to_mouse] = true
          reset_searches
        end
      end
    end

    # When the user grabs the star and puts their cursor to the far right
    # and moves up and down, the star is supposed to move along the grid as well
    # Finding the cell closest to the mouse helps with this
    def dijkstra_cell_closest_to_mouse
      # Closest cell to the mouse in the first grid
      x = (inputs.mouse.point.x / grid.cell_size).to_i
      y = (inputs.mouse.point.y / grid.cell_size).to_i
      # Bound x and y to the grid
      x = grid.width - 1 if x > grid.width - 1
      y = grid.height - 1 if y > grid.height - 1
      # Return closest cell
      [x, y]
    end

    # When the user grabs the star and puts their cursor to the far right
    # and moves up and down, the star is supposed to move along the grid as well
    # Finding the cell closest to the mouse in the second grid helps with this
    def greedy_cell_closest_to_mouse
      # Closest cell grid to the mouse in the second
      x = (inputs.mouse.point.x / grid.cell_size).to_i
      y = (inputs.mouse.point.y / grid.cell_size).to_i
      # Translate the cell to the first grid
      x -= grid.width + 1
      # Bound x and y to the first grid
      x = 0 if x < 0
      y = 0 if y < 0
      x = grid.width - 1 if x > grid.width - 1
      y = grid.height - 1 if y > grid.height - 1
      # Return closest cell
      [x, y]
    end

    # When the user grabs the star and puts their cursor to the far right
    # and moves up and down, the star is supposed to move along the grid as well
    # Finding the cell closest to the mouse in the third grid helps with this
    def a_star_cell_closest_to_mouse
      # Closest cell grid to the mouse in the second
      x = (inputs.mouse.point.x / grid.cell_size).to_i
      y = (inputs.mouse.point.y / grid.cell_size).to_i
      # Translate the cell to the first grid
      x -= (grid.width + 1) * 2
      # Bound x and y to the first grid
      x = 0 if x < 0
      y = 0 if y < 0
      x = grid.width - 1 if x > grid.width - 1
      y = grid.height - 1 if y > grid.height - 1
      # Return closest cell
      [x, y]
    end

    def reset_searches
      # Reset the searches
      dijkstra.came_from      = {}
      dijkstra.cost_so_far    = {}
      dijkstra.frontier       = []
      dijkstra.path           = []

      greedy.came_from = {}
      greedy.frontier  = []
      greedy.path      = []
      a_star.came_from = {}
      a_star.frontier  = []
      a_star.path      = []
    end

    def calc_searches
      calc_dijkstra
      calc_greedy
      calc_a_star
      # Move the searches forward to the current step
      # state.current_step.times { move_searches_one_step_forward }
    end

    def calc_dijkstra
      # Sets up the search to begin from the star
      dijkstra.frontier << grid.star
      dijkstra.came_from[grid.star] = nil
      dijkstra.cost_so_far[grid.star] = 0

      # Until the target is found or there are no more cells to explore from
      until dijkstra.came_from.key?(grid.target) or dijkstra.frontier.empty?
        # Take the next frontier cell. The first element is the cell, the second is the priority.
        new_frontier = dijkstra.frontier.shift#[0]
        # For each of its neighbors
        adjacent_neighbors(new_frontier).each do | neighbor |
          # That have not been visited and are not walls
          unless dijkstra.came_from.key?(neighbor) or grid.walls.key?(neighbor)
            # Add them to the frontier and mark them as visited
            dijkstra.frontier << neighbor
            dijkstra.came_from[neighbor] = new_frontier
            dijkstra.cost_so_far[neighbor] = dijkstra.cost_so_far[new_frontier] + 1
          end
        end

        # Sort the frontier so that cells that are in a zigzag pattern are prioritized over those in an line
        # Comment this line and let a path generate to see the difference
        dijkstra.frontier = dijkstra.frontier.sort_by {| cell | proximity_to_star(cell) }
        dijkstra.frontier = dijkstra.frontier.sort_by {| cell | dijkstra.cost_so_far[cell] }
      end


      # If the search found the target
      if dijkstra.came_from.key?(grid.target)
        # Calculate the path between the target and star
        dijkstra_calc_path
      end
    end

    def calc_greedy
      # Sets up the search to begin from the star
      greedy.frontier << grid.star
      greedy.came_from[grid.star] = nil

      # Until the target is found or there are no more cells to explore from
      until greedy.came_from.key?(grid.target) or greedy.frontier.empty?
        # Take the next frontier cell
        new_frontier = greedy.frontier.shift
        # For each of its neighbors
        adjacent_neighbors(new_frontier).each do | neighbor |
          # That have not been visited and are not walls
          unless greedy.came_from.key?(neighbor) or grid.walls.key?(neighbor)
            # Add them to the frontier and mark them as visited
            greedy.frontier << neighbor
            greedy.came_from[neighbor] = new_frontier
          end
        end
        # Sort the frontier so that cells that are in a zigzag pattern are prioritized over those in an line
        # Comment this line and let a path generate to see the difference
        greedy.frontier = greedy.frontier.sort_by {| cell | proximity_to_star(cell) }
        # Sort the frontier so cells that are close to the target are then prioritized
        greedy.frontier = greedy.frontier.sort_by {| cell | greedy_heuristic(cell)  }
      end


      # If the search found the target
      if greedy.came_from.key?(grid.target)
        # Calculate the path between the target and star
        greedy_calc_path
      end
    end

    def calc_a_star
      # Setup the search to start from the star
      a_star.came_from[grid.star] = nil
      a_star.cost_so_far[grid.star] = 0
      a_star.frontier << grid.star

      # Until there are no more cells to explore from or the search has found the target
      until a_star.frontier.empty? or a_star.came_from.key?(grid.target)
        # Get the next cell to expand from
        current_frontier = a_star.frontier.shift

        # For each of that cells neighbors
        adjacent_neighbors(current_frontier).each do | neighbor |
          # That have not been visited and are not walls
          unless a_star.came_from.key?(neighbor) or grid.walls.key?(neighbor)
            # Add them to the frontier and mark them as visited
            a_star.frontier << neighbor
            a_star.came_from[neighbor] = current_frontier
            a_star.cost_so_far[neighbor] = a_star.cost_so_far[current_frontier] + 1
          end
        end

        # Sort the frontier so that cells that are in a zigzag pattern are prioritized over those in an line
        # Comment this line and let a path generate to see the difference
        a_star.frontier = a_star.frontier.sort_by {| cell | proximity_to_star(cell) }
        a_star.frontier = a_star.frontier.sort_by {| cell | a_star.cost_so_far[cell] + greedy_heuristic(cell) }
      end

      # If the search found the target
      if a_star.came_from.key?(grid.target)
        # Calculate the path between the target and star
        a_star_calc_path
      end
    end

    # Calculates the path between the target and star for the breadth first search
    # Only called when the breadth first search finds the target
    def dijkstra_calc_path
      # Start from the target
      endpoint = grid.target
      # And the cell it came from
      next_endpoint = dijkstra.came_from[endpoint]
      while endpoint && next_endpoint
        # Draw a path between these two cells and store it
        path = get_path_between(endpoint, next_endpoint)
        dijkstra.path << path
        # And get the next pair of cells
        endpoint = next_endpoint
        next_endpoint = dijkstra.came_from[endpoint]
        # Continue till there are no more cells
      end
    end

    # Returns one-dimensional absolute distance between cell and target
    # Returns a number to compare distances between cells and the target
    def greedy_heuristic(cell)
      (grid.target.x - cell.x).abs + (grid.target.y - cell.y).abs
    end

    # Calculates the path between the target and star for the greedy search
    # Only called when the greedy search finds the target
    def greedy_calc_path
      # Start from the target
      endpoint = grid.target
      # And the cell it came from
      next_endpoint = greedy.came_from[endpoint]
      while endpoint && next_endpoint
        # Draw a path between these two cells and store it
        path = get_path_between(endpoint, next_endpoint)
        greedy.path << path
        # And get the next pair of cells
        endpoint = next_endpoint
        next_endpoint = greedy.came_from[endpoint]
        # Continue till there are no more cells
      end
    end

    # Calculates the path between the target and star for the a_star search
    # Only called when the a_star search finds the target
    def a_star_calc_path
      # Start from the target
      endpoint = grid.target
      # And the cell it came from
      next_endpoint = a_star.came_from[endpoint]

      while endpoint && next_endpoint
        # Draw a path between these two cells and store it
        path = get_path_between(endpoint, next_endpoint)
        a_star.path << path
        # And get the next pair of cells
        endpoint = next_endpoint
        next_endpoint = a_star.came_from[endpoint]
        # Continue till there are no more cells
      end
    end

    # Returns a list of adjacent cells
    # Used to determine what the next cells to be added to the frontier are
    def adjacent_neighbors(cell)
      neighbors = []

      # Gets all the valid neighbors into the array
      # From southern neighbor, clockwise
      neighbors << [cell.x    , cell.y - 1] unless cell.y == 0
      neighbors << [cell.x - 1, cell.y    ] unless cell.x == 0
      neighbors << [cell.x    , cell.y + 1] unless cell.y == grid.height - 1
      neighbors << [cell.x + 1, cell.y    ] unless cell.x == grid.width - 1

      neighbors
    end

    # Finds the vertical and horizontal distance of a cell from the star
    # and returns the larger value
    # This method is used to have a zigzag pattern in the rendered path
    # A cell that is [5, 5] from the star,
    # is explored before over a cell that is [0, 7] away.
    # So, if possible, the search tries to go diagonal (zigzag) first
    def proximity_to_star(cell)
      distance_x = (grid.star.x - cell.x).abs
      distance_y = (grid.star.y - cell.y).abs

      if distance_x > distance_y
        return distance_x
      else
        return distance_y
      end
    end

    # Methods that allow code to be more concise. Subdivides args.state, which is where all variables are stored.
    def grid
      state.grid
    end

    def dijkstra
      state.dijkstra
    end

    def greedy
      state.greedy
    end

    def a_star
      state.a_star
    end

    # Descriptive aliases for colors
    def default_color
      { r: 221, g: 212, b: 213 }
    end

    def wall_color
      { r: 134, g: 134, b: 120 }
    end

    def visited_color
      { r: 204, g: 191, b: 179 }
    end

    def path_color
      { r: 231, g: 230, b: 228 }
    end

    def button_color
      [190, 190, 190] # Gray
    end
  end


  # Method that is called by DragonRuby periodically
  # Used for updating animations and calculations
  def tick args

    # Pressing r will reset the application
    if args.inputs.keyboard.key_down.r
      args.gtk.reset
      reset
      return
    end

    # Every tick, new args are passed, and the Breadth First Search tick is called
    $a_star_algorithm ||= A_Star_Algorithm.new
    $a_star_algorithm.args = args
    $a_star_algorithm.tick
  end


  def reset
    $a_star_algorithm = nil
  end

```

### Tower Defense - main.rb
```ruby
  # ./samples/13_path_finding_algorithms/09_tower_defense/app/main.rb
  # Contributors outside of DragonRuby who also hold Copyright:
  # - Sujay Vadlakonda: https://github.com/sujayvadlakonda

  # An example of some major components in a tower defence game
  # The pathing of the tanks is determined by A* algorithm -- try editing the walls

  # The turrets shoot bullets at the closest tank. The bullets are heat-seeking

  def tick args
    $gtk.reset if args.inputs.keyboard.key_down.r
    defaults args
    render args
    calc args
  end

  def defaults args
    args.outputs.background_color = wall_color
    args.state.grid_size = 5
    args.state.tile_size = 50
    args.state.grid_start ||= [0, 0]
    args.state.grid_goal  ||= [4, 4]

    # Try editing these walls to see the path change!
    args.state.walls ||= {
      [0, 4] => true,
      [1, 3] => true,
      [3, 1] => true,
      # [4, 0] => true,
    }

    args.state.a_star.frontier ||= []
    args.state.a_star.came_from ||= {}
    args.state.a_star.path ||= []

    args.state.tanks ||= []
    args.state.tank_spawn_period ||= 60
    args.state.tank_sprite_path ||= 'sprites/circle/white.png'
    args.state.tank_speed ||= 1

    args.state.turret_shoot_period = 10
    # Turrets can be entered as [x, y] but are immediately mapped to hashes
    # Walls are also added where the turrets are to prevent tanks from pathing over them
    args.state.turrets ||= [
      [2, 2]
    ].each { |turret| args.state.walls[turret] = true}.map do |x, y|
      {
        x: x * args.state.tile_size,
        y: y * args.state.tile_size,
        w: args.state.tile_size,
        h: args.state.tile_size,
        path: 'sprites/circle/gray.png',
        range: 100
      }
    end

    args.state.bullet_size ||= 25
    args.state.bullets ||= []
    args.state.bullet_path ||= 'sprites/circle/orange.png'
  end

  def render args
    render_grid args
    render_a_star args
    args.outputs.sprites << args.state.tanks
    args.outputs.sprites << args.state.turrets
    args.outputs.sprites << args.state.bullets
  end

  def render_grid args
    # Draw a square the size and color of the grid
    args.outputs.solids << {
      x: 0,
      y: 0,
      w: args.state.grid_size * args.state.tile_size,
      h: args.state.grid_size * args.state.tile_size,
    }.merge(grid_color)

    # Draw lines across the grid to show tiles
    (args.state.grid_size + 1).times do | value |
      render_horizontal_line(args, value)
      render_vertical_line(args, value)
    end

    # Render special tiles
    render_tile(args, args.state.grid_start, start_color)
    render_tile(args, args.state.grid_goal, goal_color)
    args.state.walls.keys.each { |wall| render_tile(args, wall, wall_color) }
  end

  def render_vertical_line args, x
    args.outputs.lines << {
      x: x * args.state.tile_size,
      y: 0,
      w: 0,
      h: args.state.grid_size * args.state.tile_size
    }
  end

  def render_horizontal_line args, y
    args.outputs.lines << {
      x: 0,
      y: y * args.state.tile_size,
      w: args.state.grid_size * args.state.tile_size,
      h: 0
    }
  end

  def render_tile args, tile, color
    args.outputs.solids << {
      x: tile.x * args.state.tile_size,
      y: tile.y * args.state.tile_size,
      w: args.state.tile_size,
      h: args.state.tile_size,
      r: color[0],
      g: color[1],
      b: color[2]
    }
  end

  def calc args
    calc_a_star args
    calc_tanks args
    calc_turrets args
    calc_bullets args
  end

  def calc_a_star args
    # Only does this one time
    return unless args.state.a_star.path.empty?

    # Start the search from the grid start
    args.state.a_star.frontier << args.state.grid_start
    args.state.a_star.came_from[args.state.grid_start] = nil

    # Until a path to the goal has been found or there are no more tiles to explore
    until (args.state.a_star.came_from.key?(args.state.grid_goal) || args.state.a_star.frontier.empty?)
      # For the first tile in the frontier
      tile_to_expand_from = args.state.a_star.frontier.shift
      # Add each of its neighbors to the frontier
      neighbors(args, tile_to_expand_from).each do |tile|
        args.state.a_star.frontier << tile
        args.state.a_star.came_from[tile] = tile_to_expand_from
      end
    end

    # Stop calculating a path if the goal was never reached
    return unless args.state.a_star.came_from.key? args.state.grid_goal

    # Fill path by tracing back from the goal
    current_cell = args.state.grid_goal
    while current_cell
      args.state.a_star.path.unshift current_cell
      current_cell = args.state.a_star.came_from[current_cell]
    end

    puts "The path has been calculated"
    puts args.state.a_star.path
  end

  def calc_tanks args
    spawn_tank args
    move_tanks args
  end

  def move_tanks args
    # Remove tanks that have reached the end of their path
    args.state.tanks.reject! { |tank| tank[:a_star].empty? }

    # Tanks have an array that has each tile it has to go to in order from a* path
    args.state.tanks.each do | tank |
      destination = tank[:a_star][0]
      # Move the tank towards the destination
      tank[:x] += copy_sign(args.state.tank_speed, ((destination.x * args.state.tile_size) - tank[:x]))
      tank[:y] += copy_sign(args.state.tank_speed, ((destination.y * args.state.tile_size) - tank[:y]))
      # If the tank has reached its destination
      if (destination.x * args.state.tile_size) == tank[:x] &&
          (destination.y * args.state.tile_size) == tank[:y]
        # Set the destination to the next point in the path
        tank[:a_star].shift
      end
    end
  end

  def calc_turrets args
    return unless Kernel.tick_count.mod_zero? args.state.turret_shoot_period
    args.state.turrets.each do | turret |
      # Finds the closest tank
      target = nil
      shortest_distance = turret[:range] + 1
      args.state.tanks.each do | tank |
        distance = distance_between(turret[:x], turret[:y], tank[:x], tank[:y])
        if distance < shortest_distance
          target = tank
          shortest_distance = distance
        end
      end
      # If there is a tank in range, fires a bullet
      if target
        args.state.bullets << {
          x: turret[:x],
          y: turret[:y],
          w: args.state.bullet_size,
          h: args.state.bullet_size,
          path: args.state.bullet_path,
          # Note that this makes it heat-seeking, because target is passed by reference
          # Could do target.clone to make the bullet go to where the tank initially was
          target: target
        }
      end
    end
  end

  def calc_bullets args
    # Bullets aim for the center of their targets
    args.state.bullets.each { |bullet| move bullet, center_of(bullet[:target])}
    args.state.bullets.reject! { |b| b.intersect_rect? b[:target] }
  end

  def center_of object
    object = object.clone
    object[:x] += 0.5
    object[:y] += 0.5
    object
  end

  def render_a_star args
    args.state.a_star.path.map do |tile|
      # Map each x, y coordinate to the center of the tile and scale up
      [(tile.x + 0.5) * args.state.tile_size, (tile.y + 0.5) * args.state.tile_size]
    end.inject do | point_a,  point_b |
      # Render the line between each point
      args.outputs.lines << [point_a.x, point_a.y, point_b.x, point_b.y, a_star_color]
      point_b
    end
  end

  # Moves object to target at speed
  def move object, target, speed = 1
    if target.is_a? Hash
      object[:x] += copy_sign(speed, target[:x] - object[:x])
      object[:y] += copy_sign(speed, target[:y] - object[:y])
    else
      object[:x] += copy_sign(speed, target.x - object[:x])
      object[:y] += copy_sign(speed, target.y - object[:y])
    end
  end


  def distance_between a_x, a_y, b_x, b_y
    (((b_x - a_x) ** 2) + ((b_y - a_y) ** 2)) ** 0.5
  end

  def copy_sign value, sign
    return 0 if sign == 0
    return value if sign > 0
    -value
  end

  def spawn_tank args
    return unless Kernel.tick_count.mod_zero? args.state.tank_spawn_period
    args.state.tanks << {
      x: args.state.grid_start.x,
      y: args.state.grid_start.y,
      w: args.state.tile_size,
      h: args.state.tile_size,
      path: args.state.tank_sprite_path,
      a_star: args.state.a_star.path.clone
    }
  end

  def neighbors args, tile
    [[tile.x, tile.y - 1],
     [tile.x, tile.y + 1],
     [tile.x + 1, tile.y],
     [tile.x - 1, tile.y]].reject do |neighbor|
      args.state.a_star.came_from.key?(neighbor) || tile_out_of_bounds?(args, neighbor) ||
        args.state.walls.key?(neighbor)
    end
  end

  def tile_out_of_bounds? args, tile
    tile.x < 0 || tile.y < 0 || tile.x >= args.state.grid_size || tile.y >= args.state.grid_size
  end

  def grid_color
    { r: 133, g: 226, b: 144 }
  end

  def start_color
    [226, 144, 133]
  end

  def goal_color
    [226, 133, 144]
  end

  def wall_color
    [133, 144, 226]
  end

  def a_star_color
    [0, 0, 255]
  end

```

### Moveable Squares - main.rb
```ruby
  # ./samples/13_path_finding_algorithms/10_moveable_squares/app/main.rb
  class Game
    attr_gtk

    def tick
      defaults
      calc
      render
    end

    def defaults
      state.square_size ||= 16
      if !state.world
        state.world = {
          w: 80,
          h: 45,
          player: {
            x: 15,
            y: 15,
            speed: 6
          },
          walls: [
            { x: 16, y: 16 },
            { x: 15, y: 16 },
            { x: 14, y: 17 },
            { x: 14, y: 13 },
            { x: 15, y: 13 },
            { x: 16, y: 13 },
            { x: 17, y: 13 }
          ]
        }
      end
    end

    def calc
      player = world.player
      player.rect = { x: player.x * state.square_size, y: player.y * state.square_size, w: state.square_size, h: state.square_size }
      player.moveable_squares = entity_moveable_squares world.player
      if inputs.keyboard.key_down.plus
        state.world.player.speed += 1
      elsif inputs.keyboard.key_down.minus
        state.world.player.speed -= 1
        state.world.player.speed = 1 if state.world.player.speed < 1
      end

      mouse_ordinal_x = inputs.mouse.x.idiv state.square_size
      mouse_ordinal_y = inputs.mouse.y.idiv state.square_size

      if inputs.mouse.click
        if world.walls.any? { |enemy| enemy.x == mouse_ordinal_x && enemy.y == mouse_ordinal_y }
          world.walls.reject! { |enemy| enemy.x == mouse_ordinal_x && enemy.y == mouse_ordinal_y }
        else
          world.walls << { x: mouse_ordinal_x, y: mouse_ordinal_y, speed: 3 }
        end
      end

      state.hovered_square = world.player.moveable_squares.find do |square|
        mouse_ordinal_x == square.x && mouse_ordinal_y == square.y
      end
    end

    def render
      outputs.primitives << { x: 30, y: 30.from_top, text: "+/- to increase decrease movement radius." }
      outputs.primitives << { x: 30, y: 60.from_top, text: "click to add/remove wall." }
      outputs.primitives << { x: 30, y: 90.from_top, text: "FPS: #{$gtk.current_framerate.to_sf}" }
      if Kernel.tick_count <= 1
        outputs[:world_grid].w = 1280
        outputs[:world_grid].h = 720
        outputs[:world_grid].primitives << state.world.w.flat_map do |x|
          state.world.h.map do |y|
            {
              x: x * state.square_size,
              y: y * state.square_size,
              w: state.square_size,
              h: state.square_size,
              r: 0,
              g: 0,
              b: 0,
              a: 128
            }.border!
          end
        end
      end

      outputs[:world_overlay].w = 1280
      outputs[:world_overlay].h = 720
      outputs[:world_overlay].transient!

      if state.hovered_square
        outputs[:world_overlay].primitives << path_to_square_prefab(state.hovered_square)
      end

      outputs[:world_overlay].primitives << world.player.moveable_squares.map do |square|
        square_prefab square, { r: 0, g: 0, b: 128, a: 128 }
      end

      outputs[:world_overlay].primitives << world.walls.map do |enemy|
        square_prefab enemy, { r: 128, g: 0, b: 0, a: 200 }
      end

      outputs[:world_overlay].primitives << square_prefab(world.player, { r: 0, g: 128, b: 0, a: 200 })

      outputs[:world].w = 1280
      outputs[:world].h = 720
      outputs[:world].transient!
      outputs[:world].primitives << { x: 0, y: 0, w: 1280, h: 720, path: :world_grid }
      outputs[:world].primitives << { x: 0, y: 0, w: 1280, h: 720, path: :world_overlay }
      outputs.primitives << { x: 0, y: 0, w: 1280, h: 720, path: :world }
    end

    def square_prefab square, color
      {
        x: square.x * state.square_size,
        y: square.y * state.square_size,
        w: state.square_size,
        h: state.square_size,
        **color,
        path: :solid
      }
    end

    def path_to_square_prefab moveable_square
      prefab = []
      color = { r: 0, g: 0, b: 128, a: 80 }
      if moveable_square
        prefab << square_prefab(moveable_square, color)
        prefab << path_to_square_prefab(moveable_square.source)
      end
      prefab
    end

    def world
      state.world
    end

    def entity_moveable_squares entity
      results = {}
      queue = {}
      queue[entity.x] ||= {}
      queue[entity.x][entity.y] = entity
      entity_moveable_squares_recur queue, results while !queue.empty?
      results.flat_map do |x, ys|
        ys.map do |y, value|
          value
        end
      end
    end

    def entity_moveable_squares_recur queue, results
      x, ys = queue.first
      return if !x
      return if !ys
      y, to_process = ys.first
      return if !to_process
      queue[to_process.x].delete y
      queue.delete x if queue[x].empty?
      return if results[to_process.x] && results[to_process.x] && results[to_process.x][to_process.y]

      neighbors = MoveableLocations.neighbors world, to_process
      neighbors.each do |neighbor|
        if !queue[neighbor.x] || !queue[neighbor.x][neighbor.y]
          queue[neighbor.x] ||= {}
          queue[neighbor.x][neighbor.y] = neighbor
        end
      end

      results[to_process.x] ||= {}
      results[to_process.x][to_process.y] = to_process
    end
  end

  class MoveableLocations
    class << self
      def neighbors world, square
        return [] if !square
        return [] if square.speed <= 0
        north_square = { x: square.x, y: square.y + 1, speed: square.speed - 1, source: square }
        south_square = { x: square.x, y: square.y - 1, speed: square.speed - 1, source: square }
        east_square  = { x: square.x + 1, y: square.y, speed: square.speed - 1, source: square }
        west_square  = { x: square.x - 1, y: square.y, speed: square.speed - 1, source: square }
        north_east_square = { x: square.x + 1, y: square.y + 1, speed: square.speed - 2, source: square }
        north_west_square = { x: square.x - 1, y: square.y + 1, speed: square.speed - 2, source: square }
        south_east_square = { x: square.x + 1, y: square.y - 1, speed: square.speed - 2, source: square }
        south_west_square = { x: square.x - 1, y: square.y - 1, speed: square.speed - 2, source: square }
        result = []
        north_available = valid? world, north_square
        south_available = valid? world, south_square
        east_available  = valid? world, east_square
        west_available  = valid? world, west_square
        north_east_available = valid? world, north_east_square
        north_west_available = valid? world, north_west_square
        south_east_available = valid? world, south_east_square
        south_west_available = valid? world, south_west_square
        result << north_square if north_available
        result << south_square if south_available
        result << east_square  if east_available
        result << west_square  if west_available
        result << north_east_square if north_available && east_available && north_east_available
        result << north_west_square if north_available && west_available && north_west_available
        result << south_east_square if south_available && east_available && south_east_available
        result << south_west_square if south_available && west_available && south_west_available
        result
      end

      def valid? world, square
        return false if !square
        return false if square.speed < 0
        return false if square.x < 0 || square.x >= world.w || square.y < 0 || square.y >= world.h
        return false if world.walls.any? { |enemy| enemy.x == square.x && enemy.y == square.y }
        return false if world.player.x == square.x && world.player.y == square.y
        return true
      end
    end
  end

  def tick args
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

  $gtk.reset

```
