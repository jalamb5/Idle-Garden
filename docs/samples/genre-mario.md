### Jumping - main.rb
```ruby
  # ./samples/99_genre_mario/01_jumping/app/main.rb
  def tick args
    defaults args
    render args
    input args
    calc args
  end

  def defaults args
    args.state.player.x      ||= args.grid.w.half
    args.state.player.y      ||= 0
    args.state.player.size   ||= 100
    args.state.player.dy     ||= 0
    args.state.player.action ||= :jumping
    args.state.jump.power           = 20
    args.state.jump.increase_frames = 10
    args.state.jump.increase_power  = 1
    args.state.gravity              = -1
  end

  def render args
    args.outputs.sprites << {
      x: args.state.player.x -
         args.state.player.size.half,
      y: args.state.player.y,
      w: args.state.player.size,
      h: args.state.player.size,
      path: 'sprites/square/red.png'
    }
  end

  def input args
    if args.inputs.keyboard.key_down.space
      if args.state.player.action == :standing
        args.state.player.action = :jumping
        args.state.player.dy = args.state.jump.power

        # record when the action took place
        current_frame = Kernel.tick_count
        args.state.player.action_at = current_frame
      end
    end

    # if the space bar is being held
    if args.inputs.keyboard.key_held.space
      # is the player jumping
      is_jumping = args.state.player.action == :jumping

      # when was the jump performed
      time_of_jump = args.state.player.action_at

      # how much time has passed since the jump
      jump_elapsed_time = time_of_jump.elapsed_time

      # how much time is allowed for increasing power
      time_allowed = args.state.jump.increase_frames

      # if the player is jumping
      # and the elapsed time is less than
      # the allowed time
      if is_jumping && jump_elapsed_time < time_allowed
         # increase the dy by the increase power
         power_to_add = args.state.jump.increase_power
         args.state.player.dy += power_to_add
      end
    end
  end

  def calc args
    if args.state.player.action == :jumping
      args.state.player.y  += args.state.player.dy
      args.state.player.dy += args.state.gravity
    end

    if args.state.player.y < 0
      args.state.player.y      = 0
      args.state.player.action = :standing
    end
  end

```

