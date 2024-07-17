### Clepto Frog - main.rb
```ruby
  # ./samples/99_genre_platformer/clepto_frog/app/main.rb
  class CleptoFrog
    attr_gtk

    def tick
      defaults
      render
      input
      calc
    end

    def defaults
      state.level_editor_rect_w ||= 32
      state.level_editor_rect_h     ||= 32
      state.target_camera_scale ||= 0.5
      state.camera_scale        ||= 1
      state.tongue_length       ||= 100
      state.action              ||= :aiming
      state.tongue_angle        ||= 90
      state.tile_size           ||= 32
      state.gravity             ||= -0.1
      state.drag                ||= -0.005
      state.player ||= {
        x: 2400,
        y: 200,
        w: 60,
        h: 60,
        dx: 0,
        dy: 0,
      }
      state.camera_x     ||= state.player.x - 640
      state.camera_y     ||= 0
      load_if_needed
      state.map_saved_at ||= 0
    end

    def player
      state.player
    end

    def render
      render_world
      render_player
      render_level_editor
      render_mini_map
      render_instructions
    end

    def to_camera_space rect
      rect.merge(x: to_camera_space_x(rect.x),
                 y: to_camera_space_y(rect.y),
                 w: to_camera_space_w(rect.w),
                 h: to_camera_space_h(rect.h))
    end

    def to_camera_space_x x
      return nil if !x
       (x * state.camera_scale) - state.camera_x
    end

    def to_camera_space_y y
      return nil if !y
      (y * state.camera_scale) - state.camera_y
    end

    def to_camera_space_w w
      return nil if !w
      w * state.camera_scale
    end

    def to_camera_space_h h
      return nil if !h
      h * state.camera_scale
    end

    def render_world
      viewport = {
        x: player.x - 1280 / state.camera_scale,
        y: player.y - 720 / state.camera_scale,
        w: 2560 / state.camera_scale,
        h: 1440 / state.camera_scale
      }

      outputs.sprites << geometry.find_all_intersect_rect(viewport, state.mugs).map do |rect|
        to_camera_space rect
      end

      outputs.sprites << geometry.find_all_intersect_rect(viewport, state.walls).map do |rect|
        to_camera_space(rect).merge!(path: :pixel, r: 128, g: 128, b: 128, a: 128)
      end
    end

    def render_player
      start_of_tongue_render = to_camera_space start_of_tongue

      if state.anchor_point
        anchor_point_render = to_camera_space state.anchor_point
        outputs.sprites << { x: start_of_tongue_render.x - 2,
                             y: start_of_tongue_render.y - 2,
                             w: to_camera_space_w(4),
                             h: geometry.distance(start_of_tongue_render, anchor_point_render),
                             path:  :pixel,
                             angle_anchor_y: 0,
                             r: 255, g: 128, b: 128,
                             angle: state.tongue_angle - 90 }
      else
        outputs.sprites << { x: to_camera_space_x(start_of_tongue.x) - 2,
                             y: to_camera_space_y(start_of_tongue.y) - 2,
                             w: to_camera_space_w(4),
                             h: to_camera_space_h(state.tongue_length),
                             path:  :pixel,
                             r: 255, g: 128, b: 128,
                             angle_anchor_y: 0,
                             angle: state.tongue_angle - 90 }
      end

      angle = 0
      if state.action == :aiming && !player.on_floor
        angle = state.tongue_angle - 90
      elsif state.action == :shooting && !player.on_floor
        angle = state.tongue_angle - 90
      elsif state.action == :anchored
        angle = state.tongue_angle - 90
      end

      outputs.sprites << to_camera_space(player).merge!(path: "sprites/square/green.png", angle: angle)
    end

    def render_mini_map
      x, y = 1170, 10
      outputs.primitives << { x: x,
                              y: y,
                              w: 100,
                              h: 58,
                              r: 0,
                              g: 0,
                              b: 0,
                              a: 200,
                              path: :pixel }

      outputs.primitives << { x: x + player.x.fdiv(100) - 1,
                              y: y + player.y.fdiv(100) - 1,
                              w: 2,
                              h: 2,
                              r: 0,
                              g: 255,
                              b: 0,
                              path: :pixel }

      t_start = start_of_tongue
      t_end = end_of_tongue

      outputs.primitives << {
        x: x + t_start.x.fdiv(100),
        y: y + t_start.y.fdiv(100),
        x2: x + t_end.x.fdiv(100),
        y2: y + t_end.y.fdiv(100),
        r: 255, g: 255, b: 255
      }

      outputs.primitives << state.mugs.map do |o|
        { x: x + o.x.fdiv(100) - 1,
          y: y + o.y.fdiv(100) - 1,
          w: 2,
          h: 2,
          r: 200,
          g: 200,
          b: 0,
          path: :pixel }
      end
    end

    def render_level_editor
      return if !state.level_editor_mode
      if state.map_saved_at > 0 && state.map_saved_at.elapsed_time < 120
        outputs.primitives << { x: 920, y: 670, text: 'Map has been exported!', size_enum: 1, r: 0, g: 50, b: 100, a: 50 }
      end

      outputs.primitives << { x: to_camera_space_x(((state.camera_x + inputs.mouse.x) / state.camera_scale).ifloor(state.tile_size)),
                              y: to_camera_space_y(((state.camera_y + inputs.mouse.y) / state.camera_scale).ifloor(state.tile_size)),
                              w: to_camera_space_w(state.level_editor_rect_w),
                              h: to_camera_space_h(state.level_editor_rect_h), path: :pixel, a: 200, r: 180, g: 80, b: 200 }
    end

    def render_instructions
      if state.level_editor_mode
        outputs.labels << { x: 640,
                            y: 10.from_top,
                            text: "Click to place wall. HJKL to change wall size. X + click to remove wall. M + click to place mug. Arrow keys to move around.",
                            size_enum: -1,
                            anchor_x: 0.5 }
        outputs.labels << { x: 640,
                            y: 35.from_top,
                            text: " - and + to zoom in and out. 0 to reset camera to default zoom. G to exit level editor mode.",
                            size_enum: -1,
                            anchor_x: 0.5 }
      else
        outputs.labels << { x: 640,
                            y: 10.from_top,
                            text: "Left and Right to aim tongue. Space to shoot or release tongue. G to enter level editor mode.",
                            size_enum: -1,
                            anchor_x: 0.5 }

        outputs.labels << { x: 640,
                            y: 35.from_top,
                            text: "Up and Down to change tongue length (when tongue is attached). Left and Right to swing (when tongue is attached).",
                            size_enum: -1,
                            anchor_x: 0.5 }
      end
    end

    def start_of_tongue
      {
        x: player.x + player.w / 2,
        y: player.y + player.h / 2
      }
    end

    def calc
      calc_camera
      calc_player
      calc_mug_collection
    end

    def calc_camera
      percentage = 0.2 * state.camera_scale
      target_scale = state.target_camera_scale
      distance_scale = target_scale - state.camera_scale
      state.camera_scale += distance_scale * percentage

      target_x = player.x * state.target_camera_scale
      target_y = player.y * state.target_camera_scale

      distance_x = target_x - (state.camera_x + 640)
      distance_y = target_y - (state.camera_y + 360)
      state.camera_x += distance_x * percentage if distance_x.abs > 1
      state.camera_y += distance_y * percentage if distance_y.abs > 1
      state.camera_x = 0 if state.camera_x < 0
      state.camera_y = 0 if state.camera_y < 0
    end

    def calc_player
      calc_shooting
      calc_swing
      calc_aabb_collision
      calc_tongue_angle
      calc_on_floor
    end

    def calc_shooting
      calc_shooting_step
      calc_shooting_step
      calc_shooting_step
      calc_shooting_step
      calc_shooting_step
      calc_shooting_step
    end

    def calc_shooting_step
      return unless state.action == :shooting
      state.tongue_length += 5
      potential_anchor = end_of_tongue
      anchor_rect = { x: potential_anchor.x - 5, y: potential_anchor.y - 5, w: 10, h: 10 }
      collision = state.walls.find_all do |v|
        v.intersect_rect?(anchor_rect)
      end.first
      if collision
        state.anchor_point = potential_anchor
        state.action = :anchored
      end
    end

    def calc_swing
      return if !state.anchor_point
      target_x = state.anchor_point.x - start_of_tongue.x
      target_y = state.anchor_point.y -
                 state.tongue_length - 5 - 20 - player.h

      diff_y = player.y - target_y

      distance = geometry.distance(player, state.anchor_point)
      pull_strength = if distance < 100
                        0
                      else
                        (distance / 800)
                      end

      vector = state.tongue_angle.to_vector

      player.dx += vector.x * pull_strength**2
      player.dy += vector.y * pull_strength**2
    end

    def calc_aabb_collision
      return if !state.walls

      player.dx = player.dx.clamp(-30, 30)
      player.dy = player.dy.clamp(-30, 30)

      player.dx += player.dx * state.drag
      player.x += player.dx

      collision = geometry.find_intersect_rect player, state.walls

      if collision
        if player.dx > 0
          player.x = collision.x - player.w
        elsif player.dx < 0
          player.x = collision.x + collision.w
        end
        player.dx *= -0.8
      end

      if !state.level_editor_mode
        player.dy += state.gravity  # Since acceleration is the change in velocity, the change in y (dy) increases every frame
        player.y += player.dy
      end

      collision = geometry.find_intersect_rect player, state.walls

      if collision
        if player.dy > 0
          player.y = collision.y - 60
        elsif player.dy < 0
          player.y = collision.y + collision.h
        end

        player.dy *= -0.8
      end
    end

    def calc_tongue_angle
      return unless state.anchor_point
      state.tongue_angle = geometry.angle_from state.anchor_point, start_of_tongue
      state.tongue_length = geometry.distance(start_of_tongue, state.anchor_point)
      state.tongue_length = state.tongue_length.greater(100)
    end

    def calc_on_floor
      if state.action == :anchored
        player.on_floor = false
        player.on_floor_debounce = 30
      else
        player.on_floor_debounce ||= 30

        if player.dy.round != 0
          player.on_floor_debounce = 30
          player.on_floor = false
        else
          player.on_floor_debounce -= 1
        end

        if player.on_floor_debounce <= 0
          player.on_floor_debounce = 0
          player.on_floor = true
        end
      end
    end

    def calc_mug_collection
      collected = state.mugs.find_all { |s| s.intersect_rect? player }
      state.mugs.reject! { |s| collected.include? s }
    end

    def set_camera_scale v = nil
      return if v < 0.1
      state.target_camera_scale = v
    end

    def input
      input_game
      input_level_editor
    end

    def input_up?
      inputs.keyboard.w || inputs.keyboard.up
    end

    def input_down?
      inputs.keyboard.s || inputs.keyboard.down
    end

    def input_left?
      inputs.keyboard.a || inputs.keyboard.left
    end

    def input_right?
      inputs.keyboard.d || inputs.keyboard.right
    end

    def input_game
      if inputs.keyboard.key_down.g
        state.level_editor_mode = !state.level_editor_mode
      end

      if player.on_floor
        if inputs.keyboard.q
          player.dx = -5
        elsif inputs.keyboard.e
          player.dx = 5
        end
      end

      if inputs.keyboard.key_down.space && !state.anchor_point
        state.tongue_length = 0
        state.action = :shooting
      elsif inputs.keyboard.key_down.space
        state.action = :aiming
        state.anchor_point  = nil
        state.tongue_length = 100
      end

      if state.anchor_point
        vector = state.tongue_angle.to_vector

        if input_up?
          state.tongue_length -= 5
          player.dy += vector.y
          player.dx += vector.x
        elsif input_down?
          state.tongue_length += 5
          player.dy -= vector.y
          player.dx -= vector.x
        end

        if input_left?
          player.dx -= 0.5
        elsif input_right?
          player.dx += 0.5
        end
      else
        if input_left?
          state.tongue_angle += 1.5
          state.tongue_angle = state.tongue_angle
        elsif input_right?
          state.tongue_angle -= 1.5
          state.tongue_angle = state.tongue_angle
        end
      end
    end

    def input_level_editor
      return unless state.level_editor_mode

      if Kernel.tick_count.mod_zero?(5)
        # zoom
        if inputs.keyboard.equal_sign || inputs.keyboard.plus
          set_camera_scale state.camera_scale + 0.1
        elsif inputs.keyboard.hyphen
          set_camera_scale state.camera_scale - 0.1
        elsif inputs.keyboard.zero
          set_camera_scale 0.5
        end

        # change wall width
        if inputs.keyboard.h
          state.level_editor_rect_w -= state.tile_size
        elsif inputs.keyboard.l
          state.level_editor_rect_w += state.tile_size
        end

        state.level_editor_rect_w = state.tile_size if state.level_editor_rect_w < state.tile_size

        # change wall height
        if inputs.keyboard.j
          state.level_editor_rect_h -= state.tile_size
        elsif inputs.keyboard.k
          state.level_editor_rect_h += state.tile_size
        end

        state.level_editor_rect_h = state.tile_size if state.level_editor_rect_h < state.tile_size
      end

      if inputs.mouse.click
        x = ((state.camera_x + inputs.mouse.x) / state.camera_scale).ifloor(state.tile_size)
        y = ((state.camera_y + inputs.mouse.y) / state.camera_scale).ifloor(state.tile_size)
        # place mug
        if inputs.keyboard.m
          w = 32
          h = 32
          candidate_rect = { x: x, y: y, w: w, h: h }
          if inputs.keyboard.x
            mouse_rect = { x: (state.camera_x + inputs.mouse.x) / state.camera_scale,
                           y: (state.camera_y + inputs.mouse.y) / state.camera_scale,
                           w: 10,
                           h: 10 }
            to_remove = state.mugs.find do |r|
              r.intersect_rect? mouse_rect
            end
            if to_remove
              state.mugs.reject! { |r| r == to_remove }
            end
          else
            exists = state.mugs.find { |r| r == candidate_rect }
            if !exists
              state.mugs << candidate_rect.merge(path: "sprites/square/orange.png")
            end
          end
        else
          # place wall
          w = state.level_editor_rect_w
          h = state.level_editor_rect_h
          candidate_rect = { x: x, y: y, w: w, h: h }
          if inputs.keyboard.x
            mouse_rect = { x: (state.camera_x + inputs.mouse.x) / state.camera_scale,
                           y: (state.camera_y + inputs.mouse.y) / state.camera_scale,
                           w: 10,
                           h: 10 }
            to_remove = state.walls.find do |r|
              r.intersect_rect? mouse_rect
            end
            if to_remove
              state.walls.reject! { |r| r == to_remove }
            end
          else
            exists = state.walls.find { |r| r == candidate_rect }
            if !exists
              state.walls << candidate_rect
            end
          end
        end

        save
      end

      if input_up?
        player.y += 10
        player.dy = 0
      elsif input_down?
        player.y -= 10
        player.dy = 0
      end

      if input_left?
        player.x -= 10
        player.dx = 0
      elsif input_right?
        player.x += 10
        player.dx = 0
      end
    end

    def end_of_tongue
      p = state.tongue_angle.to_vector
      { x: start_of_tongue.x + p.x * state.tongue_length,
        y: start_of_tongue.y + p.y * state.tongue_length }
    end

    def save
      $gtk.write_file("data/mugs.txt", "")
      state.mugs.each do |o|
        $gtk.append_file "data/mugs.txt", "#{o.x},#{o.y},#{o.w},#{o.h}\n"
      end

      $gtk.write_file("data/walls.txt", "")
      state.walls.map do |o|
        $gtk.append_file "data/walls.txt", "#{o.x},#{o.y},#{o.w},#{o.h}\n"
      end
    end

    def load_if_needed
      return if state.walls
      state.walls = []
      state.mugs = []

      contents = $gtk.read_file "data/mugs.txt"
      if contents
        contents.each_line do |l|
          x, y, w, h = l.split(',').map(&:to_i)
          state.mugs << { x: x.ifloor(state.tile_size),
                          y: y.ifloor(state.tile_size),
                          w: w,
                          h: h,
                          path: "sprites/square/orange.png" }
        end
      end

      contents = $gtk.read_file "data/walls.txt"
      if contents
        contents.each_line do |l|
          x, y, w, h = l.split(',').map(&:to_i)
          state.walls << { x: x.ifloor(state.tile_size),
                           y: y.ifloor(state.tile_size),
                           w: w,
                           h: h,
                           path: :pixel,
                           r: 128,
                           g: 128,
                           b: 128,
                           a: 128 }
        end
      end
    end
  end

  $game = CleptoFrog.new

  def tick args
    $game.args = args
    $game.tick
  end

  # $gtk.reset

```

### Clepto Frog - Data - mugs.txt
```ruby
  # ./samples/99_genre_platformer/clepto_frog/data/mugs.txt
  64,64,32,32
  928,1952,32,32
  3744,2464,32,32
  1536,3264,32,32
  7648,32,32,32
  9312,1120,32,32
  7296,1152,32,32
  5792,1824,32,32
  864,3744,32,32
  1024,4640,32,32
  800,5312,32,32
  3232,5216,32,32
  4736,5280,32,32
  9312,5152,32,32
  9632,4288,32,32
  7808,4096,32,32
  8640,1952,32,32
  6880,2016,32,32
  4608,3872,32,32
  4000,4544,32,32
  3200,3328,32,32
  5056,1056,32,32
  3424,608,32,32
  6496,288,32,32
  6080,288,32,32
  5600,288,32,32
  3424,608,32,32
  2656,704,32,32
  2208,224,32,32

```

### Clepto Frog - Data - walls.txt
```ruby
  # ./samples/99_genre_platformer/clepto_frog/data/walls.txt
  0,0,32,5664
  0,5664,10016,32
  0,0,10016,32
  10016,0,32,5696
  2112,192,704,32
  2112,672,704,32
  3328,576,224,32
  5504,256,256,32
  5984,256,256,32
  6400,256,256,32
  4928,1024,256,32
  7168,1120,256,32
  9216,1088,256,32
  8544,1920,256,32
  6752,1984,256,32
  5664,1792,256,32
  832,1920,256,32
  1440,3232,256,32
  736,3712,256,32
  896,4608,256,32
  672,5280,256,32
  3136,5184,256,32
  3872,4512,256,32
  4640,5248,256,32
  7680,4064,256,32
  9536,4256,256,32
  9184,5120,256,32
  3072,3296,256,32
  3616,2432,256,32
  4480,3840,256,32
  4704,1952,128,128
  6272,3328,128,128
  5248,4832,128,128
  2496,4320,128,128
  1536,5056,128,128
  7232,5024,128,128
  2208,2336,128,128
  1120,704,128,128
  8448,2944,128,128
  8576,4608,128,128
  7840,2176,128,128
  8640,416,128,128
  6048,1088,128,128
  4768,352,128,128
  3040,1600,128,128
  448,2720,128,128
  1568,4064,128,128
  256,4736,128,128
  3936,5312,128,128
  3872,3360,128,128
  7904,800,128,128
  6272,4320,128,128
  1728,1440,128,128
  96,768,128,128
  9120,3616,128,128
  6144,5184,128,128
  7168,3168,128,128
  5472,3712,128,128
  2592,5088,128,128
  2528,3328,128,128
  1376,2560,128,128
  4096,1344,128,128
  9344,2336,128,128
  5952,2656,128,128
  3360,4160,128,128
  224,1696,128,128
  352,4064,128,128
  8192,5248,128,128
  7168,448,128,128
  6624,2592,128,128
  4608,2848,128,128
  2336,1184,128,128
  640,224,128,128
  7264,4352,128,128

```

### Gorillas Basic - credits.txt
```ruby
  # ./samples/99_genre_platformer/gorillas_basic/CREDITS.txt
  code: Amir Rajan, https://twitter.com/amirrajan
  graphics: Nick Culbertson, https://twitter.com/MobyPixel


```

### Gorillas Basic - main.rb
```ruby
  # ./samples/99_genre_platformer/gorillas_basic/app/main.rb
  class YouSoBasicGorillas
    attr_accessor :outputs, :grid, :state, :inputs

    def tick
      defaults
      render
      calc
      process_inputs
    end

    def defaults
      outputs.background_color = [33, 32, 87]
      state.building_spacing       = 1
      state.building_room_spacing  = 15
      state.building_room_width    = 10
      state.building_room_height   = 15
      state.building_heights       = [4, 4, 6, 8, 15, 20, 18]
      state.building_room_sizes    = [5, 4, 6, 7]
      state.gravity                = 0.25
      state.first_strike         ||= :player_1
      state.buildings            ||= []
      state.holes                ||= []
      state.player_1_score       ||= 0
      state.player_2_score       ||= 0
      state.wind                 ||= 0
    end

    def render
      render_stage
      render_value_insertion
      render_gorillas
      render_holes
      render_banana
      render_game_over
      render_score
      render_wind
    end

    def render_score
      outputs.primitives << [0, 0, 1280, 31, fancy_white].solid
      outputs.primitives << [1, 1, 1279, 29].solid
      outputs.labels << [  10, 25, "Score: #{state.player_1_score}", 0, 0, fancy_white]
      outputs.labels << [1270, 25, "Score: #{state.player_2_score}", 0, 2, fancy_white]
    end

    def render_wind
      outputs.primitives << [640, 12, state.wind * 500 + state.wind * 10 * rand, 4, 35, 136, 162].solid
      outputs.lines     <<  [640, 30, 640, 0, fancy_white]
    end

    def render_game_over
      return unless state.over
      outputs.primitives << [grid.rect, 0, 0, 0, 200].solid
      outputs.primitives << [640, 370, "Game Over!!", 5, 1, fancy_white].label
      if state.winner == :player_1
        outputs.primitives << [640, 340, "Player 1 Wins!!", 5, 1, fancy_white].label
      else
        outputs.primitives << [640, 340, "Player 2 Wins!!", 5, 1, fancy_white].label
      end
    end

    def render_stage
      return unless state.stage_generated
      return if state.stage_rendered

      outputs.static_solids << [grid.rect, 33, 32, 87]
      outputs.static_solids << state.buildings.map(&:solids)
      state.stage_rendered = true
    end

    def render_gorilla gorilla, id
      return unless gorilla
      if state.banana && state.banana.owner == gorilla
        animation_index  = state.banana.created_at.frame_index(3, 5, false)
      end
      if !animation_index
        outputs.sprites << [gorilla.solid, "sprites/#{id}-idle.png"]
      else
        outputs.sprites << [gorilla.solid, "sprites/#{id}-#{animation_index}.png"]
      end
    end

    def render_gorillas
      render_gorilla state.player_1, :left
      render_gorilla state.player_2, :right
    end

    def render_value_insertion
      return if state.banana
      return if state.over

      if    state.current_turn == :player_1_angle
        outputs.labels << [  10, 710, "Angle:    #{state.player_1_angle}_",    fancy_white]
      elsif state.current_turn == :player_1_velocity
        outputs.labels << [  10, 710, "Angle:    #{state.player_1_angle}",     fancy_white]
        outputs.labels << [  10, 690, "Velocity: #{state.player_1_velocity}_", fancy_white]
      elsif state.current_turn == :player_2_angle
        outputs.labels << [1120, 710, "Angle:    #{state.player_2_angle}_",    fancy_white]
      elsif state.current_turn == :player_2_velocity
        outputs.labels << [1120, 710, "Angle:    #{state.player_2_angle}",     fancy_white]
        outputs.labels << [1120, 690, "Velocity: #{state.player_2_velocity}_", fancy_white]
      end
    end

    def render_banana
      return unless state.banana
      rotation = Kernel.tick_count.%(360) * 20
      rotation *= -1 if state.banana.dx > 0
      outputs.sprites << [state.banana.x, state.banana.y, 15, 15, 'sprites/banana.png', rotation]
    end

    def render_holes
      outputs.sprites << state.holes.map do |s|
        animation_index = s.created_at.frame_index(7, 3, false)
        if animation_index
          [s.sprite, [s.sprite.rect, "sprites/explosion#{animation_index}.png" ]]
        else
          s.sprite
        end
      end
    end

    def calc
      calc_generate_stage
      calc_current_turn
      calc_banana
    end

    def calc_current_turn
      return if state.current_turn

      state.current_turn = :player_1_angle
      state.current_turn = :player_2_angle if state.first_strike == :player_2
    end

    def calc_generate_stage
      return if state.stage_generated

      state.buildings << building_prefab(state.building_spacing + -20, *random_building_size)
      8.numbers.inject(state.buildings) do |buildings, i|
        buildings <<
          building_prefab(state.building_spacing +
                          state.buildings.last.right,
                          *random_building_size)
      end

      building_two = state.buildings[1]
      state.player_1 = new_player(building_two.x + building_two.w.fdiv(2),
                                 building_two.h)

      building_nine = state.buildings[-3]
      state.player_2 = new_player(building_nine.x + building_nine.w.fdiv(2),
                                 building_nine.h)
      state.stage_generated = true
      state.wind = 1.randomize(:ratio, :sign)
    end

    def new_player x, y
      state.new_entity(:gorilla) do |p|
        p.x = x - 25
        p.y = y
        p.solid = [p.x, p.y, 50, 50]
      end
    end

    def calc_banana
      return unless state.banana

      state.banana.x  += state.banana.dx
      state.banana.dx += state.wind.fdiv(50)
      state.banana.y  += state.banana.dy
      state.banana.dy -= state.gravity
      banana_collision = [state.banana.x, state.banana.y, 10, 10]

      if state.player_1 && banana_collision.intersect_rect?(state.player_1.solid)
        state.over = true
        if state.banana.owner == state.player_2
          state.winner = :player_2
        else
          state.winner = :player_1
        end

        state.player_2_score += 1
      elsif state.player_2 && banana_collision.intersect_rect?(state.player_2.solid)
        state.over = true
        if state.banana.owner == state.player_2
          state.winner = :player_1
        else
          state.winner = :player_2
        end
        state.player_1_score += 1
      end

      if state.over
        place_hole
        return
      end

      return if state.holes.any? do |h|
        h.sprite.scale_rect(0.8, 0.5, 0.5).intersect_rect? [state.banana.x, state.banana.y, 10, 10]
      end

      return unless state.banana.y < 0 || state.buildings.any? do |b|
        b.rect.intersect_rect? [state.banana.x, state.banana.y, 1, 1]
      end

      place_hole
    end

    def place_hole
      return unless state.banana

      state.holes << state.new_entity(:banana) do |b|
        b.sprite = [state.banana.x - 20, state.banana.y - 20, 40, 40, 'sprites/hole.png']
      end

      state.banana = nil
    end

    def process_inputs_main
      return if state.banana
      return if state.over

      if inputs.keyboard.key_down.enter
        input_execute_turn
      elsif inputs.keyboard.key_down.backspace
        state.as_hash[state.current_turn] ||= ""
        state.as_hash[state.current_turn]   = state.as_hash[state.current_turn][0..-2]
      elsif inputs.keyboard.key_down.char
        state.as_hash[state.current_turn] ||= ""
        state.as_hash[state.current_turn]  += inputs.keyboard.key_down.char
      end
    end

    def process_inputs_game_over
      return unless state.over
      return unless inputs.keyboard.key_down.truthy_keys.any?
      state.over = false
      outputs.static_solids.clear
      state.buildings.clear
      state.holes.clear
      state.stage_generated = false
      state.stage_rendered = false
      if state.first_strike == :player_1
        state.first_strike = :player_2
      else
        state.first_strike = :player_1
      end
    end

    def process_inputs
      process_inputs_main
      process_inputs_game_over
    end

    def input_execute_turn
      return if state.banana

      if state.current_turn == :player_1_angle && parse_or_clear!(:player_1_angle)
        state.current_turn = :player_1_velocity
      elsif state.current_turn == :player_1_velocity && parse_or_clear!(:player_1_velocity)
        state.current_turn = :player_2_angle
        state.banana =
          new_banana(state.player_1,
                     state.player_1.x + 25,
                     state.player_1.y + 60,
                     state.player_1_angle,
                     state.player_1_velocity)
      elsif state.current_turn == :player_2_angle && parse_or_clear!(:player_2_angle)
        state.current_turn = :player_2_velocity
      elsif state.current_turn == :player_2_velocity && parse_or_clear!(:player_2_velocity)
        state.current_turn = :player_1_angle
        state.banana =
          new_banana(state.player_2,
                     state.player_2.x + 25,
                     state.player_2.y + 60,
                     180 - state.player_2_angle,
                     state.player_2_velocity)
      end

      if state.banana
        state.player_1_angle = nil
        state.player_1_velocity = nil
        state.player_2_angle = nil
        state.player_2_velocity = nil
      end
    end

    def random_building_size
      [state.building_heights.sample, state.building_room_sizes.sample]
    end

    def int? v
      v.to_i.to_s == v.to_s
    end

    def random_building_color
      [[ 99,   0, 107],
       [ 35,  64, 124],
       [ 35, 136, 162],
       ].sample
    end

    def random_window_color
      [[ 88,  62, 104],
       [253, 224, 187]].sample
    end

    def windows_for_building starting_x, floors, rooms
      floors.-(1).combinations(rooms - 1).map do |floor, room|
        [starting_x +
         state.building_room_width.*(room) +
         state.building_room_spacing.*(room + 1),
         state.building_room_height.*(floor) +
         state.building_room_spacing.*(floor + 1),
         state.building_room_width,
         state.building_room_height,
         random_window_color]
      end
    end

    def building_prefab starting_x, floors, rooms
      state.new_entity(:building) do |b|
        b.x      = starting_x
        b.y      = 0
        b.w      = state.building_room_width.*(rooms) +
                   state.building_room_spacing.*(rooms + 1)
        b.h      = state.building_room_height.*(floors) +
                   state.building_room_spacing.*(floors + 1)
        b.right  = b.x + b.w
        b.rect   = [b.x, b.y, b.w, b.h]
        b.solids = [[b.x - 1, b.y, b.w + 2, b.h + 1, fancy_white],
                    [b.x, b.y, b.w, b.h, random_building_color],
                    windows_for_building(b.x, floors, rooms)]
      end
    end

    def parse_or_clear! game_prop
      if int? state.as_hash[game_prop]
        state.as_hash[game_prop] = state.as_hash[game_prop].to_i
        return true
      end

      state.as_hash[game_prop] = nil
      return false
    end

    def new_banana owner, x, y, angle, velocity
      state.new_entity(:banana) do |b|
        b.owner     = owner
        b.x         = x
        b.y         = y
        b.angle     = angle % 360
        b.velocity  = velocity / 5
        b.dx        = b.angle.vector_x(b.velocity)
        b.dy        = b.angle.vector_y(b.velocity)
      end
    end

    def fancy_white
      [253, 252, 253]
    end
  end

  $you_so_basic_gorillas = YouSoBasicGorillas.new

  def tick args
    $you_so_basic_gorillas.outputs = args.outputs
    $you_so_basic_gorillas.grid    = args.grid
    $you_so_basic_gorillas.state    = args.state
    $you_so_basic_gorillas.inputs  = args.inputs
    $you_so_basic_gorillas.tick
  end

```

### Map Editor - camera.rb
```ruby
  # ./samples/99_genre_platformer/map_editor/app/camera.rb
  class Camera
    SCREEN_WIDTH = 1280
    SCREEN_HEIGHT = 720
    WORLD_SIZE = 1500
    WORLD_SIZE_HALF = WORLD_SIZE / 2
    OFFSET_X = (SCREEN_WIDTH - WORLD_SIZE) / 2
    OFFSET_Y = (SCREEN_HEIGHT - WORLD_SIZE) / 2

    class << self
      def to_world_space camera, rect
        x = (rect.x - WORLD_SIZE_HALF + camera.x * camera.scale - OFFSET_X) / camera.scale
        y = (rect.y - WORLD_SIZE_HALF + camera.y * camera.scale - OFFSET_Y) / camera.scale
        w = rect.w / camera.scale
        h = rect.h / camera.scale
        rect.merge x: x, y: y, w: w, h: h
      end

      def to_screen_space camera, rect
        x = rect.x * camera.scale - camera.x * camera.scale + WORLD_SIZE_HALF
        y = rect.y * camera.scale - camera.y * camera.scale + WORLD_SIZE_HALF
        w = rect.w * camera.scale
        h = rect.h * camera.scale
        rect.merge x: x, y: y, w: w, h: h
      end

      def viewport
        {
          x: OFFSET_X,
          y: OFFSET_Y,
          w: 1500,
          h: 1500
        }
      end

      def viewport_world camera
        to_world_space camera, viewport
      end

      def find_all_intersect_viewport camera, os
        Geometry.find_all_intersect_rect viewport_world(camera), os
      end
    end
  end

```

### Map Editor - level_editor.rb
```ruby
  # ./samples/99_genre_platformer/map_editor/app/level_editor.rb
  class LevelEditor
    attr_gtk
    attr :mode, :hovered_tile, :selected_tile, :tilesheet_rect

    def initialize
      @tilesheet_rect = { x: 0, y: 0, w: 320, h: 320 }
      @mode = :add
    end

    def tick
      generate_tilesheet
      calc
      render
    end

    def calc
      if inputs.keyboard.x
        @mode = :remove
      else
        @mode = :add
      end

      if !@selected_tile
        @mode = :remove
      elsif @selected_tile.x_ordinal == 0 && @selected_tile.y_ordinal == 0
        @mode = :remove
      end

      if mouse.intersect_rect? @tilesheet_rect
        x_ordinal = mouse.x.idiv(16)
        y_ordinal = mouse.y.idiv(16)
        @hovered_tile = { x_ordinal: mouse.x.idiv(16),
                          x: mouse.x.idiv(16) * 16,
                          y_ordinal: mouse.x.idiv(16),
                          y: mouse.y.idiv(16) * 16,
                          row: 20 - y_ordinal - 1,
                          col: x_ordinal,
                          path: tile_path(20 - y_ordinal - 1, x_ordinal, 20),
                          w: 16,
                          h: 16 }
      else
        @hovered_tile = nil
      end

      if mouse.click && @hovered_tile
        @selected_tile = @hovered_tile
      end

      world_mouse = Camera.to_world_space state.camera, inputs.mouse
      ifloor_x = world_mouse.x.ifloor(16)
      ifloor_y = world_mouse.y.ifloor(16)

      @mouse_world_rect =  { x: ifloor_x,
                             y: ifloor_y,
                             w: 16,
                             h: 16 }

      if @selected_tile
        ifloor_x = world_mouse.x.ifloor(16)
        ifloor_y = world_mouse.y.ifloor(16)
        @selected_tile.x = @mouse_world_rect.x
        @selected_tile.y = @mouse_world_rect.y
      end

      if @mode == :remove && (mouse.click || (mouse.held && mouse.moved))
        state.terrain.reject! { |t| t.intersect_rect? @mouse_world_rect }
        save_terrain args
      elsif @selected_tile && (mouse.click || (mouse.held && mouse.moved))
        if @mode == :add
          state.terrain.reject! { |t| t.intersect_rect? @selected_tile }
          state.terrain << @selected_tile.copy
        else
          state.terrain.reject! { |t| t.intersect_rect? @selected_tile }
        end
        save_terrain args
      end
    end

    def render
      outputs.sprites << { x: 0, y: 0, w: 320, h: 320, path: :tilesheet }

      if @hovered_tile
        outputs.sprites << { x: @hovered_tile.x,
                             y: @hovered_tile.y,
                             w: 16,
                             h: 16,
                             path: :pixel,
                             r: 255, g: 0, b: 0, a: 128 }
      end

      if @selected_tile
        if @mode == :remove
          outputs[:scene].sprites << (Camera.to_screen_space state.camera, @selected_tile).merge(path: :pixel, r: 255, g: 0, b: 0, a: 64)
        elsif @selected_tile
          outputs[:scene].sprites << (Camera.to_screen_space state.camera, @selected_tile)
          outputs[:scene].sprites << (Camera.to_screen_space state.camera, @selected_tile).merge(path: :pixel, r: 0, g: 255, b: 255, a: 64)
        end
      end
    end

    def generate_tilesheet
      return if state.tick_count > 0
      results = []
      rows = 20
      cols = 20
      tile_size = 16
      height = rows * tile_size
      width = cols * tile_size
      rows.map_with_index do |row|
        cols.map_with_index do |col|
          results << {
            x: col * tile_size,
            y: height - row * tile_size - tile_size,
            w: tile_size,
            h: tile_size,
            path: tile_path(row, col, cols)
          }
        end
      end

      outputs[:tilesheet].w = width
      outputs[:tilesheet].h = height
      outputs[:tilesheet].sprites << { x: 0, y: 0, w: width, h: height, path: :pixel, r: 0, g: 0, b: 0 }
      outputs[:tilesheet].sprites << results
    end

    def mouse
      inputs.mouse
    end

    def tile_path row, col, cols
      file_name = (tile_index row, col, cols).to_s.rjust(4, "0")
      "sprites/1-bit-platformer/#{file_name}.png"
    end

    def tile_index row, col, cols
      row * cols + col
    end

    def save_terrain args
      contents = args.state.terrain.uniq.map do |terrain_element|
        "#{terrain_element.x.to_i},#{terrain_element.y.to_i},#{terrain_element.w.to_i},#{terrain_element.h.to_i},#{terrain_element.path}"
      end
      File.write "data/terrain.txt", contents.join("\n")
    end

    def load_terrain args
      args.state.terrain = []
      contents = File.read("data/terrain.txt")
      return if !contents
      args.state.terrain = contents.lines.map do |line|
        l = line.strip
        if l.empty?
          nil
        else
          x, y, w, h, path = l.split ","
          { x: x.to_f, y: y.to_f, w: w.to_f, h: h.to_f, path: path }
        end
      end.compact.to_a.uniq
    end
  end

```