### Jumping And Collisions - main.rb
```ruby
  # ./samples/99_genre_mario/02_jumping_and_collisions/app/main.rb
  class Game
    attr_gtk

    def tick
      defaults
      render
      input
      calc
    end

    def defaults
      return if Kernel.tick_count != 0

      player.x                     = 64
      player.y                     = 800
      player.size                  = 50
      player.dx                    = 0
      player.dy                    = 0
      player.action                = :falling

      player.max_speed             = 20
      player.jump_power            = 15
      player.jump_air_time         = 15
      player.jump_increase_power   = 1

      state.gravity                = -1
      state.drag                   = 0.001
      state.tile_size              = 64
      state.tiles                ||= [
        { ordinal_x:  0, ordinal_y: 0 },
        { ordinal_x:  1, ordinal_y: 0 },
        { ordinal_x:  2, ordinal_y: 0 },
        { ordinal_x:  3, ordinal_y: 0 },
        { ordinal_x:  4, ordinal_y: 0 },
        { ordinal_x:  5, ordinal_y: 0 },
        { ordinal_x:  6, ordinal_y: 0 },
        { ordinal_x:  7, ordinal_y: 0 },
        { ordinal_x:  8, ordinal_y: 0 },
        { ordinal_x:  9, ordinal_y: 0 },
        { ordinal_x: 10, ordinal_y: 0 },
        { ordinal_x: 11, ordinal_y: 0 },
        { ordinal_x: 12, ordinal_y: 0 },

        { ordinal_x:  9, ordinal_y: 3 },
        { ordinal_x: 10, ordinal_y: 3 },
        { ordinal_x: 11, ordinal_y: 3 },
      ]

      tiles.each do |t|
        t.rect = { x: t.ordinal_x * 64,
                   y: t.ordinal_y * 64,
                   w: 64,
                   h: 64 }
      end
    end

    def render
      render_player
      render_tiles
      # render_grid
    end

    def input
      input_jump
      input_move
    end

    def calc
      calc_player_rect
      calc_left
      calc_right
      calc_below
      calc_above
      calc_player_dy
      calc_player_dx
      calc_game_over
    end

    def render_player
      outputs.sprites << {
        x: player.x,
        y: player.y,
        w: player.size,
        h: player.size,
        path: 'sprites/square/red.png'
      }
    end

    def render_tiles
      outputs.sprites << state.tiles.map do |t|
        t.merge path: 'sprites/square/white.png',
                x: t.ordinal_x * 64,
                y: t.ordinal_y * 64,
                w: 64,
                h: 64
      end
    end

    def render_grid
      if Kernel.tick_count == 0
        outputs[:grid].transient!
        outputs[:grid].background_color = [0, 0, 0, 0]
        outputs[:grid].borders << available_brick_locations
        outputs[:grid].labels  << available_brick_locations.map do |b|
          [
            b.merge(text: "#{b.ordinal_x},#{b.ordinal_y}",
                    x: b.x + 2,
                    y: b.y + 2,
                    size_enum: -3,
                    vertical_alignment_enum: 0,
                    blendmode_enum: 0),
            b.merge(text: "#{b.x},#{b.y}",
                    x: b.x + 2,
                    y: b.y + 2 + 20,
                    size_enum: -3,
                    vertical_alignment_enum: 0,
                    blendmode_enum: 0)
          ]
        end
      end

      outputs.sprites << { x: 0, y: 0, w: 1280, h: 720, path: :grid }
    end

    def input_jump
      if inputs.keyboard.key_down.space
        player_jump
      end

      if inputs.keyboard.key_held.space
        player_jump_increase_air_time
      end
    end

    def input_move
      if player.dx.abs < 20
        if inputs.keyboard.left
          player.dx -= 2
        elsif inputs.keyboard.right
          player.dx += 2
        end
      end
    end

    def calc_game_over
      if player.y < -64
        player.x = 64
        player.y = 800
        player.dx = 0
        player.dy = 0
      end
    end

    def calc_player_rect
      player.rect      = player_current_rect
      player.next_rect = player_next_rect
      player.prev_rect = player_prev_rect
    end

    def calc_player_dx
      player.dx  = player_next_dx
      player.x  += player.dx
    end

    def calc_player_dy
      player.y  += player.dy
      player.dy  = player_next_dy
    end

    def calc_below
      return unless player.dy < 0
      tiles_below = tiles_find { |t| t.rect.top <= player.prev_rect.y }
      collision = tiles_find_colliding tiles_below, (player.rect.merge y: player.next_rect.y)
      if collision
        player.y  = collision.rect.y + state.tile_size
        player.dy = 0
        player.action = :standing
      else
        player.action = :falling
      end
    end

    def calc_left
      return unless player.dx < 0 && player_next_dx < 0
      tiles_left = tiles_find { |t| t.rect.right <= player.prev_rect.left }
      collision = tiles_find_colliding tiles_left, (player.rect.merge x: player.next_rect.x)
      return unless collision
      player.x  = collision.rect.right
      player.dx = 0
    end

    def calc_right
      return unless player.dx > 0 && player_next_dx > 0
      tiles_right = tiles_find { |t| t.rect.left >= player.prev_rect.right }
      collision = tiles_find_colliding tiles_right, (player.rect.merge x: player.next_rect.x)
      return unless collision
      player.x  = collision.rect.left - player.rect.w
      player.dx = 0
    end

    def calc_above
      return unless player.dy > 0
      tiles_above = tiles_find { |t| t.rect.y >= player.prev_rect.y }
      collision = tiles_find_colliding tiles_above, (player.rect.merge y: player.next_rect.y)
      return unless collision
      player.dy = 0
      player.y  = collision.rect.bottom - player.rect.h
    end

    def player_current_rect
      { x: player.x, y: player.y, w: player.size, h: player.size }
    end

    def available_brick_locations
      (0..19).to_a
        .product(0..11)
        .map do |(ordinal_x, ordinal_y)|
        { ordinal_x: ordinal_x,
          ordinal_y: ordinal_y,
          x: ordinal_x * 64,
          y: ordinal_y * 64,
          w: 64,
          h: 64 }
      end
    end

    def player
      state.player ||= args.state.new_entity :player
    end

    def player_next_dy
      player.dy + state.gravity + state.drag ** 2 * -1
    end

    def player_next_dx
      player.dx * 0.8
    end

    def player_next_rect
      player.rect.merge x: player.x + player_next_dx,
                        y: player.y + player_next_dy
    end

    def player_prev_rect
      player.rect.merge x: player.x - player.dx,
                        y: player.y - player.dy
    end

    def player_jump
      return if player.action != :standing
      player.action = :jumping
      player.dy = state.player.jump_power
      current_frame = Kernel.tick_count
      player.action_at = current_frame
    end

    def player_jump_increase_air_time
      return if player.action != :jumping
      return if player.action_at.elapsed_time >= player.jump_air_time
      player.dy += player.jump_increase_power
    end

    def tiles
      state.tiles
    end

    def tiles_find_colliding tiles, target
      tiles.find { |t| t.rect.intersect_rect? target }
    end

    def tiles_find &block
      tiles.find_all(&block)
    end
  end

  def tick args
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

  $gtk.reset

```