### Map Editor - main.rb
```ruby
  # ./samples/99_genre_platformer/map_editor/app/main.rb
  require 'app/level_editor.rb'
  require 'app/root_scene.rb'
  require 'app/camera.rb'

  def tick args
    $root_scene ||= RootScene.new args
    $root_scene.args = args
    $root_scene.tick
  end

  def reset
    $root_scene = nil
  end

  $gtk.reset

```

### Map Editor - root_scene.rb
```ruby
  # ./samples/99_genre_platformer/map_editor/app/root_scene.rb
  class RootScene
    attr_gtk

    attr :level_editor

    def initialize args
      @level_editor = LevelEditor.new
    end

    def tick
      args.outputs.background_color = [0, 0, 0]
      args.state.terrain ||= []
      @level_editor.load_terrain args if args.state.tick_count == 0

      state.player ||= {
        x: 0,
        y: 750,
        w: 16,
        h: 16,
        dy: 0,
        dx: 0,
        on_ground: false,
        path: "sprites/1-bit-platformer/0280.png"
      }

      if inputs.keyboard.left
        player.dx = -3
      elsif inputs.keyboard.right
        player.dx = 3
      end

      if inputs.keyboard.key_down.space && player.on_ground
        player.dy = 10
        player.on_ground = false
      end

      if args.inputs.keyboard.key_down.equal_sign || args.inputs.keyboard.key_down.plus
        state.camera.target_scale += 0.25
      elsif args.inputs.keyboard.key_down.minus
        state.camera.target_scale -= 0.25
        state.camera.target_scale = 0.25 if state.camera.target_scale < 0.25
      elsif args.inputs.keyboard.zero
        state.camera.target_scale = 1
      end

      state.gravity ||= 0.25
      calc_camera
      calc_physics
      outputs[:scene].transient!
      outputs[:scene].w = 1500
      outputs[:scene].h = 1500
      outputs[:scene].background_color = [0, 0, 0, 0]
      outputs[:scene].lines << { x: 0, y: 0, x2: 1500, y2: 1500, r: 255, g: 255, b: 255, a: 255 }
      outputs[:scene].lines << { x: 0, y: 1500, x2: 1500, y2: 0, r: 255, g: 255, b: 255, a: 255 }
      outputs[:scene].sprites << player_prefab

      terrain_to_render = Camera.find_all_intersect_viewport(state.camera, state.terrain)
      outputs[:scene].sprites << terrain_to_render.map do |m|
        Camera.to_screen_space(state.camera, m)
      end

      outputs.sprites << { **Camera.viewport, path: :scene }

      @level_editor.args = args
      @level_editor.tick

      outputs.labels << { x: 640,
                          y: 30.from_top,
                          anchor_x: 0.5,
                          text: "WASD: move around. SPACE: jump. +/-: Zoom in and out. MOUSE: select tile/edit map (hold X and CLICK to delete).",
                          r: 255,
                          g: 255,
                          b: 255 }
    end

    def calc_camera
      state.world_size ||= 1280

      if !state.camera
        state.camera = {
          x: 0,
          y: 0,
          target_x: 0,
          target_y: 0,
          target_scale: 2,
          scale: 1
        }
      end

      ease = 0.1
      state.camera.scale += (state.camera.target_scale - state.camera.scale) * ease
      state.camera.target_x = player.x
      state.camera.target_y = player.y

      state.camera.x += (state.camera.target_x - state.camera.x) * ease
      state.camera.y += (state.camera.target_y - state.camera.y) * ease
    end

    def calc_physics
      player.x += player.dx
      collision = state.terrain.find do |t|
        t.intersect_rect? player
      end

      if collision
        if player.dx > 0
          player.x = collision.x - player.w
        else
          player.x = collision.x + collision.w
        end

        player.dx = 0
      end

      player.dx *= 0.8
      if player.dx.abs < 0.5
        player.dx = 0
      end

      player.y += player.dy
      player.on_ground = false

      collision = state.terrain.find do |t|
        t.intersect_rect? player
      end

      if collision
        if player.dy > 0
          player.y = collision.y - player.h
        else
          player.y = collision.y + collision.h
          player.on_ground = true
        end
        player.dy = 0
      end

      player.dy -= state.gravity

      if (player.y + player.h) < -750
        player.y = 750
        player.dy = 0
      end
    end

    def player
      state.player
    end

    def player_prefab
      prefab = Camera.to_screen_space state.camera, (player.merge path: "sprites/1-bit-platformer/0280.png")

      if !player.on_ground
        prefab.merge! path: "sprites/1-bit-platformer/0284.png"
        if player.dx > 0
          prefab.merge! flip_horizontally: false
        elsif player.dx < 0
          prefab.merge! flip_horizontally: true
        end
      elsif player.dx > 0
        frame_index = 0.frame_index 3, 5, true
        prefab.merge! path: "sprites/1-bit-platformer/028#{frame_index + 1}.png"
      elsif player.dx < 0
        frame_index = 0.frame_index 3, 5, true
        prefab.merge! path: "sprites/1-bit-platformer/028#{frame_index + 1}.png", flip_horizontally: true
      end

      prefab
    end

    def camera
      state.camera
    end

    def should_update_matricies?
      player.dx != 0 || player.dy != 0
    end
  end

```

### Map Editor - Data - terrain.txt
```ruby
  # ./samples/99_genre_platformer/map_editor/data/terrain.txt
  0,368,16,16,sprites/1-bit-platformer/0088.png
  -16,368,16,16,sprites/1-bit-platformer/0088.png
  -32,368,16,16,sprites/1-bit-platformer/0088.png
  -48,368,16,16,sprites/1-bit-platformer/0088.png
  -64,368,16,16,sprites/1-bit-platformer/0088.png
  -80,368,16,16,sprites/1-bit-platformer/0088.png
  16,368,16,16,sprites/1-bit-platformer/0088.png
  32,368,16,16,sprites/1-bit-platformer/0088.png
  48,368,16,16,sprites/1-bit-platformer/0088.png
  64,368,16,16,sprites/1-bit-platformer/0088.png
  80,368,16,16,sprites/1-bit-platformer/0088.png
  -96,368,16,16,sprites/1-bit-platformer/0087.png
  96,368,16,16,sprites/1-bit-platformer/0089.png
  -96,352,16,16,sprites/1-bit-platformer/0127.png
  -80,352,16,16,sprites/1-bit-platformer/0128.png
  -64,352,16,16,sprites/1-bit-platformer/0128.png
  -48,352,16,16,sprites/1-bit-platformer/0128.png
  -32,352,16,16,sprites/1-bit-platformer/0128.png
  -16,352,16,16,sprites/1-bit-platformer/0128.png
  0,352,16,16,sprites/1-bit-platformer/0128.png
  16,352,16,16,sprites/1-bit-platformer/0128.png
  32,352,16,16,sprites/1-bit-platformer/0128.png
  48,352,16,16,sprites/1-bit-platformer/0128.png
  64,352,16,16,sprites/1-bit-platformer/0128.png
  80,352,16,16,sprites/1-bit-platformer/0128.png
  96,352,16,16,sprites/1-bit-platformer/0129.png

```

### Shadows - main.rb
```ruby
  # ./samples/99_genre_platformer/shadows/app/main.rb
  # demo gameplay here: https://youtu.be/wQknjYk_-dE
  # this is the core game class. the game is
  # pretty small so this is the only class that was created
  class Game
    # attr_gtk is a ruby class macro (mixin) that
    # adds the .args, .inputs, .outputs, and .state
    # properties to a class
    attr_gtk

    # this is the main tick method that
    # will be called every frame
    # the tick method is your standard game loop.
    # ie initialize game state, process input,
    #    perform simulation calculations, then render
    def tick
      defaults
      input
      calc
      render
    end

    # defaults method re-initializes the game to its
    # starting point if
    # 1. it hasn't already been initialized (state.clock is nil)
    # 2. or reinitializes the game if the player died (game_over)
    def defaults
      new_game if !state.clock || state.game_over == true
    end

    # this is where inputs are processed
    # we process inputs for the player via input_entity
    # and then process inputs for each enemy using the same
    # input_entity function
    def input
      input_entity player,
                   find_input_timeline(at: player.clock, key: :left_right),
                   find_input_timeline(at: player.clock, key: :space),
                   find_input_timeline(at: player.clock, key: :down)

      # an enemy could still be spawing
      shadows.find_all { |shadow| entity_active? shadow }
             .each do |shadow|
               input_entity shadow,
                            find_input_timeline(at: shadow.clock, key: :left_right),
                            find_input_timeline(at: shadow.clock, key: :space),
                            find_input_timeline(at: shadow.clock, key: :down)
               end
    end

    # this is the input_entity function that handles
    # the movement of the player (and the enemies)
    # it's essentially your state machine for player
    # movement
    def input_entity entity, left_right, jump, fall_through
      # guard clause that ignores input processing if
      # the entity is still spawning
      return if !entity_active? entity

      # increment the dx of the entity by the magnitude of
      # the left_right input value
      entity.dx += left_right

      # if the left_right input is zero...
      if left_right == 0
        # if the entity was originally running, then
        # set their "action" to standing
        # entity_set_action! updates the current action
        # of the entity and takes note of the frame that
        # the action occured on
        if (entity.action == :running)
          entity_set_action! entity, :standing
        end
      elsif entity.left_right != left_right && (entity_on_platform? entity)
        # if the entity is on a platform, and their current
        # left right value is different, mark them as running
        # this is done because we want to reset the run animation
        # if they changed directions
        entity_set_action! entity, :running
      end

      # capture the left_right input so that it can be
      # consulted on the next frame
      entity.left_right = left_right

      # capture the direction the player is facing
      # (this is used to determine the horizontal flip of the
      # sprite
      entity.orientation = if left_right == -1
                             :left
                           elsif left_right == 1
                             :right
                           else
                             entity.orientation
                           end

      # if the fall_through (down) input was requested,
      # and if they are on a platform...
      if fall_through && (entity_on_platform? entity)
        entity.jumped_at      = 0
        # set their jump_down value (falling through a platform)
        entity.jumped_down_at = entity.clock
        # and increment the number of times they jumped
        # (entities get three jumps before needing to touch the ground again)
        entity.jump_count    += 1
      end

      # if the jump input was requested
      # and if they haven't reached their jump limit
      if jump && entity.jump_count < 3
        # update the player's current action to the
        # corresponding jump number (used for rendering
        # the different jump animations)
        if entity.jump_count == 0
          entity_set_action! entity, :first_jump
        elsif entity.jump_count == 1
          entity_set_action! entity, :midair_jump
        elsif entity.jump_count == 2
          entity_set_action! entity, :midair_jump
        end

        # set the entity's dy value and take note
        # of when jump occured (also increment jump
        # count/eat one of their jumps)
        entity.dy             = entity.jump_power
        entity.jumped_at      = entity.clock
        entity.jumped_down_at = 0
        entity.jump_count    += 1
      end
    end

    # after inputs have been processed, we then
    # determine game over states, collision, win states
    # etc
    def calc
      # calculate the new values of the light meter
      # (if the light meter hits zero, it's game over)
      calc_light_meter

      # capture the actions that were taken this turn so
      # that they can be "replayed" for the enemies on future
      # ticks of the simulation
      calc_action_history

      # calculate collisions for the player
      calc_entity player

      # calculate collisions for the enemies
      calc_shadows

      # spawn a new light crystal
      calc_light_crystal

      # process "fire and forget" render queues
      # (eg particles and death animations)
      calc_render_queues

      # determine game over
      calc_game_over

      # increment the internal clocks for all entities
      # this internal clock is used to determine how
      # a player's past input is replayed. it's also
      # used to determine what animation frame the entity
      # should be performing when idle, running, and jumping
      calc_clock
    end

    # ease the light meters value up or down
    # every time the player captures a light crystal
    # the "target" light meter value is increased and
    # slowly spills over to the final light meter value
    # which is used to determine game over
    def calc_light_meter
      state.light_meter -= 1
      d = state.light_meter_queue * 0.1
      state.light_meter += d
      state.light_meter_queue -= d
    end

    def calc_action_history
      # keep track of the inputs the player has performed over time
      # as the inputs change for the player, mark the point in time
      # the specific input changed, and when the change occured.
      # when enemies replay the player's actions, this history (along
      # with the enemy's interal clock) is consulted to determine
      # what action should be performed

      # the three possible input events are captured and marked
      # within the input timeline if/when the value changes

      # left right input events
      state.curr_left_right     = inputs.left_right
      if state.prev_left_right != state.curr_left_right
        state.input_timeline.unshift({ at: state.clock, k: :left_right, v: state.curr_left_right })
      end
      state.prev_left_right = state.curr_left_right

      # jump input events
      state.curr_space     = inputs.keyboard.key_down.space    ||
                             inputs.controller_one.key_down.a  ||
                             inputs.keyboard.key_down.up       ||
                             inputs.controller_one.key_down.b
      if state.prev_space != state.curr_space
        state.input_timeline.unshift({ at: state.clock, k: :space, v: state.curr_space })
      end
      state.prev_space = state.curr_space

      # jump down (fall through platform)
      state.curr_down     = inputs.keyboard.down || inputs.controller_one.down
      if state.prev_down != state.curr_down
        state.input_timeline.unshift({ at: state.clock, k: :down, v: state.curr_down })
      end
      state.prev_down = state.curr_down
    end

    def calc_entity entity
      # process entity collision/simulation
      calc_entity_rect entity

      # return if the entity is still spawning
      return if !entity_active? entity

      # calc collisions
      calc_entity_collision entity

      # update the state machine of the entity based on the
      # collision results
      calc_entity_action entity

      # calc actions the entity should take based on
      # input timeline
      calc_entity_movement entity
    end

    def calc_entity_rect entity
      # this function calculates the entity's new
      # collision rect, render rect, hurt box, etc
      entity.render_rect = { x: entity.x, y: entity.y, w: entity.w, h: entity.h }
      entity.rect = entity.render_rect.merge x: entity.render_rect.x + entity.render_rect.w * 0.33,
                                             w: entity.render_rect.w * 0.33
      entity.next_rect = entity.rect.merge x: entity.x + entity.dx,
                                           y: entity.y + entity.dy
      entity.prev_rect = entity.rect.merge x: entity.x - entity.dx,
                                           y: entity.y - entity.dy
      orientation_shift = 0
      if entity.orientation == :right
        orientation_shift = entity.rect.w.half
      end
      entity.hurt_rect  = entity.rect.merge y: entity.rect.y + entity.h * 0.33,
                                            x: entity.rect.x - entity.rect.w.half + orientation_shift,
                                            h: entity.rect.h * 0.33
    end

    def calc_entity_collision entity
      # run of the mill AABB collision
      calc_entity_below entity
      calc_entity_left entity
      calc_entity_right entity
    end

    def calc_entity_below entity
      # exit ground collision detection if they aren't falling
      return unless entity.dy < 0
      tiles_below = find_tiles { |t| t.rect.top <= entity.prev_rect.y }
      collision = find_collision tiles_below, (entity.rect.merge y: entity.next_rect.y)

      # exit ground collision detection if no ground was found
      return unless collision

      # determine if the entity is allowed to fall through the platform
      # (you can only fall through a platform if you've been standing on it for 8 frames)
      can_drop = true
      if entity.last_standing_at && (entity.clock - entity.last_standing_at) < 8
        can_drop = false
      end

      # if the entity is allowed to fall through the platform,
      # and the entity requested the action, then clip them through the platform
      if can_drop && entity.jumped_down_at.elapsed_time(entity.clock) < 10 && !collision.impassable
        if (entity_on_platform? entity) && can_drop
          entity.dy = -1
        end

        entity.jump_count = 1
      else
        entity.y  = collision.rect.y + collision.rect.h
        entity.dy = 0
        entity.jump_count = 0
      end
    end

    def calc_entity_left entity
      # collision detection left side of screen
      return unless entity.dx < 0
      return if entity.next_rect.x > 8 - 32
      entity.x  = 8 - 32
      entity.dx = 0
    end

    def calc_entity_right entity
      # collision detection right side of screen
      return unless entity.dx > 0
      return if (entity.next_rect.x + entity.rect.w) < (1280 - 8 - 32)
      entity.x  = (1280 - 8 - entity.rect.w - 32)
      entity.dx = 0
    end

    def calc_entity_action entity
      # update the state machine of the entity
      # based on where they ended up after physics calculations
      if entity.dy < 0
        # mark the entity as falling after the jump animation frames
        # have been processed
        if entity.action == :midair_jump
          if entity_action_complete? entity, state.midair_jump_duration
            entity_set_action! entity, :falling
          end
        else
          entity_set_action! entity, :falling
        end
      elsif entity.dy == 0 && !(entity_on_platform? entity)
        # if the entity's dy is zero, determine if they should
        # be marked as standing or running
        if entity.left_right == 0
          entity_set_action! entity, :standing
        else
          entity_set_action! entity, :running
        end
      end
    end

    def calc_entity_movement entity
      # increment x and y positions of the entity
      # based on dy and dx
      calc_entity_dy entity
      calc_entity_dx entity
    end

    def calc_entity_dx entity
      # horizontal movement application and friction
      entity.dx  = entity.dx.clamp(-5,  5)
      entity.dx *= 0.9
      entity.x  += entity.dx
    end

    def calc_entity_dy entity
      # vertical movement application and gravity
      entity.y  += entity.dy
      entity.dy += state.gravity
      entity.dy += entity.dy * state.drag ** 2 * -1
    end

    def calc_shadows
      # every 5 seconds, add a new shadow enemy/increase difficult
      add_shadow! if state.clock.zmod?(300)

      # for each shadow, perform a simulation calculation
      shadows.each do |shadow|
        calc_entity shadow

        # decrement the spawn countdown which is used to determine if
        # the enemy is finally active
        shadow.spawn_countdown -= 1 if shadow.spawn_countdown > 0
      end
    end

    def calc_light_crystal
      # determine if the player has intersected with a light crystal
      light_rect = state.light_crystal
      if player.hurt_rect.intersect_rect? light_rect
        # if they have then queue up the partical animation of the
        # light crystal being collected
        state.jitter_fade_out_render_queue << { x:    state.light_crystal.x,
                                                y:    state.light_crystal.y,
                                                w:    state.light_crystal.w,
                                                h:    state.light_crystal.h,
                                                a:    255,
                                                path: 'sprites/light.png' }

        # increment the light meter target value
        state.light_meter_queue += 600

        # spawn a new light cristal for the player to try to get
        state.light_crystal = new_light_crystal
      end
    end

    def calc_render_queues
      # render all the entries in the "fire and forget" render queues
      state.jitter_fade_out_render_queue.each do |s|
        new_w = s.w * 1.02 ** 5
        ds = new_w - s.w
        s.w = new_w
        s.h = new_w
        s.x -= ds.half
        s.y -= ds.half
        s.a = s.a * 0.97 ** 5
      end

      state.jitter_fade_out_render_queue.reject! { |s| s.a <= 1 }

      state.game_over_render_queue.each { |s| s.a = s.a * 0.95 }
      state.game_over_render_queue.reject! { |s| s.a <= 1 }
    end

    def calc_game_over
      # calcuate game over
      state.game_over = false

      # it's game over if the player intersects with any of the enemies
      state.game_over ||= shadows.find_all { |s| s.spawn_countdown <= 0 }
                                 .any? { |s| s.hurt_rect.intersect_rect? player.hurt_rect }

      # it's game over if the light_meter hits 0
      state.game_over ||= state.light_meter <= 1

      # debug to reset the game/prematurely
      if inputs.keyboard.key_down.r
        state.you_win = false
        state.game_over = true
      end

      # update game over states and win/loss
      if state.game_over
        state.you_win = false
        state.game_over = true
      end

      if state.light_meter >= 6000
        state.you_win = true
        state.game_over = true
      end

      # if it's a game over, fade out all current entities in play
      if state.game_over
        state.game_over_render_queue.concat shadows.map { |s| s.sprite.merge(a: 255) }
        state.game_over_render_queue << player.sprite.merge(a: 255)
        state.game_over_render_queue << state.light_crystal.merge(a: 255, path: 'sprites/light.png', b: 128)
      end
    end

    def calc_clock
      return if state.game_over
      state.clock += 1
      player.clock += 1
      shadows.each { |s| s.clock += 1 if entity_active? s }
    end

    def render
      # render the game
      render_stage
      render_light_meter
      render_instructions
      render_render_queues
      render_light_meter_warning
      render_light_crystal
      render_entities
    end

    def render_stage
      # the stage is a simple background
      outputs.background_color = [255, 255, 255]
      outputs.sprites << { x: 0,
                           y: 0,
                           w: 1280,
                           h: 720,
                           path: "sprites/stage.png",
                           a: 200 }
    end

    def render_light_meter
      # the light meter sprite is rendered across the top
      # how much of the light meter is light vs dark is based off
      # of what the current light meter value is (which increases
      # when a crystal is collected and decreses a little bit every
      # frame
      meter_perc = state.light_meter.fdiv(6000) + (0.002 * rand)
      light_w = (1280 * meter_perc).round
      dark_w  = 1280 - light_w

      # once the light and dark partitions have been computed
      # render the meter sprite and clip its width (source_w)
      outputs.sprites << { x: 0,
                           y: 64.from_top,
                           w: light_w,
                           source_x: 0,
                           source_y: 0,
                           source_w: light_w,
                           source_h: 128,
                           h: 64,
                           path: 'sprites/meter-light.png' }

      outputs.sprites << { x: 1280 * meter_perc,
                           y: 64.from_top,
                           w: dark_w,
                           source_x: light_w,
                           source_y: 0,
                           source_w: dark_w,
                           source_h: 128,
                           h: 64,
                           path: 'sprites/meter-dark.png' }
    end

    def render_instructions
      outputs.labels << { x: 640,
                          y: 40,
                          text: '[left/right] to move, [up/space] to jump, [down] to drop through platform',
                          alignment_enum: 1 }

      if state.you_win
        outputs.labels << { x: 640,
                            y: 40.from_top,
                            text: 'You win!',
                            size_enum: -1,
                            alignment_enum: 1 }
      end
    end

    def render_render_queues
      outputs.sprites << state.jitter_fade_out_render_queue
      outputs.sprites << state.game_over_render_queue
    end

    def render_light_meter_warning
      return if state.light_meter >= 255

      # the screen starts to dim if they are close to having
      # a game over because of a depleated light meter
      outputs.primitives << { x: 0,
                              y: 0,
                              w: 1280,
                              h: 720,
                              a: 255 - state.light_meter,
                              path: :pixel,
                              r: 0,
                              g: 0,
                              b: 0 }

      outputs.primitives << { x: state.light_crystal.x - 32,
                              y: state.light_crystal.y - 32,
                              w: 128,
                              h: 128,
                              a: 255 - state.light_meter,
                              path: 'sprites/spotlight.png' }
    end

    def render_light_crystal
      jitter_sprite = { x: state.light_crystal.x + 5 * rand,
                        y: state.light_crystal.y + 5 * rand,
                        w: state.light_crystal.w + 5 * rand,
                        h: state.light_crystal.h + 5 * rand,
                        path: 'sprites/light.png' }
      outputs.primitives << jitter_sprite
    end

    def render_entities
      render_entity player, r: 0, g: 0, b: 0
      shadows.each { |shadow| render_entity shadow, g: 0, b: 0 }
    end

    def render_entity entity, r: 255, g: 255, b: 255;
      # this is essentially the entity "prefab"
      # the current action of the entity is consulted to
      # determine what sprite should be rendered
      # the action_at time is consulted to determine which frame
      # of the sprite animation should be presented
      a = 255

      entity.sprite = nil

      if entity.activate_at
        activation_elapsed_time = state.clock - entity.activate_at
        if entity.activate_at > state.clock
          entity.sprite = { x: entity.initial_x + 5 * rand,
                            y: entity.initial_y + 5 * rand,
                            w: 64 + 5 * rand,
                            h: 64 + 5 * rand,
                            path: "sprites/light.png",
                            g: 0, b: 0,
                            a: a }

          outputs.sprites << entity.sprite
          return
        elsif !entity.activated
          entity.activated = true
          state.jitter_fade_out_render_queue << { x: entity.initial_x + 5 * rand,
                                                  y: entity.initial_y + 5 * rand,
                                                  w: 86 + 5 * rand, h: 86 + 5 * rand,
                                                  path: "sprites/light.png",
                                                  g: 0, b: 0, a: 255 }
        end
      end

      # this is the render outputs for an entities action state machine
      if entity.action == :standing
        path = "sprites/player/stand.png"
      elsif entity.action == :running
        sprint_index = entity.action_at
                             .frame_index count: 4,
                                          hold_for: 8,
                                          repeat: true,
                                          tick_count_override: entity.clock
        path = "sprites/player/run-#{sprint_index}.png"
      elsif entity.action == :first_jump
        sprint_index = entity.action_at
                             .frame_index count: 2,
                                          hold_for: 8,
                                          repeat: false,
                                          tick_count_override: entity.clock
        path = "sprites/player/jump-#{sprint_index || 1}.png"
      elsif entity.action == :midair_jump
        sprint_index = entity.action_at
                             .frame_index count: state.midair_jump_frame_count,
                                          hold_for: state.midair_jump_hold_for,
                                          repeat: false,
                                          tick_count_override: entity.clock
        path = "sprites/player/midair-jump-#{sprint_index || 8}.png"
      elsif entity.action == :falling
        path = "sprites/player/falling.png"
      end

      flip_horizontally = true if entity.orientation == :left
      entity.sprite = entity.render_rect.merge path: path,
                                               a: a,
                                               r: r,
                                               g: g,
                                               b: b,
                                               flip_horizontally: flip_horizontally
      outputs.sprites << entity.sprite
    end

    def new_game
      state.clock                   = 0
      state.game_over               = false
      state.gravity                 = -0.4
      state.drag                    = 0.15

      state.activation_time         = 90
      state.light_meter             = 600
      state.light_meter_queue       = 0

      state.midair_jump_frame_count = 9
      state.midair_jump_hold_for    = 6
      state.midair_jump_duration    = state.midair_jump_frame_count * state.midair_jump_hold_for

      # hard coded collision tiles
      state.tiles                   = [
        { impassable: true, x: 0, y: 0, w: 1280, h: 8, path: :pixel, r: 0, g: 0, b: 0 },
        { impassable: true, x: 0, y: 0, w: 8, h: 1500, path: :pixel, r: 0, g: 0, b: 0 },
        { impassable: true, x: 1280 - 8, y: 0, w: 8, h: 1500, path: :pixel, r: 0, g: 0, b: 0 },

        { x: 80 + 320 + 80,            y: 128, w: 320, h: 8, path: :pixel, r: 0, g: 0, b: 0 },
        { x: 80 + 320 + 80 + 320 + 80, y: 192, w: 320, h: 8, path: :pixel, r: 0, g: 0, b: 0 },

        { x: 160,                      y: 320, w: 400, h: 8, path: :pixel, r: 0, g: 0, b: 0 },
        { x: 160 + 400 + 160,          y: 400, w: 400, h: 8, path: :pixel, r: 0, g: 0, b: 0 },

        { x: 320,                      y: 600, w: 320, h: 8, path: :pixel, r: 0, g: 0, b: 0 },

        { x: 8, y: 500, w: 100, h: 8, path: :pixel, r: 0, g: 0, b: 0 },

        { x: 8, y: 60, w: 100, h: 8, path: :pixel, r: 0, g: 0, b: 0 },
      ]

      state.player                = new_entity
      state.player.jump_count     = 1
      state.player.jumped_at      = state.player.clock
      state.player.jumped_down_at = 0

      state.shadows   = []

      state.input_timeline = [
        { at: 0, k: :left_right, v: inputs.left_right },
        { at: 0, k: :space,      v: false },
        { at: 0, k: :down,       v: false },
      ]

      state.jitter_fade_out_render_queue   = []
      state.game_over_render_queue       ||= []

      state.light_crystal = new_light_crystal
    end

    def new_light_crystal
      r = { x: 124 + rand(1000), y: 135 + rand(500), w: 64, h: 64 }
      return new_light_crystal if tiles.any? { |t| t.intersect_rect? r }
      return new_light_crystal if (player.x - r.x).abs < 200
      r
    end

    def entity_active? entity
      return true unless entity.activate_at
      return entity.activate_at <= state.clock
    end

    def add_shadow!
      s = new_entity(from_entity: player)
      s.activate_at = state.clock + state.activation_time * (shadows.length + 1)
      s.spawn_countdown = state.activation_time
      shadows << s
    end

    def find_input_timeline at:, key:;
      state.input_timeline.find { |t| t.at <= at && t.k == key }.v
    end

    def new_entity from_entity: nil
      # these are all the properties of an entity
      # an optional from_entity can be passed in
      # for "cloning" an entity/setting an entities
      # starting state
      pe = state.new_entity(:body)
      pe.w                  = 96
      pe.h                  = 96
      pe.jump_power         = 12
      pe.y                  = 500
      pe.x                  = 640 - 8
      pe.initial_x          = pe.x
      pe.initial_y          = pe.y
      pe.dy                 = 0
      pe.dx                 = 0
      pe.jumped_down_at     = 0
      pe.jumped_at          = 0
      pe.jump_count         = 0
      pe.clock              = state.clock
      pe.orientation        = :right
      pe.action             = :falling
      pe.action_at          = state.clock
      pe.left_right         = 0
      if from_entity
        pe.w              = from_entity.w
        pe.h              = from_entity.h
        pe.jump_power     = from_entity.jump_power
        pe.x              = from_entity.x
        pe.y              = from_entity.y
        pe.initial_x      = from_entity.x
        pe.initial_y      = from_entity.y
        pe.dy             = from_entity.dy
        pe.dx             = from_entity.dx
        pe.jumped_down_at = from_entity.jumped_down_at
        pe.jumped_at      = from_entity.jumped_at
        pe.orientation    = from_entity.orientation
        pe.action         = from_entity.action
        pe.action_at      = from_entity.action_at
        pe.jump_count     = from_entity.jump_count
        pe.left_right     = from_entity.left_right
      end
      pe
    end

    def entity_on_platform? entity
      entity.action == :standing || entity.action == :running
    end

    def entity_action_complete? entity, action_duration
      entity.action_at.elapsed_time(entity.clock) + 1 >= action_duration
    end

    def entity_set_action! entity, action
      entity.action = action
      entity.action_at = entity.clock
      entity.last_standing_at = entity.clock if action == :standing
    end

    def player
      state.player
    end

    def shadows
      state.shadows
    end

    def tiles
      state.tiles
    end

    def find_tiles &block
      tiles.find_all(&block)
    end

    def find_collision tiles, target
      tiles.find { |t| t.rect.intersect_rect? target }
    end
  end

  def boot args
    # initialize the game on boot
    $game = Game.new
  end

  def tick args
    # tick the game class after setting .args
    # (which is provided by the engine)
    $game.args = args
    $game.tick
  end

  # debug function for resetting the game if requested
  def reset args
    $game = Game.new
  end

```

### The Little Probe - main.rb
```ruby
  # ./samples/99_genre_platformer/the_little_probe/app/main.rb
  class FallingCircle
    attr_gtk

    def tick
      fiddle
      defaults
      render
      input
      calc
    end

    def fiddle
      state.gravity     = -0.02
      circle.radius     = 15
      circle.elasticity = 0.4
      camera.follow_speed = 0.4 * 0.4
    end

    def render
      render_stage_editor
      render_debug
      render_game
    end

    def defaults
      if Kernel.tick_count == 0
        args.audio[:bg] = { input: "sounds/bg.ogg", looping: true }
      end

      state.storyline ||= [
        { text: "<- -> to aim, hold space to charge",                            distance_gate: 0 },
        { text: "the little probe - by @amirrajan, made with DragonRuby Game Toolkit", distance_gate: 0 },
        { text: "mission control, this is sasha. landing on europa successful.", distance_gate: 0 },
        { text: "operation \"find earth 2.0\", initiated at 8-29-2036 14:00.",   distance_gate: 0 },
        { text: "jupiter's sure is beautiful...",   distance_gate: 4000 },
        { text: "hmm, it seems there's some kind of anomoly in the sky",   distance_gate: 7000 },
        { text: "dancing lights, i'll call them whisps.",   distance_gate: 8000 },
        { text: "#todo... look i ran out of time -_-",   distance_gate: 9000 },
        { text: "there's never enough time",   distance_gate: 9000 },
        { text: "the game jam was fun though ^_^",   distance_gate: 10000 },
      ]

      load_level force: Kernel.tick_count == 0
      state.line_mode            ||= :terrain

      state.sound_index          ||= 1
      circle.potential_lift      ||= 0
      circle.angle               ||= 90
      circle.check_point_at      ||= -1000
      circle.game_over_at        ||= -1000
      circle.x                   ||= -485
      circle.y                   ||= 12226
      circle.check_point_x       ||= circle.x
      circle.check_point_y       ||= circle.y
      circle.dy                  ||= 0
      circle.dx                  ||= 0
      circle.previous_dy         ||= 0
      circle.previous_dx         ||= 0
      circle.angle               ||= 0
      circle.after_images        ||= []
      circle.terrains_to_monitor ||= {}
      circle.impact_history      ||= []

      camera.x                   ||= 0
      camera.y                   ||= 0
      camera.target_x            ||= 0
      camera.target_y            ||= 0
      state.snaps                ||= { }
      state.snap_number            = 10

      args.state.storyline_x ||= -1000
      args.state.storyline_y ||= -1000
    end

    def render_game
      outputs.background_color = [0, 0, 0]
      outputs.sprites << [-circle.x + 1100,
                          -circle.y - 100,
                          2416 * 4,
                          3574 * 4,
                          'sprites/jupiter.png']
      outputs.sprites << [-circle.x,
                          -circle.y,
                          2416 * 4,
                          3574 * 4,
                          'sprites/level.png']
      outputs.sprites << state.whisp_queue
      render_aiming_retical
      render_circle
      render_notification
    end

    def render_notification
      toast_length = 500
      if circle.game_over_at.elapsed_time < toast_length
        label_text = "..."
      elsif circle.check_point_at.elapsed_time > toast_length
        args.state.current_storyline = nil
        return
      end
      if circle.check_point_at &&
         circle.check_point_at.elapsed_time == 1 &&
         !args.state.current_storyline
         if args.state.storyline.length > 0 && args.state.distance_traveled > args.state.storyline[0][:distance_gate]
           args.state.current_storyline = args.state.storyline.shift[:text]
           args.state.distance_traveled ||= 0
           args.state.storyline_x = circle.x
           args.state.storyline_y = circle.y
         end
        return unless args.state.current_storyline
      end
      label_text = args.state.current_storyline
      return unless label_text
      x = circle.x + camera.x
      y = circle.y + camera.y - 40
      w = 900
      h = 30
      outputs.primitives << [x - w.idiv(2), y - h, w, h, 255, 255, 255, 255].solid
      outputs.primitives << [x - w.idiv(2), y - h, w, h, 0, 0, 0, 255].border
      outputs.labels << [x, y - 4, label_text, 1, 1, 0, 0, 0, 255]
    end

    def render_aiming_retical
      outputs.sprites << [state.camera.x + circle.x + circle.angle.vector_x(circle.potential_lift * 10) - 5,
                          state.camera.y + circle.y + circle.angle.vector_y(circle.potential_lift * 10) - 5,
                          10, 10, 'sprites/circle-orange.png']
      outputs.sprites << [state.camera.x + circle.x + circle.angle.vector_x(circle.radius * 3) - 5,
                          state.camera.y + circle.y + circle.angle.vector_y(circle.radius * 3) - 5,
                          10, 10, 'sprites/circle-orange.png', 0, 128]
      if rand > 0.9
        outputs.sprites << [state.camera.x + circle.x + circle.angle.vector_x(circle.radius * 3) - 5,
                            state.camera.y + circle.y + circle.angle.vector_y(circle.radius * 3) - 5,
                            10, 10, 'sprites/circle-white.png', 0, 128]
      end
    end

    def render_circle
      outputs.sprites << circle.after_images.map do |ai|
        ai.merge(x: ai.x + state.camera.x - circle.radius,
                 y: ai.y + state.camera.y - circle.radius,
                 w: circle.radius * 2,
                 h: circle.radius * 2,
                 path: 'sprites/circle-white.png')
      end

      outputs.sprites << [(circle.x - circle.radius) + state.camera.x,
                          (circle.y - circle.radius) + state.camera.y,
                          circle.radius * 2,
                          circle.radius * 2,
                          'sprites/probe.png']
    end

    def render_debug
      return unless state.debug_mode

      outputs.labels << [10, 30, state.line_mode, 0, 0, 0, 0, 0]
      outputs.labels << [12, 32, state.line_mode, 0, 0, 255, 255, 255]

      args.outputs.lines << trajectory(circle).line.to_hash.tap do |h|
        h[:x] += state.camera.x
        h[:y] += state.camera.y
        h[:x2] += state.camera.x
        h[:y2] += state.camera.y
      end

      outputs.primitives << state.terrain.find_all do |t|
        circle.x.between?(t.x - 640, t.x2 + 640) || circle.y.between?(t.y - 360, t.y2 + 360)
      end.map do |t|
        [
          t.line.associate(r: 0, g: 255, b: 0) do |h|
            h.x  += state.camera.x
            h.y  += state.camera.y
            h.x2 += state.camera.x
            h.y2 += state.camera.y
            if circle.rect.intersect_rect? t[:rect]
              h[:r] = 255
              h[:g] = 0
            end
            h
          end,
          t[:rect].border.associate(r: 255, g: 0, b: 0) do |h|
            h.x += state.camera.x
            h.y += state.camera.y
            h.b = 255 if line_near_rect? circle.rect, t
            h
          end
        ]
      end

      outputs.primitives << state.lava.find_all do |t|
        circle.x.between?(t.x - 640, t.x2 + 640) || circle.y.between?(t.y - 360, t.y2 + 360)
      end.map do |t|
        [
          t.line.associate(r: 0, g: 0, b: 255) do |h|
            h.x  += state.camera.x
            h.y  += state.camera.y
            h.x2 += state.camera.x
            h.y2 += state.camera.y
            if circle.rect.intersect_rect? t[:rect]
              h[:r] = 255
              h[:b] = 0
            end
            h
          end,
          t[:rect].border.associate(r: 255, g: 0, b: 0) do |h|
            h.x += state.camera.x
            h.y += state.camera.y
            h.b = 255 if line_near_rect? circle.rect, t
            h
          end
        ]
      end

      if state.god_mode
        border = circle.rect.merge(x: circle.rect.x + state.camera.x,
                                   y: circle.rect.y + state.camera.y,
                                   g: 255)
      else
        border = circle.rect.merge(x: circle.rect.x + state.camera.x,
                                   y: circle.rect.y + state.camera.y,
                                   b: 255)
      end

      outputs.borders << border

      overlapping ||= {}

      circle.impact_history.each do |h|
        label_mod = 300
        x = (h[:body][:x].-(150).idiv(label_mod)) * label_mod + camera.x
        y = (h[:body][:y].+(150).idiv(label_mod)) * label_mod + camera.y
        10.times do
          if overlapping[x] && overlapping[x][y]
            y -= 52
          else
            break
          end
        end

        overlapping[x] ||= {}
        overlapping[x][y] ||= true
        outputs.primitives << [x, y - 25, 300, 50, 0, 0, 0, 128].solid
        outputs.labels << [x + 10, y + 24, "dy: %.2f" % h[:body][:new_dy], -2, 0, 255, 255, 255]
        outputs.labels << [x + 10, y +  9, "dx: %.2f" % h[:body][:new_dx], -2, 0, 255, 255, 255]
        outputs.labels << [x + 10, y -  5, " ?: #{h[:body][:new_reason]}", -2, 0, 255, 255, 255]

        outputs.labels << [x + 100, y + 24, "angle: %.2f" % h[:impact][:angle], -2, 0, 255, 255, 255]
        outputs.labels << [x + 100, y + 9, "m(l): %.2f" % h[:terrain][:slope], -2, 0, 255, 255, 255]
        outputs.labels << [x + 100, y - 5, "m(c): %.2f" % h[:body][:slope], -2, 0, 255, 255, 255]

        outputs.labels << [x + 200, y + 24, "ray: #{h[:impact][:ray]}", -2, 0, 255, 255, 255]
        outputs.labels << [x + 200, y +  9, "nxt: #{h[:impact][:ray_next]}", -2, 0, 255, 255, 255]
        outputs.labels << [x + 200, y -  5, "typ: #{h[:impact][:type]}", -2, 0, 255, 255, 255]
      end

      if circle.floor
        outputs.labels << [circle.x + camera.x + 30, circle.y + camera.y + 100, "point: #{circle.floor_point.slice(:x, :y).values}", -2, 0]
        outputs.labels << [circle.x + camera.x + 31, circle.y + camera.y + 101, "point: #{circle.floor_point.slice(:x, :y).values}", -2, 0, 255, 255, 255]
        outputs.labels << [circle.x + camera.x + 30, circle.y + camera.y +  85, "circle: #{circle.as_hash.slice(:x, :y).values}", -2, 0]
        outputs.labels << [circle.x + camera.x + 31, circle.y + camera.y +  86, "circle: #{circle.as_hash.slice(:x, :y).values}", -2, 0, 255, 255, 255]
        outputs.labels << [circle.x + camera.x + 30, circle.y + camera.y +  70, "rel: #{circle.floor_relative_x} #{circle.floor_relative_y}", -2, 0]
        outputs.labels << [circle.x + camera.x + 31, circle.y + camera.y +  71, "rel: #{circle.floor_relative_x} #{circle.floor_relative_y}", -2, 0, 255, 255, 255]
      end
    end

    def render_stage_editor
      return unless state.god_mode
      return unless state.point_one
      args.lines << [state.point_one, inputs.mouse.point, 0, 255, 255]
    end

    def trajectory body
      [body.x + body.dx,
       body.y + body.dy,
       body.x + body.dx * 1000,
       body.y + body.dy * 1000,
       0, 255, 255]
    end

    def lengthen_line line, num
      line = normalize_line(line)
      slope = geometry.line_slope(line, replace_infinity: 10).abs
      if slope < 2
        [line.x - num, line.y, line.x2 + num, line.y2].line.to_hash
      else
        [line.x, line.y, line.x2, line.y2].line.to_hash
      end
    end

    def normalize_line line
      if line.x > line.x2
        x  = line.x2
        y  = line.y2
        x2 = line.x
        y2 = line.y
      else
        x  = line.x
        y  = line.y
        x2 = line.x2
        y2 = line.y2
      end
      [x, y, x2, y2]
    end

    def rect_for_line line
      if line.x > line.x2
        x  = line.x2
        y  = line.y2
        x2 = line.x
        y2 = line.y
      else
        x  = line.x
        y  = line.y
        x2 = line.x2
        y2 = line.y2
      end

      w = x2 - x
      h = y2 - y

      if h < 0
        y += h
        h = h.abs
      end

      if w < circle.radius
        x -= circle.radius
        w = circle.radius * 2
      end

      if h < circle.radius
        y -= circle.radius
        h = circle.radius * 2
      end

      { x: x, y: y, w: w, h: h }
    end

    def snap_to_grid x, y, snaps
      snap_number = 10
      x = x.to_i
      y = y.to_i

      x_floor = x.idiv(snap_number) * snap_number
      x_mod   = x % snap_number
      x_ceil  = (x.idiv(snap_number) + 1) * snap_number

      y_floor = y.idiv(snap_number) * snap_number
      y_mod   = y % snap_number
      y_ceil  = (y.idiv(snap_number) + 1) * snap_number

      if snaps[x_floor]
        x_result = x_floor
      elsif snaps[x_ceil]
        x_result = x_ceil
      elsif x_mod < snap_number.idiv(2)
        x_result = x_floor
      else
        x_result = x_ceil
      end

      snaps[x_result] ||= {}

      if snaps[x_result][y_floor]
        y_result = y_floor
      elsif snaps[x_result][y_ceil]
        y_result = y_ceil
      elsif y_mod < snap_number.idiv(2)
        y_result = y_floor
      else
        y_result = y_ceil
      end

      snaps[x_result][y_result] = true
      return [x_result, y_result]

    end

    def snap_line line
      x, y, x2, y2 = line
    end

    def string_to_line s
      x, y, x2, y2 = s.split(',').map(&:to_f)

      if x > x2
        x2, x = x, x2
        y2, y = y, y2
      end

      x, y = snap_to_grid x, y, state.snaps
      x2, y2 = snap_to_grid x2, y2, state.snaps
      [x, y, x2, y2].line.to_hash
    end

    def load_lines file
      return unless state.snaps
      data = gtk.read_file(file) || ""
      data.each_line
          .reject { |l| l.strip.length == 0 }
          .map { |l| string_to_line l }
          .map { |h| h.merge(rect: rect_for_line(h))  }
    end

    def load_terrain
      load_lines 'data/level.txt'
    end

    def load_lava
      load_lines 'data/level_lava.txt'
    end

    def load_level force: false
      if force
        state.snaps = {}
        state.terrain = load_terrain
        state.lava = load_lava
      else
        state.terrain ||= load_terrain
        state.lava ||= load_lava
      end
    end

    def save_lines lines, file
      s = lines.map do |l|
        "#{l.x},#{l.y},#{l.x2},#{l.y2}"
      end.join("\n")
      gtk.write_file(file, s)
    end

    def save_level
      save_lines(state.terrain, 'level.txt')
      save_lines(state.lava, 'level_lava.txt')
      load_level force: true
    end

    def line_near_rect? rect, terrain
      geometry.intersect_rect?(rect, terrain[:rect])
    end

    def point_within_line? point, line
      return false if !point
      return false if !line
      return true
    end

    def calc_impacts x, dx, y, dy, radius
      results = { }
      results[:x] = x
      results[:y] = y
      results[:dx] = x
      results[:dy] = y
      results[:point] = { x: x, y: y }
      results[:rect] = { x: x - radius, y: y - radius, w: radius * 2, h: radius * 2 }
      results[:trajectory] = trajectory(results)
      results[:impacts] = terrain.find_all { |t| t && (line_near_rect? results[:rect], t) }.map do |t|
        intersection = geometry.ray_intersect(results[:trajectory], t)
        {
          terrain: t,
          point: geometry.ray_intersect(results[:trajectory], t),
          type: :terrain
        }
      end

      results[:impacts] += lava.find_all { |t| line_near_rect? results[:rect], t }.map do |t|
        intersection = geometry.ray_intersect(results[:trajectory], t)
        {
          terrain: t,
          point: geometry.ray_intersect(results[:trajectory], t),
          type: :lava
        }
      end

      results
    end

    def calc_potential_impacts
      impact_results = calc_impacts circle.x, circle.dx, circle.y, circle.dy, circle.radius
      circle.rect = impact_results[:rect]
      circle.trajectory = impact_results[:trajectory]
      circle.impacts = impact_results[:impacts]
    end

    def calc_terrains_to_monitor
      return unless circle.impacts
      circle.impact = nil
      circle.impacts.each do |i|
        future_circle = { x: circle.x + circle.dx, y: circle.y + circle.dy }
        circle.terrains_to_monitor[i[:terrain]] ||= {
          ray_start: geometry.ray_test(future_circle, i[:terrain]),
        }

        circle.terrains_to_monitor[i[:terrain]][:ray_current] = geometry.ray_test(future_circle, i[:terrain])
        if circle.terrains_to_monitor[i[:terrain]][:ray_start] != circle.terrains_to_monitor[i[:terrain]][:ray_current]
          circle.impact = i
          circle.ray_current = circle.terrains_to_monitor[i[:terrain]][:ray_current]
        end
      end
    end

    def impact_result body, impact
      infinity_alias = 1000
      r = {
        body: {},
        terrain: {},
        impact: {}
      }

      r[:body][:line] = body.trajectory.dup
      r[:body][:slope] = geometry.line_slope(body.trajectory, replace_infinity: infinity_alias)
      r[:body][:slope_sign] = r[:body][:slope].sign
      r[:body][:x] = body.x
      r[:body][:y] = body.y
      r[:body][:dy] = body.dy
      r[:body][:dx] = body.dx

      r[:terrain][:line] = impact[:terrain].dup
      r[:terrain][:slope] = geometry.line_slope(impact[:terrain], replace_infinity: infinity_alias)
      r[:terrain][:slope_sign] = r[:terrain][:slope].sign

      r[:impact][:angle] = -geometry.angle_between_lines(body.trajectory, impact[:terrain], replace_infinity: infinity_alias)
      r[:impact][:point] = { x: impact[:point].x, y: impact[:point].y }
      r[:impact][:same_slope_sign] = r[:body][:slope_sign] == r[:terrain][:slope_sign]
      r[:impact][:ray] = body.ray_current
      r[:body][:new_on_floor] = body.on_floor
      r[:body][:new_floor] = r[:terrain][:line]

      if r[:impact][:angle].abs < 90 && r[:terrain][:slope].abs < 3
        play_sound
        r[:body][:new_dy] = r[:body][:dy] * circle.elasticity * -1
        r[:body][:new_dx] = r[:body][:dx] * circle.elasticity
        r[:impact][:type] = :horizontal
        r[:body][:new_reason] = "-"
      elsif r[:impact][:angle].abs < 90 && r[:terrain][:slope].abs > 3
        play_sound
        r[:body][:new_dy] = r[:body][:dy] * 1.1
        r[:body][:new_dx] = r[:body][:dx] * -circle.elasticity
        r[:impact][:type] = :vertical
        r[:body][:new_reason] = "|"
      else
        play_sound
        r[:body][:new_dx] = r[:body][:dx] * -circle.elasticity
        r[:body][:new_dy] = r[:body][:dy] * -circle.elasticity
        r[:impact][:type] = :slanted
        r[:body][:new_reason] = "/"
      end

      r[:impact][:energy] = r[:body][:new_dx].abs + r[:body][:new_dy].abs

      if r[:impact][:energy] <= 0.3 && r[:terrain][:slope].abs < 4
        r[:body][:new_dx] = 0
        r[:body][:new_dy] = 0
        r[:impact][:energy] = 0
        r[:body][:new_on_floor] = true if r[:impact][:point].y < body.y
        r[:body][:new_floor] = r[:terrain][:line]
        r[:body][:new_reason] = "0"
      end

      r[:impact][:ray_next] = geometry.ray_test({ x: r[:body][:x] - (r[:body][:dx] * 1.1) + r[:body][:new_dx],
                                                  y: r[:body][:y] - (r[:body][:dy] * 1.1) + r[:body][:new_dy] + state.gravity },
                                                r[:terrain][:line])

      if r[:impact][:ray_next] == r[:impact][:ray]
        r[:body][:new_dx] *= -1
        r[:body][:new_dy] *= -1
        r[:body][:new_reason] = "clip"
      end

      r
    end

    def game_over!
      circle.x = circle.check_point_x
      circle.y = circle.check_point_y
      circle.dx = 0
      circle.dy = 0
      circle.game_over_at = Kernel.tick_count
    end

    def not_game_over!
      impact_history_entry = impact_result circle, circle.impact
      circle.impact_history << impact_history_entry
      circle.x -= circle.dx * 1.1
      circle.y -= circle.dy * 1.1
      circle.dx = impact_history_entry[:body][:new_dx]
      circle.dy = impact_history_entry[:body][:new_dy]
      circle.on_floor = impact_history_entry[:body][:new_on_floor]

      if circle.on_floor
        circle.check_point_at = Kernel.tick_count
        circle.check_point_x = circle.x
        circle.check_point_y = circle.y
      end

      circle.previous_floor = circle.floor || {}
      circle.floor = impact_history_entry[:body][:new_floor] || {}
      circle.floor_point = impact_history_entry[:impact][:point]
      if circle.floor.slice(:x, :y, :x2, :y2) != circle.previous_floor.slice(:x, :y, :x2, :y2)
        new_relative_x = if circle.dx > 0
                           :right
                         elsif circle.dx < 0
                           :left
                         else
                           nil
                         end

        new_relative_y = if circle.dy > 0
                           :above
                         elsif circle.dy < 0
                           :below
                         else
                           nil
                         end

        circle.floor_relative_x = new_relative_x
        circle.floor_relative_y = new_relative_y
      end

      circle.impact = nil
      circle.terrains_to_monitor.clear
    end

    def calc_physics
      if args.state.god_mode
        calc_potential_impacts
        calc_terrains_to_monitor
        return
      end

      if circle.y < -700
        game_over
        return
      end

      return if state.game_over
      return if circle.on_floor
      circle.previous_dy = circle.dy
      circle.previous_dx = circle.dx
      circle.x  += circle.dx
      circle.y  += circle.dy
      args.state.distance_traveled ||= 0
      args.state.distance_traveled += circle.dx.abs + circle.dy.abs
      circle.dy += state.gravity
      calc_potential_impacts
      calc_terrains_to_monitor
      return unless circle.impact
      if circle.impact && circle.impact[:type] == :lava
        game_over!
      else
        not_game_over!
      end
    end

    def input_god_mode
      state.debug_mode = !state.debug_mode if inputs.keyboard.key_down.forward_slash

      # toggle god mode
      if inputs.keyboard.key_down.g
        state.god_mode = !state.god_mode
        state.potential_lift = 0
        circle.floor = nil
        circle.floor_point = nil
        circle.floor_relative_x = nil
        circle.floor_relative_y = nil
        circle.impact = nil
        circle.terrains_to_monitor.clear
        return
      end

      return unless state.god_mode

      circle.x = circle.x.to_i
      circle.y = circle.y.to_i

      # move god circle
      if inputs.keyboard.left || inputs.keyboard.a
        circle.x -= 20
      elsif inputs.keyboard.right || inputs.keyboard.d || inputs.keyboard.f
        circle.x += 20
      end

      if inputs.keyboard.up || inputs.keyboard.w
        circle.y += 20
      elsif inputs.keyboard.down || inputs.keyboard.s
        circle.y -= 20
      end

      # delete terrain
      if inputs.keyboard.key_down.x
        calc_terrains_to_monitor
        state.terrain = state.terrain.reject do |t|
          t[:rect].intersect_rect? circle.rect
        end

        state.lava = state.lava.reject do |t|
          t[:rect].intersect_rect? circle.rect
        end

        calc_potential_impacts
        save_level
      end

      # change terrain type
      if inputs.keyboard.key_down.l
        if state.line_mode == :terrain
          state.line_mode = :lava
        else
          state.line_mode = :terrain
        end
      end

      if inputs.mouse.click && !state.point_one
        state.point_one = inputs.mouse.click.point
      elsif inputs.mouse.click && state.point_one
        l = [*state.point_one, *inputs.mouse.click.point]
        l = [l.x  - state.camera.x,
             l.y  - state.camera.y,
             l.x2 - state.camera.x,
             l.y2 - state.camera.y].line.to_hash
        l[:rect] = rect_for_line l
        if state.line_mode == :terrain
          state.terrain << l
        else
          state.lava << l
        end
        save_level
        next_x = inputs.mouse.click.point.x - 640
        next_y = inputs.mouse.click.point.y - 360
        circle.x += next_x
        circle.y += next_y
        state.point_one = nil
      elsif inputs.keyboard.one
        state.point_one = [circle.x + camera.x, circle.y+ camera.y]
      end

      # cancel chain lines
      if inputs.keyboard.key_down.nine || inputs.keyboard.key_down.escape || inputs.keyboard.key_up.six || inputs.keyboard.key_up.one
        state.point_one = nil
      end
    end

    def play_sound
      return if state.sound_debounce > 0
      state.sound_debounce = 5
      outputs.sounds << "sounds/03#{"%02d" % state.sound_index}.wav"
      state.sound_index += 1
      if state.sound_index > 21
        state.sound_index = 1
      end
    end

    def input_game
      if inputs.keyboard.down || inputs.keyboard.space
        circle.potential_lift += 0.03
        circle.potential_lift = circle.potential_lift.lesser(10)
      elsif inputs.keyboard.key_up.down || inputs.keyboard.key_up.space
        play_sound
        circle.dy += circle.angle.vector_y circle.potential_lift
        circle.dx += circle.angle.vector_x circle.potential_lift

        if circle.on_floor
          if circle.floor_relative_y == :above
            circle.y += circle.potential_lift.abs * 2
          elsif circle.floor_relative_y == :below
            circle.y -= circle.potential_lift.abs * 2
          end
        end

        circle.on_floor = false
        circle.potential_lift = 0
        circle.terrains_to_monitor.clear
        circle.impact_history.clear
        circle.impact = nil
        calc_physics
      end

      # aim probe
      if inputs.keyboard.right || inputs.keyboard.a
        circle.angle -= 2
      elsif inputs.keyboard.left || inputs.keyboard.d
        circle.angle += 2
      end
    end

    def input
      input_god_mode
      input_game
    end

    def calc_camera
      state.camera.target_x = 640 - circle.x
      state.camera.target_y = 360 - circle.y
      xdiff = state.camera.target_x - state.camera.x
      ydiff = state.camera.target_y - state.camera.y
      state.camera.x += xdiff * camera.follow_speed
      state.camera.y += ydiff * camera.follow_speed
    end

    def calc
      state.sound_debounce ||= 0
      state.sound_debounce -= 1
      state.sound_debounce = 0 if state.sound_debounce < 0
      if state.god_mode
        circle.dy *= 0.1
        circle.dx *= 0.1
      end
      calc_camera
      state.whisp_queue ||= []
      if Kernel.tick_count.mod_zero?(4)
        state.whisp_queue << {
          x: -300,
          y: 1400 * rand,
          speed: 2.randomize(:ratio) + 3,
          w: 20,
          h: 20, path: 'sprites/whisp.png',
          a: 0,
          created_at: Kernel.tick_count,
          angle: 0,
          r: 100,
          g: 128 + 128 * rand,
          b: 128 + 128 * rand
        }
      end

      state.whisp_queue.each do |w|
        w.x += w[:speed] * 2
        w.x -= circle.dx * 0.3
        w.y -= w[:speed]
        w.y -= circle.dy * 0.3
        w.angle += w[:speed]
        w.a = w[:created_at].ease(30) * 255
      end

      state.whisp_queue = state.whisp_queue.reject { |w| w[:x] > 1280 }

      if Kernel.tick_count.mod_zero?(2) && (circle.dx != 0 || circle.dy != 0)
        circle.after_images << {
          x: circle.x,
          y: circle.y,
          w: circle.radius,
          h: circle.radius,
          a: 255,
          created_at: Kernel.tick_count
        }
      end

      circle.after_images.each do |ai|
        ai.a = ai[:created_at].ease(10, :flip) * 255
      end

      circle.after_images = circle.after_images.reject { |ai| ai[:created_at].elapsed_time > 10 }
      calc_physics
    end

    def circle
      state.circle
    end

    def camera
      state.camera
    end

    def terrain
      state.terrain
    end

    def lava
      state.lava
    end
  end

  # $gtk.reset

  def tick args
    args.outputs.background_color = [0, 0, 0]
    if args.inputs.keyboard.r
      args.gtk.reset
      return
    end
    # uncomment the line below to slow down the game so you
    # can see each tick as it passes
    # args.gtk.slowmo! 30
    $game ||= FallingCircle.new
    $game.args = args
    $game.tick
  end

  def reset
    $game = nil
  end

```

### The Little Probe - Data - level.txt
```ruby
  # ./samples/99_genre_platformer/the_little_probe/data/level.txt
  640,8840,1180,8840
  -60,10220,0,9960
  -60,10220,0,10500
  0,10500,0,10780
  0,10780,40,10900
  500,10920,760,10960
  300,10560,820,10600
  420,10320,700,10300
  820,10600,1500,10600
  1500,10600,1940,10600
  1940,10600,2380,10580
  2380,10580,2800,10620
  2240,11080,2480,11020
  2000,11120,2240,11080
  1760,11180,2000,11120
  1620,11180,1760,11180
  1500,11220,1620,11180
  1180,11280,1340,11220
  1040,11240,1180,11280
  840,11280,1040,11240
  640,11280,840,11280
  500,11220,640,11280
  420,11140,500,11220
  240,11100,420,11140
  100,11120,240,11100
  0,11180,100,11120
  -160,11220,0,11180
  -260,11240,-160,11220
  1340,11220,1500,11220
  960,13300,1280,13060
  1280,13060,1540,12860
  1540,12860,1820,12700
  1820,12700,2080,12520
  2080,12520,2240,12400
  2240,12400,2240,12240
  2240,12240,2400,12080
  2400,12080,2560,11920
  2560,11920,2640,11740
  2640,11740,2740,11580
  2740,11580,2800,11400
  2800,11400,2800,11240
  2740,11140,2800,11240
  2700,11040,2740,11140
  2700,11040,2740,10960
  2740,10960,2740,10920
  2700,10900,2740,10920
  2380,10900,2700,10900
  2040,10920,2380,10900
  1720,10940,2040,10920
  1380,11000,1720,10940
  1180,10980,1380,11000
  900,10980,1180,10980
  760,10960,900,10980
  240,10960,500,10920
  40,10900,240,10960
  0,9700,0,9960
  -60,9500,0,9700
  -60,9420,-60,9500
  -60,9420,-60,9340
  -60,9340,-60,9280
  -60,9120,-60,9280
  -60,8940,-60,9120
  -60,8940,-60,8780
  -60,8780,0,8700
  0,8700,40,8680
  40,8680,240,8700
  240,8700,360,8780
  360,8780,640,8840
  1420,8400,1540,8480
  1540,8480,1680,8500
  1680,8500,1940,8460
  1180,8840,1280,8880
  1280,8880,1340,8860
  1340,8860,1720,8860
  1720,8860,1820,8920
  1820,8920,1820,9140
  1820,9140,1820,9280
  1820,9460,1820,9280
  1760,9480,1820,9460
  1640,9480,1760,9480
  1540,9500,1640,9480
  1340,9500,1540,9500
  1100,9500,1340,9500
  1040,9540,1100,9500
  960,9540,1040,9540
  300,9420,360,9460
  240,9440,300,9420
  180,9600,240,9440
  120,9660,180,9600
  100,9820,120,9660
  100,9820,120,9860
  120,9860,140,9900
  140,9900,140,10000
  140,10440,180,10540
  100,10080,140,10000
  100,10080,140,10100
  140,10100,140,10440
  180,10540,300,10560
  2140,9560,2140,9640
  2140,9720,2140,9640
  1880,9780,2140,9720
  1720,9780,1880,9780
  1620,9740,1720,9780
  1500,9780,1620,9740
  1380,9780,1500,9780
  1340,9820,1380,9780
  1200,9820,1340,9820
  1100,9780,1200,9820
  900,9780,1100,9780
  820,9720,900,9780
  540,9720,820,9720
  360,9840,540,9720
  360,9840,360,9960
  360,9960,360,10080
  360,10140,360,10080
  360,10140,360,10240
  360,10240,420,10320
  700,10300,820,10280
  820,10280,820,10280
  820,10280,900,10320
  900,10320,1040,10300
  1040,10300,1200,10320
  1200,10320,1380,10280
  1380,10280,1500,10300
  1500,10300,1760,10300
  2800,10620,2840,10600
  2840,10600,2900,10600
  2900,10600,3000,10620
  3000,10620,3080,10620
  3080,10620,3140,10600
  3140,10540,3140,10600
  3140,10540,3140,10460
  3140,10460,3140,10360
  3140,10360,3140,10260
  3140,10260,3140,10140
  3140,10140,3140,10000
  3140,10000,3140,9860
  3140,9860,3160,9720
  3160,9720,3160,9580
  3160,9580,3160,9440
  3160,9300,3160,9440
  3160,9300,3160,9140
  3160,9140,3160,8980
  3160,8980,3160,8820
  3160,8820,3160,8680
  3160,8680,3160,8520
  1760,10300,1880,10300
  660,9500,960,9540
  640,9460,660,9500
  360,9460,640,9460
  -480,10760,-440,10880
  -480,11020,-440,10880
  -480,11160,-260,11240
  -480,11020,-480,11160
  -600,11420,-380,11320
  -380,11320,-200,11340
  -200,11340,0,11340
  0,11340,180,11340
  960,13420,960,13300
  960,13420,960,13520
  960,13520,1000,13560
  1000,13560,1040,13540
  1040,13540,1200,13440
  1200,13440,1380,13380
  1380,13380,1620,13300
  1620,13300,1820,13220
  1820,13220,2000,13200
  2000,13200,2240,13200
  2240,13200,2440,13160
  2440,13160,2640,13040
  -480,10760,-440,10620
  -440,10620,-360,10560
  -380,10460,-360,10560
  -380,10460,-360,10300
  -380,10140,-360,10300
  -380,10140,-380,10040
  -380,9880,-380,10040
  -380,9720,-380,9880
  -380,9720,-380,9540
  -380,9360,-380,9540
  -380,9180,-380,9360
  -380,9180,-380,9000
  -380,8840,-380,9000
  -380,8840,-380,8760
  -380,8760,-380,8620
  -380,8620,-380,8520
  -380,8520,-360,8400
  -360,8400,-100,8400
  -100,8400,-60,8420
  -60,8420,240,8440
  240,8440,240,8380
  240,8380,500,8440
  500,8440,760,8460
  760,8460,1000,8400
  1000,8400,1180,8420
  1180,8420,1420,8400
  1940,8460,2140,8420
  2140,8420,2200,8520
  2200,8680,2200,8520
  2140,8840,2200,8680
  2140,8840,2140,9020
  2140,9100,2140,9020
  2140,9200,2140,9100
  2140,9200,2200,9320
  2200,9320,2200,9440
  2140,9560,2200,9440
  1880,10300,2200,10280
  2200,10280,2480,10260
  2480,10260,2700,10240
  2700,10240,2840,10180
  2840,10180,2900,10060
  2900,9860,2900,10060
  2900,9640,2900,9860
  2900,9640,2900,9500
  2900,9460,2900,9500
  2740,9460,2900,9460
  2700,9460,2740,9460
  2700,9360,2700,9460
  2700,9320,2700,9360
  2600,9320,2700,9320
  2600,9260,2600,9320
  2600,9200,2600,9260
  2480,9120,2600,9200
  2440,9080,2480,9120
  2380,9080,2440,9080
  2320,9060,2380,9080
  2320,8860,2320,9060
  2320,8860,2380,8840
  2380,8840,2480,8860
  2480,8860,2600,8840
  2600,8840,2740,8840
  2740,8840,2840,8800
  2840,8800,2900,8700
  2900,8600,2900,8700
  2900,8480,2900,8600
  2900,8380,2900,8480
  2900,8380,2900,8260
  2900,8260,2900,8140
  2900,8140,2900,8020
  2900,8020,2900,7900
  2900,7820,2900,7900
  2900,7820,2900,7740
  2900,7660,2900,7740
  2900,7560,2900,7660
  2900,7460,2900,7560
  2900,7460,2900,7360
  2900,7260,2900,7360
  2840,7160,2900,7260
  2800,7080,2840,7160
  2700,7100,2800,7080
  2560,7120,2700,7100
  2400,7100,2560,7120
  2320,7100,2400,7100
  2140,7100,2320,7100
  2040,7080,2140,7100
  1940,7080,2040,7080
  1820,7140,1940,7080
  1680,7140,1820,7140
  1540,7140,1680,7140
  1420,7220,1540,7140
  1280,7220,1380,7220
  1140,7200,1280,7220
  1000,7220,1140,7200
  760,7280,900,7320
  540,7220,760,7280
  300,7180,540,7220
  180,7120,180,7160
  40,7140,180,7120
  -60,7160,40,7140
  -200,7120,-60,7160
  180,7160,300,7180
  -260,7060,-200,7120
  -260,6980,-260,7060
  -260,6880,-260,6980
  -260,6880,-260,6820
  -260,6820,-200,6760
  -200,6760,-100,6740
  -100,6740,-60,6740
  -60,6740,40,6740
  40,6740,300,6800
  300,6800,420,6760
  420,6760,500,6740
  500,6740,540,6760
  540,6760,540,6760
  540,6760,640,6780
  640,6660,640,6780
  580,6580,640,6660
  580,6440,580,6580
  580,6440,640,6320
  640,6320,640,6180
  580,6080,640,6180
  580,6080,640,5960
  640,5960,640,5840
  640,5840,640,5700
  640,5700,660,5560
  660,5560,660,5440
  660,5440,660,5300
  660,5140,660,5300
  660,5140,660,5000
  660,5000,660,4880
  660,4880,820,4860
  820,4860,1000,4840
  1000,4840,1100,4860
  1100,4860,1280,4860
  1280,4860,1420,4840
  1420,4840,1580,4860
  1580,4860,1720,4820
  1720,4820,1880,4860
  1880,4860,2000,4840
  2000,4840,2140,4840
  2140,4840,2320,4860
  2320,4860,2440,4880
  2440,4880,2600,4880
  2600,4880,2800,4880
  2800,4880,2900,4880
  2900,4880,2900,4820
  2900,4740,2900,4820
  2800,4700,2900,4740
  2520,4680,2800,4700
  2240,4660,2520,4680
  1940,4620,2240,4660
  1820,4580,1940,4620
  1820,4500,1820,4580
  1820,4500,1880,4420
  1880,4420,2000,4420
  2000,4420,2200,4420
  2200,4420,2400,4440
  2400,4440,2600,4440
  2600,4440,2840,4440
  2840,4440,2900,4400
  2740,4260,2900,4280
  2600,4240,2740,4260
  2480,4280,2600,4240
  2320,4240,2480,4280
  2140,4220,2320,4240
  1940,4220,2140,4220
  1880,4160,1940,4220
  1880,4160,1880,4080
  1880,4080,2040,4040
  2040,4040,2240,4060
  2240,4060,2400,4040
  2400,4040,2600,4060
  2600,4060,2740,4020
  2740,4020,2840,3940
  2840,3780,2840,3940
  2740,3660,2840,3780
  2700,3680,2740,3660
  2520,3700,2700,3680
  2380,3700,2520,3700
  2200,3720,2380,3700
  2040,3720,2200,3720
  1880,3700,2040,3720
  1820,3680,1880,3700
  1760,3600,1820,3680
  1760,3600,1820,3480
  1820,3480,1880,3440
  1880,3440,1960,3460
  1960,3460,2140,3460
  2140,3460,2380,3460
  2380,3460,2640,3440
  2640,3440,2900,3380
  2840,3280,2900,3380
  2840,3280,2900,3200
  2900,3200,2900,3140
  2840,3020,2900,3140
  2800,2960,2840,3020
  2700,3000,2800,2960
  2600,2980,2700,3000
  2380,3000,2600,2980
  2140,3000,2380,3000
  1880,3000,2140,3000
  1720,3040,1880,3000
  1640,2960,1720,3040
  1500,2940,1640,2960
  1340,3000,1500,2940
  1240,3000,1340,3000
  1140,3020,1240,3000
  1040,3000,1140,3020
  960,2960,1040,3000
  900,2960,960,2960
  840,2840,900,2960
  700,2820,840,2840
  540,2820,700,2820
  420,2820,540,2820
  180,2800,420,2820
  60,2780,180,2800
  -60,2800,60,2780
  -160,2760,-60,2800
  -260,2740,-160,2760
  -300,2640,-260,2740
  -360,2560,-300,2640
  -380,2460,-360,2560
  -380,2460,-300,2380
  -300,2300,-300,2380
  -300,2300,-300,2220
  -300,2100,-300,2220
  -300,2100,-300,2040
  -300,2040,-160,2040
  -160,2040,-60,2040
  -60,2040,60,2040
  60,2040,180,2040
  180,2040,360,2040
  360,2040,540,2040
  540,2040,700,2080
  660,2160,700,2080
  660,2160,700,2260
  660,2380,700,2260
  500,2340,660,2380
  360,2340,500,2340
  240,2340,360,2340
  40,2320,240,2340
  -60,2320,40,2320
  -100,2380,-60,2320
  -100,2380,-100,2460
  -100,2460,-100,2540
  -100,2540,0,2560
  0,2560,140,2600
  140,2600,300,2600
  300,2600,460,2600
  460,2600,640,2600
  640,2600,760,2580
  760,2580,820,2560
  820,2560,820,2500
  820,2500,820,2400
  820,2400,840,2320
  840,2320,840,2240
  820,2120,840,2240
  820,2020,820,2120
  820,1900,820,2020
  760,1840,820,1900
  640,1840,760,1840
  500,1840,640,1840
  300,1860,420,1880
  180,1840,300,1860
  420,1880,500,1840
  0,1840,180,1840
  -60,1860,0,1840
  -160,1840,-60,1860
  -200,1800,-160,1840
  -260,1760,-200,1800
  -260,1680,-260,1760
  -260,1620,-260,1680
  -260,1540,-260,1620
  -260,1540,-260,1460
  -300,1420,-260,1460
  -300,1420,-300,1340
  -300,1340,-260,1260
  -260,1260,-260,1160
  -260,1060,-260,1160
  -260,1060,-260,960
  -260,880,-260,960
  -260,880,-260,780
  -260,780,-260,680
  -300,580,-260,680
  -300,580,-300,480
  -300,480,-260,400
  -300,320,-260,400
  -300,320,-300,240
  -300,240,-200,220
  -200,220,-200,160
  -200,160,-100,140
  -100,140,0,120
  0,120,60,120
  60,120,180,120
  180,120,300,120
  300,120,420,140
  420,140,580,180
  580,180,760,180
  760,180,900,180
  960,180,1100,180
  1100,180,1340,200
  1340,200,1580,200
  1580,200,1720,180
  1720,180,2000,140
  2000,140,2240,140
  2240,140,2480,140
  2520,140,2800,160
  2800,160,3000,160
  3000,160,3140,160
  3140,260,3140,160
  3140,260,3140,380
  3080,500,3140,380
  3080,620,3080,500
  3080,620,3080,740
  3080,740,3080,840
  3080,960,3080,840
  3080,1080,3080,960
  3080,1080,3080,1200
  3080,1200,3080,1340
  3080,1340,3080,1460
  3080,1580,3080,1460
  3080,1700,3080,1580
  3080,1700,3080,1760
  3080,1760,3200,1760
  3200,1760,3320,1760
  3320,1760,3520,1760
  3520,1760,3680,1740
  3680,1740,3780,1700
  3780,1700,3840,1620
  3840,1620,3840,1520
  3840,1520,3840,1420
  3840,1320,3840,1420
  3840,1120,3840,1320
  3840,1120,3840,940
  3840,940,3840,760
  3780,600,3840,760
  3780,600,3780,440
  3780,320,3780,440
  3780,320,3780,160
  3780,60,3780,160
  3780,60,4020,60
  4020,60,4260,40
  4260,40,4500,40
  4500,40,4740,40
  4740,40,4840,20
  4840,20,4880,80
  4880,80,5080,40
  5080,40,5280,20
  5280,20,5500,0
  5500,0,5720,0
  5720,0,5940,60
  5940,60,6240,60
  6240,60,6540,20
  6540,20,6840,20
  6840,20,7040,0
  7040,0,7140,0
  7140,0,7400,20
  7400,20,7680,0
  7680,0,7940,0
  7940,0,8200,-20
  8200,-20,8360,20
  8360,20,8560,-40
  8560,-40,8760,0
  8760,0,8880,40
  8880,120,8880,40
  8840,220,8840,120
  8620,240,8840,220
  8420,260,8620,240
  8200,280,8420,260
  7940,280,8200,280
  7760,240,7940,280
  7560,220,7760,240
  7360,280,7560,220
  7140,260,7360,280
  6940,240,7140,260
  6720,220,6940,240
  6480,220,6720,220
  6360,300,6480,220
  6240,300,6360,300
  6200,500,6240,300
  6200,500,6360,540
  6360,540,6540,520
  6540,520,6720,480
  6720,480,6880,460
  6880,460,7080,500
  7080,500,7320,500
  7320,500,7680,500
  7680,620,7680,500
  7520,640,7680,620
  7360,640,7520,640
  7200,640,7360,640
  7040,660,7200,640
  6880,720,7040,660
  6720,700,6880,720
  6540,700,6720,700
  6420,760,6540,700
  6280,740,6420,760
  6240,760,6280,740
  6200,920,6240,760
  6200,920,6360,960
  6360,960,6540,960
  6540,960,6720,960
  6720,960,6760,980
  6760,980,6880,940
  6880,940,7080,940
  7080,940,7280,940
  7280,940,7520,920
  7520,920,7760,900
  7760,900,7980,860
  7980,860,8100,880
  8100,880,8280,900
  8280,900,8500,820
  8500,820,8700,820
  8700,820,8760,840
  8760,960,8760,840
  8700,1040,8760,960
  8560,1060,8700,1040
  8460,1080,8560,1060
  8360,1040,8460,1080
  8280,1080,8360,1040
  8160,1120,8280,1080
  8040,1120,8160,1120
  7940,1100,8040,1120
  7800,1120,7940,1100
  7680,1120,7800,1120
  7520,1100,7680,1120
  7360,1100,7520,1100
  7200,1120,7360,1100
  7040,1180,7200,1120
  6880,1160,7040,1180
  6720,1160,6880,1160
  6540,1160,6720,1160
  6360,1160,6540,1160
  6200,1160,6360,1160
  6040,1220,6200,1160
  6040,1220,6040,1400
  6040,1400,6200,1440
  6200,1440,6320,1440
  6320,1440,6440,1440
  6600,1440,6760,1440
  6760,1440,6940,1420
  6440,1440,6600,1440
  6940,1420,7280,1400
  7280,1400,7560,1400
  7560,1400,7760,1400
  7760,1400,7940,1360
  7940,1360,8100,1380
  8100,1380,8280,1340
  8280,1340,8460,1320
  8660,1300,8760,1360
  8460,1320,8660,1300
  8760,1360,8800,1500
  8800,1660,8800,1500
  8800,1660,8800,1820
  8700,1840,8800,1820
  8620,1860,8700,1840
  8560,1800,8620,1860
  8560,1800,8620,1680
  8500,1640,8620,1680
  8420,1680,8500,1640
  8280,1680,8420,1680
  8160,1680,8280,1680
  7900,1680,8160,1680
  7680,1680,7900,1680
  7400,1660,7680,1680
  7140,1680,7400,1660
  6880,1640,7140,1680
  6040,1820,6320,1780
  5900,1840,6040,1820
  6640,1700,6880,1640
  6320,1780,6640,1700
  5840,2040,5900,1840
  5840,2040,5840,2220
  5840,2220,5840,2320
  5840,2460,5840,2320
  5840,2560,5840,2460
  5840,2560,5960,2620
  5960,2620,6200,2620
  6200,2620,6380,2600
  6380,2600,6600,2580
  6600,2580,6800,2600
  6800,2600,7040,2580
  7040,2580,7280,2580
  7280,2580,7480,2560
  7760,2540,7980,2520
  7980,2520,8160,2500
  7480,2560,7760,2540
  8160,2500,8160,2420
  8160,2420,8160,2320
  8160,2180,8160,2320
  7980,2160,8160,2180
  7800,2180,7980,2160
  7600,2200,7800,2180
  7400,2200,7600,2200
  6960,2200,7200,2200
  7200,2200,7400,2200
  6720,2200,6960,2200
  6540,2180,6720,2200
  6320,2200,6540,2180
  6240,2160,6320,2200
  6240,2160,6240,2040
  6240,2040,6240,1940
  6240,1940,6440,1940
  6440,1940,6720,1940
  6720,1940,6940,1920
  7520,1920,7760,1920
  6940,1920,7280,1920
  7280,1920,7520,1920
  7760,1920,8100,1900
  8100,1900,8420,1900
  8420,1900,8460,1940
  8460,2120,8460,1940
  8460,2280,8460,2120
  8460,2280,8560,2420
  8560,2420,8660,2380
  8660,2380,8800,2340
  8800,2340,8840,2400
  8840,2520,8840,2400
  8800,2620,8840,2520
  8800,2740,8800,2620
  8800,2860,8800,2740
  8800,2940,8800,2860
  8760,2980,8800,2940
  8660,2980,8760,2980
  8620,2960,8660,2980
  8560,2880,8620,2960
  8560,2880,8560,2780
  8500,2740,8560,2780
  8420,2760,8500,2740
  8420,2840,8420,2760
  8420,2840,8420,2940
  8420,3040,8420,2940
  8420,3160,8420,3040
  8420,3280,8420,3380
  8420,3280,8420,3160
  8420,3380,8620,3460
  8620,3460,8760,3460
  8760,3460,8840,3400
  8840,3400,8960,3400
  8960,3400,9000,3500
  9000,3700,9000,3500
  9000,3900,9000,3700
  9000,4080,9000,3900
  9000,4280,9000,4080
  9000,4500,9000,4280
  9000,4620,9000,4500
  9000,4780,9000,4620
  9000,4780,9000,4960
  9000,5120,9000,4960
  9000,5120,9000,5300
  8960,5460,9000,5300
  8920,5620,8960,5460
  8920,5620,8920,5800
  8920,5800,8920,5960
  8920,5960,8920,6120
  8920,6120,8960,6300
  8960,6300,8960,6480
  8960,6660,8960,6480
  8960,6860,8960,6660
  8960,7040,8960,6860
  8920,7420,8920,7220
  8920,7420,8960,7620
  8960,7620,8960,7800
  8960,7800,8960,8000
  8960,8000,8960,8180
  8960,8180,8960,8380
  8960,8580,8960,8380
  8920,8800,8960,8580
  8880,9000,8920,8800
  8840,9180,8880,9000
  8800,9220,8840,9180
  8800,9220,8840,9340
  8760,9380,8840,9340
  8560,9340,8760,9380
  8360,9360,8560,9340
  8160,9360,8360,9360
  8040,9340,8160,9360
  7860,9360,8040,9340
  7680,9360,7860,9360
  7520,9360,7680,9360
  7420,9260,7520,9360
  7400,9080,7420,9260
  7400,9080,7420,8860
  7420,8860,7440,8720
  7440,8720,7480,8660
  7480,8660,7520,8540
  7520,8540,7600,8460
  7600,8460,7800,8480
  7800,8480,8040,8480
  8040,8480,8280,8480
  8280,8480,8500,8460
  8500,8460,8620,8440
  8620,8440,8660,8340
  8660,8340,8660,8220
  8660,8220,8700,8080
  8700,8080,8700,7920
  8700,7920,8700,7760
  8700,7760,8700,7620
  8700,7480,8700,7620
  8700,7480,8700,7320
  8700,7160,8700,7320
  8920,7220,8960,7040
  8660,7040,8700,7160
  8660,7040,8700,6880
  8660,6700,8700,6880
  8660,6700,8700,6580
  8700,6460,8700,6580
  8700,6460,8700,6320
  8700,6160,8700,6320
  8700,6160,8760,6020
  8760,6020,8760,5860
  8760,5860,8760,5700
  8760,5700,8760,5540
  8760,5540,8760,5360
  8760,5360,8760,5180
  8760,5000,8760,5180
  8700,4820,8760,5000
  8560,4740,8700,4820
  8420,4700,8560,4740
  8280,4700,8420,4700
  8100,4700,8280,4700
  7980,4700,8100,4700
  7820,4740,7980,4700
  7800,4920,7820,4740
  7800,4920,7900,4960
  7900,4960,8060,4980
  8060,4980,8220,5000
  8220,5000,8420,5040
  8420,5040,8460,5120
  8460,5180,8460,5120
  8360,5200,8460,5180
  8360,5280,8360,5200
  8160,5300,8360,5280
  8040,5260,8160,5300
  7860,5220,8040,5260
  7720,5160,7860,5220
  7640,5120,7720,5160
  7480,5120,7640,5120
  7240,5120,7480,5120
  7000,5120,7240,5120
  6800,5160,7000,5120
  6640,5220,6800,5160
  6600,5360,6640,5220
  6600,5460,6600,5360
  6480,5520,6600,5460
  6240,5540,6480,5520
  5980,5540,6240,5540
  5740,5540,5980,5540
  5500,5520,5740,5540
  5400,5520,5500,5520
  5280,5540,5400,5520
  5080,5540,5280,5540
  4940,5540,5080,5540
  4760,5540,4940,5540
  4600,5540,4760,5540
  4440,5560,4600,5540
  4040,5580,4120,5520
  4260,5540,4440,5560
  4120,5520,4260,5540
  4020,5720,4040,5580
  4020,5840,4020,5720
  4020,5840,4080,5940
  4080,5940,4120,6040
  4120,6040,4200,6080
  4200,6080,4340,6080
  4340,6080,4500,6060
  4500,6060,4700,6060
  4700,6060,4880,6060
  4880,6060,5080,6060
  5080,6060,5280,6080
  5280,6080,5440,6100
  5440,6100,5660,6100
  5660,6100,5900,6080
  5900,6080,6120,6080
  6120,6080,6360,6080
  6360,6080,6480,6100
  6480,6100,6540,6060
  6540,6060,6720,6060
  6720,6060,6940,6060
  6940,6060,7140,6060
  7400,6060,7600,6060
  7140,6060,7400,6060
  7600,6060,7800,6060
  7800,6060,7860,6080
  7860,6080,8060,6080
  8060,6080,8220,6080
  8220,6080,8320,6140
  8320,6140,8360,6300
  8320,6460,8360,6300
  8320,6620,8320,6460
  8320,6800,8320,6620
  8320,6960,8320,6800
  8320,6960,8360,7120
  8320,7280,8360,7120
  8320,7440,8320,7280
  8320,7600,8320,7440
  8100,7580,8220,7600
  8220,7600,8320,7600
  7900,7560,8100,7580
  7680,7560,7900,7560
  7480,7580,7680,7560
  7280,7580,7480,7580
  7080,7580,7280,7580
  7000,7600,7080,7580
  6880,7600,7000,7600
  6800,7580,6880,7600
  6640,7580,6800,7580
  6540,7580,6640,7580
  6380,7600,6540,7580
  6280,7620,6380,7600
  6240,7700,6280,7620
  6240,7700,6240,7800
  6240,7840,6240,7800
  6080,7840,6240,7840
  5960,7820,6080,7840
  5660,7840,5800,7840
  5500,7800,5660,7840
  5440,7700,5500,7800
  5800,7840,5960,7820
  5440,7540,5440,7700
  5440,7440,5440,7540
  5440,7320,5440,7440
  5400,7320,5440,7320
  5340,7400,5400,7320
  5340,7400,5340,7500
  5340,7600,5340,7500
  5340,7600,5340,7720
  5340,7720,5340,7860
  5340,7860,5340,7960
  5340,7960,5440,8020
  5440,8020,5560,8020
  5560,8020,5720,8040
  5720,8040,5900,8060
  5900,8060,6080,8060
  6080,8060,6240,8060
  6720,8040,6840,8060
  6240,8060,6480,8040
  6480,8040,6720,8040
  6840,8060,6940,8060
  6940,8060,7080,8120
  7080,8120,7140,8180
  7140,8460,7140,8320
  7140,8620,7140,8460
  7140,8620,7140,8740
  7140,8860,7140,8740
  7140,8960,7140,8860
  7140,8960,7200,9080
  7140,9200,7200,9080
  7140,9200,7200,9320
  7200,9320,7200,9460
  7200,9760,7200,9900
  7200,9620,7200,9460
  7200,9620,7200,9760
  7200,9900,7200,10060
  7200,10220,7200,10060
  7200,10360,7200,10220
  7140,10400,7200,10360
  6880,10400,7140,10400
  6640,10360,6880,10400
  6420,10360,6640,10360
  6160,10380,6420,10360
  5940,10340,6160,10380
  5720,10320,5940,10340
  5500,10340,5720,10320
  5280,10300,5500,10340
  5080,10300,5280,10300
  4840,10280,5080,10300
  4700,10280,4840,10280
  4540,10280,4700,10280
  4360,10280,4540,10280
  4200,10300,4360,10280
  4040,10380,4200,10300
  4020,10500,4040,10380
  3980,10640,4020,10500
  3980,10640,3980,10760
  3980,10760,4020,10920
  4020,10920,4080,11000
  4080,11000,4340,11020
  4340,11020,4600,11060
  4600,11060,4840,11040
  4840,11040,4880,10960
  4880,10740,4880,10960
  4880,10740,4880,10600
  4880,10600,5080,10560
  5080,10560,5340,10620
  5340,10620,5660,10620
  5660,10620,6040,10600
  6040,10600,6120,10620
  6120,10620,6240,10720
  6240,10720,6420,10740
  6420,10740,6640,10760
  6640,10760,6880,10780
  7140,10780,7400,10780
  6880,10780,7140,10780
  7400,10780,7680,10780
  7680,10780,8100,10760
  8100,10760,8460,10740
  8460,10740,8700,10760
  8800,10840,8800,10980
  8700,10760,8800,10840
  8760,11200,8800,10980
  8760,11200,8760,11380
  8760,11380,8800,11560
  8760,11680,8800,11560
  8760,11760,8760,11680
  8760,11760,8760,11920
  8760,11920,8800,12080
  8800,12200,8800,12080
  8700,12240,8800,12200
  8560,12220,8700,12240
  8360,12220,8560,12220
  8160,12240,8360,12220
  7720,12220,7980,12220
  7980,12220,8160,12240
  7400,12200,7720,12220
  7200,12180,7400,12200
  7000,12160,7200,12180
  6800,12160,7000,12160
  6280,12140,6380,12180
  6120,12180,6280,12140
  6540,12180,6800,12160
  6380,12180,6540,12180
  5900,12200,6120,12180
  5620,12180,5900,12200
  5340,12120,5620,12180
  5140,12100,5340,12120
  4980,12120,5140,12100
  4840,12120,4980,12120
  4700,12200,4840,12120
  4700,12380,4700,12200
  4740,12480,4940,12520
  4700,12380,4740,12480
  4940,12520,5160,12560
  5160,12560,5340,12600
  5340,12600,5400,12600
  5400,12600,5500,12600
  5500,12600,5620,12600
  5620,12600,5720,12560
  5720,12560,5800,12440
  5800,12440,5900,12380
  5900,12380,6120,12420
  6120,12420,6380,12440
  6380,12440,6600,12460
  6720,12460,6840,12520
  6840,12520,6960,12520
  6600,12460,6720,12460
  6960,12520,7040,12500
  7040,12500,7140,12440
  7200,12440,7360,12500
  7360,12500,7600,12560
  7600,12560,7860,12600
  7860,12600,8060,12500
  8100,12500,8200,12340
  8200,12340,8360,12360
  8360,12360,8560,12400
  8560,12400,8660,12420
  8660,12420,8840,12400
  8840,12400,9000,12360
  9000,12360,9000,12360
  2900,4400,2900,4280
  900,7320,1000,7220
  2640,13040,2900,12920
  2900,12920,3160,12840
  3480,12760,3780,12620
  3780,12620,4020,12460
  4300,12360,4440,12260
  4020,12460,4300,12360
  3160,12840,3480,12760
  4440,12080,4440,12260
  4440,12080,4440,11880
  4440,11880,4440,11720
  4440,11720,4600,11720
  4600,11720,4760,11740
  4760,11740,4980,11760
  4980,11760,5160,11760
  5160,11760,5340,11780
  6000,11860,6120,11820
  5340,11780,5620,11820
  5620,11820,6000,11860
  6120,11820,6360,11820
  6360,11820,6640,11860
  6940,11920,7240,11940
  7240,11940,7520,11960
  7520,11960,7860,11960
  7860,11960,8100,11920
  8100,11920,8420,11940
  8420,11940,8460,11960
  8460,11960,8500,11860
  8460,11760,8500,11860
  8320,11720,8460,11760
  8160,11720,8320,11720
  7940,11720,8160,11720
  7720,11700,7940,11720
  7520,11680,7720,11700
  7320,11680,7520,11680
  7200,11620,7320,11680
  7200,11620,7200,11500
  7200,11500,7280,11440
  7280,11440,7420,11440
  7420,11440,7600,11440
  7600,11440,7980,11460
  7980,11460,8160,11460
  8160,11460,8360,11460
  8360,11460,8460,11400
  8420,11060,8500,11200
  8280,11040,8420,11060
  8100,11060,8280,11040
  8460,11400,8500,11200
  7800,11060,8100,11060
  7520,11060,7800,11060
  7240,11060,7520,11060
  6940,11040,7240,11060
  6640,11000,6940,11040
  6420,10980,6640,11000
  6360,11060,6420,10980
  6360,11180,6360,11060
  6200,11280,6360,11180
  5960,11300,6200,11280
  5720,11280,5960,11300
  5500,11280,5720,11280
  4940,11300,5200,11280
  4660,11260,4940,11300
  4440,11280,4660,11260
  4260,11280,4440,11280
  4220,11220,4260,11280
  4080,11280,4220,11220
  3980,11420,4080,11280
  3980,11420,4040,11620
  4040,11620,4040,11820
  3980,11960,4040,11820
  3840,12000,3980,11960
  3720,11940,3840,12000
  3680,11800,3720,11940
  3680,11580,3680,11800
  3680,11360,3680,11580
  3680,11360,3680,11260
  3680,11080,3680,11260
  3680,11080,3680,10880
  3680,10700,3680,10880
  3680,10700,3680,10620
  3680,10480,3680,10620
  3680,10480,3680,10300
  3680,10300,3680,10100
  3680,10100,3680,9940
  3680,9940,3720,9860
  3720,9860,3920,9900
  3920,9900,4220,9880
  4980,9940,5340,9960
  4220,9880,4540,9900
  4540,9900,4980,9940
  5340,9960,5620,9960
  5620,9960,5900,9960
  5900,9960,6160,10000
  6160,10000,6480,10000
  6480,10000,6720,10000
  6720,10000,6880,9860
  6880,9860,6880,9520
  6880,9520,6940,9340
  6940,9120,6940,9340
  6940,9120,6940,8920
  6940,8700,6940,8920
  6880,8500,6940,8700
  6880,8320,6880,8500
  7140,8320,7140,8180
  6760,8260,6880,8320
  6540,8240,6760,8260
  6420,8180,6540,8240
  6280,8240,6420,8180
  6160,8300,6280,8240
  6120,8400,6160,8300
  6080,8520,6120,8400
  5840,8480,6080,8520
  5620,8500,5840,8480
  5500,8500,5620,8500
  5340,8560,5500,8500
  5160,8540,5340,8560
  4620,8520,4880,8520
  4360,8480,4620,8520
  4880,8520,5160,8540
  4140,8440,4360,8480
  3920,8460,4140,8440
  3720,8380,3920,8460
  3680,8160,3720,8380
  3680,8160,3720,7940
  3720,7720,3720,7940
  3680,7580,3720,7720
  3680,7580,3720,7440
  3720,7440,3720,7300
  3720,7160,3720,7300
  3720,7160,3720,7020
  3720,7020,3780,6900
  3780,6900,4080,6940
  4080,6940,4340,6980
  4340,6980,4600,6980
  4600,6980,4880,6980
  4880,6980,5160,6980
  5160,6980,5400,7000
  5400,7000,5560,7020
  5560,7020,5660,7080
  5660,7080,5660,7280
  5660,7280,5660,7440
  5660,7440,5740,7520
  5740,7520,5740,7600
  5740,7600,5900,7600
  5900,7600,6040,7540
  6040,7540,6040,7320
  6040,7320,6120,7200
  6120,7200,6120,7040
  6120,7040,6240,7000
  6240,7000,6480,7060
  6480,7060,6800,7060
  6800,7060,7080,7080
  7080,7080,7320,7100
  7940,7100,7980,6920
  7860,6860,7980,6920
  7640,6860,7860,6860
  7400,6840,7640,6860
  7320,7100,7560,7120
  7560,7120,7760,7120
  7760,7120,7940,7100
  7200,6820,7400,6840
  7040,6820,7200,6820
  6600,6840,6840,6840
  6380,6800,6600,6840
  6120,6800,6380,6800
  5900,6840,6120,6800
  5620,6820,5900,6840
  5400,6800,5620,6820
  5140,6800,5400,6800
  4880,6780,5140,6800
  4600,6760,4880,6780
  4340,6760,4600,6760
  4080,6760,4340,6760
  3840,6740,4080,6760
  3680,6720,3840,6740
  3680,6720,3680,6560
  3680,6560,3720,6400
  3720,6400,3720,6200
  3720,6200,3780,6000
  3720,5780,3780,6000
  3720,5580,3720,5780
  3720,5360,3720,5580
  3720,5360,3840,5240
  3840,5240,4200,5260
  4200,5260,4600,5280
  4600,5280,4880,5280
  4880,5280,5140,5200
  5140,5200,5220,5100
  5220,5100,5280,4900
  5280,4900,5340,4840
  5340,4840,5720,4880
  6120,4880,6480,4860
  6880,4840,7200,4860
  6480,4860,6880,4840
  7200,4860,7320,4860
  7320,4860,7360,4740
  7360,4600,7440,4520
  7360,4600,7360,4740
  7440,4520,7640,4520
  7640,4520,7800,4480
  7800,4480,7800,4280
  7800,4280,7800,4040
  7800,4040,7800,3780
  7800,3560,7800,3780
  7800,3560,7860,3440
  7860,3440,8060,3460
  8060,3460,8160,3340
  8160,3340,8160,3140
  8160,3140,8160,2960
  8000,2900,8160,2960
  7860,2900,8000,2900
  7640,2940,7860,2900
  7400,2980,7640,2940
  7100,2980,7400,2980
  6840,3000,7100,2980
  5620,2980,5840,2980
  5840,2980,6500,3000
  6500,3000,6840,3000
  5560,2780,5620,2980
  5560,2780,5560,2580
  5560,2580,5560,2380
  5560,2140,5560,2380
  5560,2140,5560,1900
  5560,1900,5620,1660
  5620,1660,5660,1460
  5660,1460,5660,1300
  5500,1260,5660,1300
  5340,1260,5500,1260
  4600,1220,4840,1240
  4440,1220,4600,1220
  4440,1080,4440,1220
  4440,1080,4600,1020
  5080,1260,5340,1260
  4840,1240,5080,1260
  4600,1020,4940,1020
  4940,1020,5220,1020
  5220,1020,5560,960
  5560,960,5660,860
  5660,740,5660,860
  5280,740,5660,740
  4940,780,5280,740
  4660,760,4940,780
  4500,700,4660,760
  4500,520,4500,700
  4500,520,4700,460
  4700,460,5080,440
  5440,420,5740,420
  5080,440,5440,420
  5740,420,5840,360
  5800,280,5840,360
  5560,280,5800,280
  4980,300,5280,320
  4360,320,4660,300
  4200,360,4360,320
  5280,320,5560,280
  4660,300,4980,300
  4140,480,4200,360
  4140,480,4140,640
  4140,640,4200,780
  4200,780,4200,980
  4200,980,4220,1180
  4220,1400,4220,1180
  4220,1400,4260,1540
  4260,1540,4500,1540
  4500,1540,4700,1520
  4700,1520,4980,1540
  5280,1560,5400,1560
  4980,1540,5280,1560
  5400,1560,5400,1700
  5400,1780,5400,1700
  5340,1900,5400,1780
  5340,2020,5340,1900
  5340,2220,5340,2020
  5340,2220,5340,2420
  5340,2420,5340,2520
  5080,2600,5220,2580
  5220,2580,5340,2520
  4900,2580,5080,2600
  4700,2540,4900,2580
  4500,2540,4700,2540
  4220,2580,4340,2540
  4200,2700,4220,2580
  4340,2540,4500,2540
  3980,2740,4200,2700
  3840,2740,3980,2740
  3780,2640,3840,2740
  3780,2640,3780,2460
  3780,2280,3780,2460
  3620,2020,3780,2100
  3780,2280,3780,2100
  3360,2040,3620,2020
  3080,2040,3360,2040
  2840,2020,3080,2040
  2740,1940,2840,2020
  2740,1940,2800,1800
  2800,1640,2800,1800
  2800,1640,2800,1460
  2800,1300,2800,1460
  2700,1180,2800,1300
  2480,1140,2700,1180
  1580,1200,1720,1200
  2240,1180,2480,1140
  1960,1180,2240,1180
  1720,1200,1960,1180
  1500,1320,1580,1200
  1500,1440,1500,1320
  1500,1440,1760,1480
  1760,1480,1940,1480
  1940,1480,2140,1500
  2140,1500,2320,1520
  2400,1560,2400,1700
  2280,1820,2380,1780
  2320,1520,2400,1560
  2380,1780,2400,1700
  2080,1840,2280,1820
  1720,1820,2080,1840
  1420,1800,1720,1820
  1280,1800,1420,1800
  1240,1720,1280,1800
  1240,1720,1240,1600
  1240,1600,1280,1480
  1280,1340,1280,1480
  1180,1280,1280,1340
  1000,1280,1180,1280
  760,1280,1000,1280
  360,1240,540,1260
  180,1220,360,1240
  540,1260,760,1280
  180,1080,180,1220
  180,1080,180,1000
  180,1000,360,940
  360,940,540,960
  540,960,820,980
  1100,980,1200,920
  820,980,1100,980
  6640,11860,6940,11920
  5200,11280,5500,11280
  4120,7330,4120,7230
  4120,7230,4660,7250
  4660,7250,4940,7250
  4940,7250,5050,7340
  5010,7400,5050,7340
  4680,7380,5010,7400
  4380,7370,4680,7380
  4120,7330,4360,7370
  4120,7670,4120,7760
  4120,7670,4280,7650
  4280,7650,4540,7660
  4550,7660,4820,7680
  4820,7680,4900,7730
  4880,7800,4900,7730
  4620,7820,4880,7800
  4360,7790,4620,7820
  4120,7760,4360,7790
  6840,6840,7040,6820
  5720,4880,6120,4880
  1200,920,1340,810
  1340,810,1520,790
  1520,790,1770,800
  2400,790,2600,750
  2600,750,2640,520
  2520,470,2640,520
  2140,470,2520,470
  1760,800,2090,800
  2080,800,2400,790
  1760,450,2140,470
  1420,450,1760,450
  1180,440,1420,450
  900,480,1180,440
  640,450,900,480
  360,440,620,450
  120,430,360,440
  0,520,120,430
  -20,780,0,520
  -20,780,-20,1020
  -20,1020,-20,1150
  -20,1150,0,1300
  0,1470,60,1530
  0,1300,0,1470
  60,1530,360,1530
  360,1530,660,1520
  660,1520,980,1520
  980,1520,1040,1520
  1040,1520,1070,1560
  1070,1770,1070,1560
  1070,1770,1100,2010
  1070,2230,1100,2010
  1070,2240,1180,2340
  1180,2340,1580,2340
  1580,2340,1940,2350
  1940,2350,2440,2350
  2440,2350,2560,2380
  2560,2380,2600,2540
  2810,2640,3140,2680
  2600,2540,2810,2640
  3140,2680,3230,2780
  3230,2780,3260,2970
  3230,3220,3260,2970
  3200,3470,3230,3220
  3200,3480,3210,3760
  3210,3760,3210,4040
  3200,4040,3230,4310
  3210,4530,3230,4310
  3210,4530,3230,4730
  3230,4960,3230,4730
  3230,4960,3260,5190
  3170,5330,3260,5190
  2920,5330,3170,5330
  2660,5360,2920,5330
  2420,5330,2660,5360
  2200,5280,2400,5330
  2020,5280,2200,5280
  1840,5260,2020,5280
  1660,5280,1840,5260
  1500,5300,1660,5280
  1360,5270,1500,5300
  1200,5290,1340,5270
  1070,5400,1200,5290
  1040,5630,1070,5400
  1000,5900,1040,5630
  980,6170,1000,5900
  980,6280,980,6170
  980,6540,980,6280
  980,6540,1040,6720
  1040,6720,1360,6730
  1360,6730,1760,6710
  2110,6720,2420,6730
  1760,6710,2110,6720
  2420,6730,2640,6720
  2640,6720,2970,6720
  2970,6720,3160,6700
  3160,6700,3240,6710
  3240,6710,3260,6890
  3260,7020,3260,6890
  3230,7180,3260,7020
  3230,7350,3230,7180
  3210,7510,3230,7350
  3210,7510,3210,7690
  3210,7870,3210,7690
  3210,7870,3210,7980
  3200,8120,3210,7980
  3200,8330,3200,8120
  3160,8520,3200,8330
  2460,11100,2480,11020
  2200,11180,2460,11100
  1260,11350,1600,11320
  600,11430,930,11400
  180,11340,620,11430
  1600,11320,1910,11280
  1910,11280,2200,11180
  923.0029599285435,11398.99893503157,1264.002959928544,11351.99893503157
```

### The Little Probe - Data - level_lava.txt
```ruby
  # ./samples/99_genre_platformer/the_little_probe/data/level_lava.txt
  100,10740,500,10780
  500,10780,960,10760
  960,10760,1340,10760
  1380,10760,1820,10780
  1820,10780,2240,10780
  2280,10780,2740,10740
  2740,10740,3000,10780
  3000,10780,3140,11020
  -520,8820,-480,9160
  -520,8480,-520,8820
  -520,8480,-480,8180
  -480,8180,-200,8120
  -200,8120,100,8220
  100,8220,420,8240
  420,8240,760,8260
  760,8260,1140,8280
  1140,8280,1500,8200
  1500,8200,1880,8240
  1880,8240,2240,8260
  2240,8260,2320,8480
  2320,8480,2380,8680
  2240,8860,2380,8680
  2240,9080,2240,8860
  2240,9080,2320,9260
  2320,9260,2480,9440
  2480,9440,2600,9640
  2480,9840,2600,9640
  2400,10020,2480,9840
  2240,10080,2400,10020
  1960,10080,2240,10080
  1720,10080,1960,10080
  1460,10080,1720,10080
  1180,10080,1420,10080
  900,10080,1180,10080
  640,10080,900,10080
  640,10080,640,9900
  60,10520,100,10740
  40,10240,60,10520
  40,10240,40,9960
  40,9960,40,9680
  40,9680,40,9360
  40,9360,60,9080
  60,9080,100,8860
  100,8860,460,9040
  460,9040,760,9220
  760,9220,1140,9220
  1140,9220,1720,9200
  -660,11580,-600,11420
  -660,11800,-660,11580
  -660,12000,-660,11800
  -660,12000,-600,12220
  -600,12220,-600,12440
  -600,12440,-600,12640
  -600,11240,-260,11280
  -260,11280,100,11240
  9000,12360,9020,12400
  9020,12620,9020,12400
  9020,12840,9020,12620
  9020,13060,9020,12840
  9020,13060,9020,13240
  9020,13240,9020,13420
  9020,13420,9020,13600
  9020,13600,9020,13780
  8880,13900,9020,13780
  8560,13800,8880,13900
  8220,13780,8560,13800
  7860,13760,8220,13780
  7640,13780,7860,13760
  7360,13800,7640,13780
  7100,13800,7360,13800
  6540,13760,6800,13780
  6800,13780,7100,13800
  6280,13760,6540,13760
  5760,13760,6280,13760
  5220,13780,5760,13760
  4700,13760,5220,13780
  4200,13740,4700,13760
  3680,13720,4200,13740
  3140,13700,3680,13720
  2600,13680,3140,13700
  2040,13940,2600,13680
  1640,13940,2040,13940
  1200,13960,1640,13940
  840,14000,1200,13960
  300,13960,840,14000
  -200,13900,300,13960
  -600,12840,-600,12640
  -600,13140,-600,12840
  -600,13140,-600,13420
  -600,13700,-600,13420
  -600,13700,-600,13820
  -600,13820,-200,13900
  -600,11240,-560,11000
  -560,11000,-480,10840
  -520,10660,-480,10840
  -520,10660,-520,10480
  -520,10480,-520,10300
  -520,10260,-480,10080
  -480,9880,-440,10060
  -520,9680,-480,9880
  -520,9680,-480,9400
  -480,9400,-480,9160
  1820,9880,2140,9800
  1540,9880,1820,9880
  1200,9920,1500,9880
  900,9880,1200,9920
  640,9900,840,9880
  2380,8760,2800,8760
  2800,8760,2840,8660
  2840,8660,2840,8420
  2840,8160,2840,8420
  2800,7900,2840,8160
  2800,7900,2800,7720
  2800,7540,2800,7720
  2800,7540,2800,7360
  2700,7220,2800,7360
  2400,7220,2700,7220
  2080,7240,2400,7220
  1760,7320,2080,7240
  1380,7360,1720,7320
  1040,7400,1340,7360
  640,7400,1000,7420
  300,7380,640,7400
  0,7300,240,7380
  -300,7180,-60,7300
  -380,6860,-360,7180
  -380,6880,-360,6700
  -360,6700,-260,6540
  -260,6540,0,6520
  0,6520,240,6640
  240,6640,460,6640
  460,6640,500,6480
  500,6260,500,6480
  460,6060,500,6260
  460,5860,460,6060
  460,5860,500,5640
  500,5640,540,5440
  540,5440,580,5220
  580,5220,580,5000
  580,4960,580,4740
  580,4740,960,4700
  960,4700,1140,4760
  1140,4760,1420,4740
  1420,4740,1720,4700
  1720,4700,2000,4740
  2000,4740,2380,4760
  2380,4760,2700,4800
  1720,4600,1760,4300
  1760,4300,2200,4340
  2200,4340,2560,4340
  2560,4340,2740,4340
  2160,12580,2440,12400
  1820,12840,2160,12580
  1500,13080,1820,12840
  1140,13340,1500,13080
  1140,13340,1580,13220
  2110,13080,2520,13000
  2520,13000,2900,12800
  1580,13220,2110,13080
  2900,12800,3200,12680
  3200,12680,3440,12640
  3440,12640,3720,12460
  3720,12460,4040,12320
  4040,12320,4360,12200
  4360,11940,4380,12180
  4360,11700,4360,11940
  4360,11700,4540,11500
  4540,11500,4880,11540
  6000,11660,6280,11640
  5440,11600,5720,11610
  5720,11610,6000,11660
  6280,11640,6760,11720
  6760,11720,7060,11780
  7060,11780,7360,11810
  7360,11810,7640,11840
  7640,11840,8000,11830
  8000,11830,8320,11850
  8320,11850,8390,11800
  8330,11760,8390,11800
  8160,11760,8330,11760
  7910,11750,8160,11760
  7660,11740,7900,11750
  7400,11730,7660,11740
  7160,11680,7400,11730
  7080,11570,7160,11680
  7080,11570,7100,11350
  7100,11350,7440,11280
  7440,11280,7940,11280
  7960,11280,8360,11280
  5840,11540,6650,11170
  4880,11540,5440,11600
  3410,11830,3420,11300
  3410,11260,3520,10920
  3520,10590,3520,10920
  3520,10590,3540,10260
  3520,9900,3540,10240
  3520,9900,3640,9590
  3640,9570,4120,9590
  4140,9590,4600,9680
  4620,9680,5030,9730
  5120,9750,5520,9800
  5620,9820,6080,9800
  6130,9810,6580,9820
  6640,9820,6800,9700
  6780,9400,6800,9700
  6780,9400,6840,9140
  6820,8860,6840,9120
  6780,8600,6820,8830
  6720,8350,6780,8570
  6480,8340,6720,8320
  6260,8400,6480,8340
  6050,8580,6240,8400
  5760,8630,6040,8590
  5520,8690,5740,8630
  5120,8690,5450,8700
  4570,8670,5080,8690
  4020,8610,4540,8670
  3540,8480,4020,8610
  3520,8230,3520,8480
  3520,7930,3520,8230
  3520,7930,3540,7630
  3480,7320,3540,7610
  3480,7280,3500,7010
  3500,6980,3680,6850
  3680,6850,4220,6840
  4230,6840,4760,6850
  4780,6850,5310,6860
  5310,6860,5720,6940
  5720,6940,5880,7250
  5880,7250,5900,7520
  100,11240,440,11300
  440,11300,760,11330
  1480,11280,1840,11230
  2200,11130,2360,11090
  1840,11230,2200,11130
```
