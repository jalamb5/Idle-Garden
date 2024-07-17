### Bullet Heaven - main.rb
```ruby
  # ./samples/99_genre_arcade/bullet_heaven/app/main.rb
  class Game
    attr_gtk

    def initialize
      @level_scene = LevelScene.new
      @shop_scene = ShopScene.new
    end

    def tick
      defaults
      current_scene.args = args
      current_scene.tick
      if state.next_scene
        state.scene = state.next_scene
        state.scene_at = Kernel.tick_count
        state.next_scene = nil
      end
    end

    def current_scene
      if state.scene == :level
        @level_scene
      elsif state.scene == :shop
        @shop_scene
      end
    end

    def defaults
      state.shield ||= 10
      state.assembly_points ||= 4
      state.scene ||= :level
      state.bullets ||= []
      state.enemies ||= []
      state.bullet_speed ||= 5
      state.turret_position ||= { x: 640, y: 0 }
      state.blaster_spread ||= 1
      state.blaster_rate ||= 60
      state.level ||= 1
      state.bullet_damage ||= 1
      state.enemy_spawn_rate ||= 120
      state.enemy_min_health ||= 1
      state.enemy_health_range ||= 2
      state.enemies_to_spawn ||= 5
      state.enemies_spawned ||= 0
      state.enemy_dy ||= -0.2
    end
  end

  class ShopScene
    attr_gtk

    def activate
      state.module_selected = nil
      state.available_module_1 = :blaster_spread
      state.available_module_2 = :bullet_damage
      state.available_module_3 = if state.blaster_rate > 3
                                   :blaster_rate
                                 else
                                   nil
                                 end
    end

    def tick
      if state.scene_at == Kernel.tick_count - 1
        activate
      end

      state.next_wave_button ||= layout.rect(row: 0, col: 20, w: 4, h: 2)
      state.module_1_button  ||= layout.rect(row: 10, col: 0, w: 8, h: 2)
      state.module_2_button  ||= layout.rect(row: 10, col: 8, w: 8, h: 2)
      state.module_3_button  ||= layout.rect(row: 10, col: 16, w: 8, h: 2)

      calc
      render
    end

    def increase_difficulty_and_start_level
      state.next_scene = :level
      state.enemies_spawned = 0
      state.enemies = []
      state.level += 1
      state.enemy_spawn_rate = (state.enemy_spawn_rate * 0.95).to_i
      state.enemy_min_health = (state.enemy_min_health * 1.1).to_i + 1
      state.enemy_health_range = state.enemy_min_health * 2
      state.enemies_to_spawn = (state.enemies_to_spawn * 1.1).to_i + 2
      state.enemy_dy *= 1.05
    end

    def calc
      if state.module_selected
        if inputs.mouse.click && inputs.mouse.click.point.inside_rect?(state.next_wave_button)
          increase_difficulty_and_start_level
        end
      else
        if inputs.mouse.click && inputs.mouse.click.point.inside_rect?(state.module_1_button)
          perform_upgrade state.available_module_1
          state.available_module_1 = nil
          state.module_selected = true
        elsif inputs.mouse.click && inputs.mouse.click.point.inside_rect?(state.module_2_button)
          perform_upgrade state.available_module_2
          state.available_module_2 = nil
          state.module_selected = true
        elsif inputs.mouse.click && inputs.mouse.click.point.inside_rect?(state.module_3_button)
          perform_upgrade state.available_module_3
          state.available_module_3 = nil
          state.module_selected = true
        end
      end
    end

    def perform_upgrade module_name
      return if state.module_selected
      if module_name == :bullet_damage
        state.bullet_damage += 1
      elsif module_name == :blaster_rate
        state.blaster_rate = (state.blaster_rate * 0.85).to_i
        state.blaster_rate = 3 if state.blaster_rate < 3
      elsif module_name == :blaster_spread
        state.blaster_spread += 2
      else
        raise "perform_upgade: Unknown module: #{module_name}"
      end
    end

    def render
      outputs.background_color = [0, 0, 0]
      # outputs.primitives << layout.debug_primitives.map { |p| p.merge a: 80 }

      outputs.labels << layout.rect(row: 0, col: 11, w: 2, h: 1)
                              .center
                              .merge(text: "Select Upgrade", anchor_x: 0.5, anchor_y: 0.5, size_px: 50, r: 255, g: 255, b: 255)

      if state.module_selected
        outputs.primitives << button_prefab(state.next_wave_button, "Next Wave", a: 255)
      end

      a = if state.module_selected
            80
          else
            255
          end

      outputs.primitives << button_prefab(state.module_1_button, state.available_module_1, a: a)
      outputs.primitives << button_prefab(state.module_2_button, state.available_module_2, a: a)
      outputs.primitives << button_prefab(state.module_3_button, state.available_module_3, a: a)
    end

    def button_prefab rect, text, a: 255
      return nil if !text
      [
        rect.merge(path: :solid, r: 255, g: 255, b: 255, a: a),
        geometry.center(rect).merge(text: text.gsub("_", " "), anchor_x: 0.5, anchor_y: 0.5, r: 0, g: 0, b: 0, size_px: rect.h.idiv(4))
      ]
    end
  end

  class LevelScene
    attr_gtk

    def tick
      if inputs.keyboard.key_down.g
        state.enemies_spawned = state.enemies_to_spawn
        state.enemies = []
      elsif inputs.keyboard.key_down.forward_slash
        roll = rand
        if roll < 0.33
          state.bullet_damage += 1
          $gtk.notify_extended! message: "bullet damage increased: #{state.bullet_damage}", env: :prod
        elsif roll < 0.66
          if state.blaster_rate > 3
            state.blaster_rate = (state.blaster_rate * 0.85).to_i
            state.blaster_rate = 3 if state.blaster_rate < 3
            $gtk.notify_extended! message: "blaster rate upgraded: #{state.blaster_rate}", env: :prod
          else
            $gtk.notify_extended! message: "blaster rate already at fastest.", env: :prod
          end
        else
          state.blaster_spread += 2
          $gtk.notify_extended! message: "blaster spread increased: #{state.blaster_spread}", env: :prod
        end
      end

      calc
      render
    end

    def calc
      calc_bullets
      calc_enemies
      calc_bullet_hits
      calc_enemy_push_back
      calc_deaths
    end

    def calc_deaths
      state.enemies.reject! { |e| e.hp <= 0 }
      state.bullets.reject! { |b| b.dead_at }
    end

    def enemy_prefab enemy
      b = (enemy.hp / (state.enemy_min_health + state.enemy_health_range)) * 255
      [
        enemy.merge(path: :solid, r: 128, g: 0, b: b),
        geometry.center(enemy).merge(text: enemy.hp, anchor_x: 0.5, anchor_y: 0.5, r: 255, g: 255, b: 255, size_px: enemy.h * 0.5)
      ]
    end

    def render
      outputs.background_color = [0, 0, 0]
      level_completion_perc = (state.enemies_spawned - state.enemies.length).fdiv(state.enemies_to_spawn)
      outputs.primitives << { x: 30, y: 30.from_top, text: "Wave: #{state.level} (#{(level_completion_perc * 100).to_i}% complete)", r: 255, g: 255, b: 255 }
      outputs.primitives << { x: 30, y: 60.from_top, text: "Press G to skip to end of the current wave.", r: 255, g: 255, b: 255 }
      outputs.primitives << { x: 30, y: 90.from_top, text: "Press / to get a random upgrade immediately.", r: 255, g: 255, b: 255 }

      outputs.sprites << state.bullets.map do |b|
        b.merge w: 10, h: 10, path: :solid, r: 0, g: 255, b: 255
      end

      outputs.primitives << state.enemies.map { |e| enemy_prefab e }
    end

    def calc_bullets
      if Kernel.tick_count.zmod? state.blaster_rate
        bullet_count = state.blaster_spread
        min_degrees = state.blaster_spread.idiv(2) * -2
        bullet_count.times do |i|
          degree_offset = min_degrees + (i * 2)
          state.bullets << { x: 640,
                             y: 0,
                             dy: (attack_angle + degree_offset).vector_y * state.bullet_speed,
                             dx: (attack_angle + degree_offset).vector_x * state.bullet_speed }
        end
      end

      state.bullets.each do |b|
        b.x += b.dx
        b.y += b.dy
      end

      state.bullets.reject! { |b| b.y < 0 || b.y > 720 || b.x > 1280 || b.x < 0 }
    end

    def calc_enemies
      if Kernel.tick_count.zmod?(state.enemy_spawn_rate) && state.enemies_spawned < state.enemies_to_spawn
        state.enemies_spawned += 1
        x = rand(1280 - 96) + 48
        y = 720
        hp = state.enemy_min_health + rand(state.enemy_health_range)
        state.enemies << { x: x,
                           y: y,
                           w: 48,
                           h: 48,
                           push_back_x: 0,
                           push_back_y: 0,
                           spawn_at: Kernel.tick_count,
                           dy: state.enemy_dy,
                           start_hp: hp,
                           hp: hp }
      end

      state.enemies.each do |e|
        if e.y + e.h > 720
          e.y -= (((e.y + e.h) - 720) / e.h) * 10
        end

        e.y += e.dy

        if e.x < 0 && e.push_back_x < 0
          e.push_back_x = e.push_back_x.abs
        elsif (e.x + e.w) > 1280 && e.push_back_x > 0
          e.push_back_x = e.push_back_x.abs * -1
        end

        e.x += e.push_back_x
        e.y += e.push_back_y

        e.push_back_x *= 0.9
        e.push_back_y *= 0.9
      end

      state.enemies.reject! { |e| e.y < 0 }

      if state.enemies.empty? && state.enemies_spawned >= state.enemies_to_spawn
        state.next_scene = :shop
        state.bullets.clear
      end
    end

    def calc_bullet_hits
      state.bullets.each do |b|
        state.enemies.each do |e|
          if geometry.intersect_rect? b.merge(w: 4, h: 4, anchor_x: 0.5, anchor_x: 0.5), e
            e.hp -= state.bullet_damage
            push_back_angle = geometry.angle b, geometry.center(e)
            push_back_x = push_back_angle.vector_x * state.bullet_damage * 0.1
            push_back_y = push_back_angle.vector_y * state.bullet_damage * 0.1
            e.push_back_x += push_back_x
            e.push_back_y += push_back_y
            e.hit_at = Kernel.tick_count
            b.dead_at = Kernel.tick_count
          end
        end
      end
    end

    def calc_enemy_push_back
      state.enemies.sort_by { |e| -e.y }.each do |e|
        has_pushed_back = false
        other_enemies = geometry.find_all_intersect_rect e, state.enemies
        other_enemies.each do |e2|
          next if e == e2
          push_back_angle = geometry.angle geometry.center(e), geometry.center(e2)
          e2.push_back_x += (e.push_back_x).fdiv(other_enemies.length) * 0.7
          e2.push_back_y += (e.push_back_y).fdiv(other_enemies.length) * 0.7
          has_pushed_back = true
        end

        if has_pushed_back
          e.push_back_x *= 0.2
          e.push_back_y *= 0.2
        end
      end
    end

    def attack_angle
      geometry.angle state.turret_position, inputs.mouse
    end
  end

  def tick args
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

  def reset
    $game = nil
  end

  $gtk.reset

```

### Bullet Hell - main.rb
```ruby
  # ./samples/99_genre_arcade/bullet_hell/app/main.rb
  def tick args
    args.state.base_columns   ||= 10.times.map { |n| 50 * n + 1280 / 2 - 5 * 50 + 5 }
    args.state.base_rows      ||= 5.times.map { |n| 50 * n + 720 - 5 * 50 }
    args.state.offset_columns = 10.times.map { |n| (n - 4.5) * Math.sin(Kernel.tick_count.to_radians) * 12 }
    args.state.offset_rows    = 5.map { 0 }
    args.state.columns        = 10.times.map { |i| args.state.base_columns[i] + args.state.offset_columns[i] }
    args.state.rows           = 5.times.map { |i| args.state.base_rows[i] + args.state.offset_rows[i] }
    args.state.explosions     ||= []
    args.state.enemies        ||= []
    args.state.score          ||= 0
    args.state.wave           ||= 0
    if args.state.enemies.empty?
      args.state.wave      += 1
      args.state.wave_root = Math.sqrt(args.state.wave)
      args.state.enemies   = make_enemies
    end
    args.state.player         ||= {x: 620, y: 80, w: 40, h: 40, path: 'sprites/circle-gray.png', angle: 90, cooldown: 0, alive: true}
    args.state.enemy_bullets  ||= []
    args.state.player_bullets ||= []
    args.state.lives          ||= 3
    args.state.missed_shots   ||= 0
    args.state.fired_shots    ||= 0

    update_explosions args
    update_enemy_positions args

    if args.inputs.left && args.state.player[:x] > (300 + 5)
      args.state.player[:x] -= 5
    end
    if args.inputs.right && args.state.player[:x] < (1280 - args.state.player[:w] - 300 - 5)
      args.state.player[:x] += 5
    end

    args.state.enemy_bullets.each do |bullet|
      bullet[:x] += bullet[:dx]
      bullet[:y] += bullet[:dy]
    end
    args.state.player_bullets.each do |bullet|
      bullet[:x] += bullet[:dx]
      bullet[:y] += bullet[:dy]
    end

    args.state.enemy_bullets  = args.state.enemy_bullets.find_all { |bullet| bullet[:y].between?(-16, 736) }
    args.state.player_bullets = args.state.player_bullets.find_all do |bullet|
      if bullet[:y].between?(-16, 736)
        true
      else
        args.state.missed_shots += 1
        false
      end
    end

    args.state.enemies = args.state.enemies.reject do |enemy|
      if args.state.player[:alive] && 1500 > (args.state.player[:x] - enemy[:x]) ** 2 + (args.state.player[:y] - enemy[:y]) ** 2
        args.state.explosions << {x: enemy[:x] + 4, y: enemy[:y] + 4, w: 32, h: 32, path: 'sprites/explosion-0.png', age: 0}
        args.state.explosions << {x: args.state.player[:x] + 4, y: args.state.player[:y] + 4, w: 32, h: 32, path: 'sprites/explosion-0.png', age: 0}
        args.state.player[:alive] = false
        true
      else
        false
      end
    end
    args.state.enemy_bullets.each do |bullet|
      if args.state.player[:alive] && 400 > (args.state.player[:x] - bullet[:x] + 12) ** 2 + (args.state.player[:y] - bullet[:y] + 12) ** 2
        args.state.explosions << {x: args.state.player[:x] + 4, y: args.state.player[:y] + 4, w: 32, h: 32, path: 'sprites/explosion-0.png', age: 0}
        args.state.player[:alive] = false
        bullet[:despawn]          = true
      end
    end
    args.state.enemies = args.state.enemies.reject do |enemy|
      args.state.player_bullets.any? do |bullet|
        if 400 > (enemy[:x] - bullet[:x] + 12) ** 2 + (enemy[:y] - bullet[:y] + 12) ** 2
          args.state.explosions << {x: enemy[:x] + 4, y: enemy[:y] + 4, w: 32, h: 32, path: 'sprites/explosion-0.png', age: 0}
          bullet[:despawn] = true
          args.state.score += 1000 * args.state.wave
          true
        else
          false
        end
      end
    end

    args.state.player_bullets = args.state.player_bullets.reject { |bullet| bullet[:despawn] }
    args.state.enemy_bullets  = args.state.enemy_bullets.reject { |bullet| bullet[:despawn] }

    args.state.player[:cooldown] -= 1
    if args.inputs.keyboard.key_held.space && args.state.player[:cooldown] <= 0 && args.state.player[:alive]
      args.state.player_bullets << {x: args.state.player[:x] + 12, y: args.state.player[:y] + 28, w: 16, h: 16, path: 'sprites/star.png', dx: 0, dy: 8}.sprite
      args.state.fired_shots       += 1
      args.state.player[:cooldown] = 10 + 20 / args.state.wave
    end
    args.state.enemies.each do |enemy|
      if Math.rand < 0.0005 + 0.0005 * args.state.wave && args.state.player[:alive] && enemy[:move_state] == :normal
        args.state.enemy_bullets << {x: enemy[:x] + 12, y: enemy[:y] - 8, w: 16, h: 16, path: 'sprites/star.png', dx: 0, dy: -3 - args.state.wave_root}.sprite
      end
    end

    args.outputs.background_color = [0, 0, 0]
    args.outputs.primitives << args.state.enemies.map do |enemy|
      [enemy[:x], enemy[:y], 40, 40, enemy[:path], -90].sprite
    end
    args.outputs.primitives << args.state.player if args.state.player[:alive]
    args.outputs.primitives << args.state.explosions
    args.outputs.primitives << args.state.player_bullets
    args.outputs.primitives << args.state.enemy_bullets
    accuracy = args.state.fired_shots.zero? ? 1 : (args.state.fired_shots - args.state.missed_shots) / args.state.fired_shots
    args.outputs.primitives << [
      [0, 0, 300, 720, 96, 0, 0].solid,
      [1280 - 300, 0, 300, 720, 96, 0, 0].solid,
      [1280 - 290, 60, "Wave     #{args.state.wave}", 255, 255, 255].label,
      [1280 - 290, 40, "Accuracy #{(accuracy * 100).floor}%", 255, 255, 255].label,
      [1280 - 290, 20, "Score    #{(args.state.score * accuracy).floor}", 255, 255, 255].label,
    ]
    args.outputs.primitives << args.state.lives.times.map do |n|
      [1280 - 290 + 50 * n, 80, 40, 40, 'sprites/circle-gray.png', 90].sprite
    end
    #args.outputs.debug << args.gtk.framerate_diagnostics_primitives

    if (!args.state.player[:alive]) && args.state.enemy_bullets.empty? && args.state.explosions.empty? && args.state.enemies.all? { |enemy| enemy[:move_state] == :normal }
      args.state.player[:alive] = true
      args.state.player[:x]     = 624
      args.state.player[:y]     = 80
      args.state.lives          -= 1
      if args.state.lives == -1
        args.state.clear!
      end
    end
  end

  def make_enemies
    enemies = []
    enemies += 10.times.map { |n| {x: Math.rand * 1280 * 2 - 640, y: Math.rand * 720 * 2 + 720, row: 0, col: n, path: 'sprites/circle-orange.png', move_state: :retreat} }
    enemies += 10.times.map { |n| {x: Math.rand * 1280 * 2 - 640, y: Math.rand * 720 * 2 + 720, row: 1, col: n, path: 'sprites/circle-orange.png', move_state: :retreat} }
    enemies += 8.times.map { |n| {x: Math.rand * 1280 * 2 - 640, y: Math.rand * 720 * 2 + 720, row: 2, col: n + 1, path: 'sprites/circle-blue.png', move_state: :retreat} }
    enemies += 8.times.map { |n| {x: Math.rand * 1280 * 2 - 640, y: Math.rand * 720 * 2 + 720, row: 3, col: n + 1, path: 'sprites/circle-blue.png', move_state: :retreat} }
    enemies += 4.times.map { |n| {x: Math.rand * 1280 * 2 - 640, y: Math.rand * 720 * 2 + 720, row: 4, col: n + 3, path: 'sprites/circle-green.png', move_state: :retreat} }
    enemies
  end

  def update_explosions args
    args.state.explosions.each do |explosion|
      explosion[:age]  += 0.5
      explosion[:path] = "sprites/explosion-#{explosion[:age].floor}.png"
    end
    args.state.explosions = args.state.explosions.reject { |explosion| explosion[:age] >= 7 }
  end

  def update_enemy_positions args
    args.state.enemies.each do |enemy|
      if enemy[:move_state] == :normal
        enemy[:x]          = args.state.columns[enemy[:col]]
        enemy[:y]          = args.state.rows[enemy[:row]]
        enemy[:move_state] = :dive if Math.rand < 0.0002 + 0.00005 * args.state.wave && args.state.player[:alive]
      elsif enemy[:move_state] == :dive
        enemy[:target_x] ||= args.state.player[:x]
        enemy[:target_y] ||= args.state.player[:y]
        dx               = enemy[:target_x] - enemy[:x]
        dy               = enemy[:target_y] - enemy[:y]
        vel              = Math.sqrt(dx * dx + dy * dy)
        speed_limit      = 2 + args.state.wave_root
        if vel > speed_limit
          dx /= vel / speed_limit
          dy /= vel / speed_limit
        end
        if vel < 1 || !args.state.player[:alive]
          enemy[:move_state] = :retreat
        end
        enemy[:x] += dx
        enemy[:y] += dy
      elsif enemy[:move_state] == :retreat
        enemy[:target_x] = args.state.columns[enemy[:col]]
        enemy[:target_y] = args.state.rows[enemy[:row]]
        dx               = enemy[:target_x] - enemy[:x]
        dy               = enemy[:target_y] - enemy[:y]
        vel              = Math.sqrt(dx * dx + dy * dy)
        speed_limit      = 2 + args.state.wave_root
        if vel > speed_limit
          dx /= vel / speed_limit
          dy /= vel / speed_limit
        elsif vel < 1
          enemy[:move_state] = :normal
          enemy[:target_x]   = nil
          enemy[:target_y]   = nil
        end
        enemy[:x] += dx
        enemy[:y] += dy
      end
    end
  end

```

### Dueling Starships - main.rb
```ruby
  # ./samples/99_genre_arcade/dueling_starships/app/main.rb
  class DuelingSpaceships
    attr_gtk

    def tick
      defaults
      render
      calc
      input
    end

    def defaults
      outputs.background_color = [0, 0, 0]
      state.ship_blue       ||= new_blue_ship
      state.ship_red        ||= new_red_ship
      state.flames          ||= []
      state.bullets         ||= []
      state.ship_blue_score ||= 0
      state.ship_red_score  ||= 0
      state.stars           ||= 100.map do
        (rand + 2).yield_self do |size|
          { x: grid.w_half.randomize(:sign, :ratio),
            y: grid.h_half.randomize(:sign, :ratio),
            w: size,
            h: size,
            r: 128 + 128 * rand,
            g: 255,
            b: 255,
            path: :solid }
        end
      end
    end

    def new_ship x:, y:, angle:, path:, bullet_path:, color:;
      { x: x, y: y, w: 66, h: 66,
        dy: 0, dx: 0,
        anchor_x: 0.5, anchor_y: 0.5,
        damage: 0,
        dead: false,
        angle: angle,
        a: 255,
        path: path,
        bullet_sprite_path: bullet_path,
        color: color,
        created_at: Kernel.tick_count,
        last_bullet_at: 0,
        fire_rate: 10 }
    end

    def new_red_ship
      new_ship x: 400,
               y: 250.randomize(:sign, :ratio),
               angle: 180, path: 'sprites/ship_red.png',
               bullet_path: 'sprites/red_bullet.png',
               color: { r: 255, g: 90, b: 90 }
    end

    def new_blue_ship
      new_ship x: -400,
               y: 250.randomize(:sign, :ratio),
               angle: 0,
               path: 'sprites/ship_blue.png',
               bullet_path: 'sprites/blue_bullet.png',
               color: { r: 110, g: 140, b: 255 }
    end

    def render
      render_instructions
      render_score
      render_universe
      render_flames
      render_ships
      render_bullets
    end

    def render_ships
      outputs.primitives << ship_prefab(state.ship_blue)
      outputs.primitives << ship_prefab(state.ship_red)
    end

    def render_instructions
      return if state.ship_blue.dx  > 0  || state.ship_blue.dy > 0  ||
                state.ship_red.dx   > 0  || state.ship_red.dy  > 0  ||
                state.flames.length > 0

      outputs.labels << { x: grid.left.shift_right(30),
                          y: grid.bottom.shift_up(30),
                          text: "Two gamepads needed to play. R1 to accelerate. Left and right on D-PAD to turn ship. Hold A to shoot. Press B to drop mines.",
                          r: 255, g: 255, b: 255 }
    end

    def calc
      calc_flames
      calc_ships
      calc_bullets
      calc_winner
    end

    def input
      input_accelerate
      input_turn
      input_bullets_and_mines
    end

    def render_score
      outputs.labels << { x: grid.left.shift_right(80),
                          y: grid.top.shift_down(40),
                          text: state.ship_blue_score,
                          size_enum: 30,
                          alignment_enum: 1, **state.ship_blue.color }

      outputs.labels << { x: grid.right.shift_left(80),
                          y: grid.top.shift_down(40),
                          text: state.ship_red_score,
                          size_enum: 30,
                          alignment_enum: 1, **state.ship_red.color }
    end

    def render_universe
      args.outputs.background_color = [0, 0, 0]
      outputs.sprites << state.stars
    end

    def apply_round_finished_alpha entity
      return entity unless state.round_finished_at
      entity.merge(a: (entity.a || 0) * state.round_finished_at.ease(2.seconds, :flip))
    end

    def ship_prefab ship
      [
        apply_round_finished_alpha(**ship,
                                   a: ship.dead ? 0 : 255 * ship.created_at.ease(2.seconds)),

        apply_round_finished_alpha(x: ship.x,
                                   y: ship.y + 100,
                                   text: "." * (5 - ship.damage.clamp(0, 5)),
                                   size_enum: 20,
                                   alignment_enum: 1,
                                   **ship.color)
      ]
    end

    def render_flames
      outputs.sprites << state.flames.map do |flame|
        apply_round_finished_alpha(flame.merge(a: 255 * flame.created_at.ease(flame.lifetime, :flip)))
      end
    end

    def render_bullets
      outputs.sprites << state.bullets.map do |b|
        apply_round_finished_alpha(b.merge(a: 255 * b.owner.created_at.ease(2.seconds)))
      end
    end

    def wrap_location! location
      location.merge! x: location.x.clamp_wrap(grid.left, grid.right),
                      y: location.y.clamp_wrap(grid.bottom, grid.top)
    end

    def calc_flames
      state.flames =
        state.flames
             .reject { |p| p.created_at.elapsed_time > p.lifetime }
             .map do |p|
               p.speed *= 0.9
               p.y += p.angle.vector_y(p.speed)
               p.x += p.angle.vector_x(p.speed)
               wrap_location! p
             end
    end

    def all_ships
      [state.ship_blue, state.ship_red]
    end

    def alive_ships
      all_ships.reject { |s| s.dead }
    end

    def calc_bullet bullet
      bullet.y += bullet.angle.vector_y(bullet.speed)
      bullet.x += bullet.angle.vector_x(bullet.speed)
      wrap_location! bullet
      explode_bullet! bullet, particle_count: 5 if bullet.created_at.elapsed_time > bullet.lifetime
      return if bullet.exploded
      return if state.round_finished
      alive_ships.each do |s|
        if s != bullet.owner && s.intersect_rect?(bullet)
          explode_bullet! bullet, particle_count: 10
          s.damage += 1
        end
      end
    end

    def calc_bullets
      state.bullets.each    { |b| calc_bullet b }
      state.bullets.reject! { |b| b.exploded }
    end

    def new_flame x:, y:, angle:, a:, lifetime:, speed:;
      { angle: angle,
        speed: speed,
        lifetime: lifetime,
        path: 'sprites/flame.png',
        x: x,
        y: y,
        w: 6,
        h: 6,
        anchor_x: 0.5,
        anchor_y: 0.5,
        created_at: Kernel.tick_count,
        a: a }
    end

    def create_explosion! source:, particle_count:, max_speed:, lifetime:;
      state.flames.concat(particle_count.map do
                            new_flame x: source.x,
                                      y: source.y,
                                      speed: max_speed * rand,
                                      angle: 360 * rand,
                                      lifetime: lifetime,
                                      a: source.a
                          end)
    end

    def explode_bullet! bullet, particle_count: 5
      bullet.exploded = true
      create_explosion! source: bullet,
                        particle_count: particle_count,
                        max_speed: 5,
                        lifetime: 10
    end

    def calc_ship ship
      ship.x += ship.dx
      ship.y += ship.dy
      wrap_location! ship
    end

    def calc_ships
      all_ships.each { |s| calc_ship s }
      return if all_ships.any? { |s| s.dead }
      return if state.round_finished
      return unless state.ship_blue.intersect_rect?(state.ship_red)
      state.ship_blue.damage = 5
      state.ship_red.damage  = 5
    end

    def create_thruster_flames! ship
      state.flames << new_flame(x: ship.x - ship.angle.vector_x(40) + 5.randomize(:sign, :ratio),
                                y: ship.y - ship.angle.vector_y(40) + 5.randomize(:sign, :ratio),
                                angle: ship.angle + 180 + 60.randomize(:sign, :ratio),
                                speed: 5.randomize(:ratio),
                                a: 255 * ship.created_at.elapsed_time.ease(2.seconds),
                                lifetime: 30)
    end

    def input_accelerate_ship should_move_ship, ship
      return if ship.dead

      should_move_ship &&= (ship.dx + ship.dy).abs < 5

      if should_move_ship
        create_thruster_flames! ship
        ship.dx += ship.angle.vector_x 0.050
        ship.dy += ship.angle.vector_y 0.050
      else
        ship.dx *= 0.99
        ship.dy *= 0.99
      end
    end

    def input_accelerate
      input_accelerate_ship inputs.controller_one.key_held.r1 || inputs.keyboard.up, state.ship_blue
      input_accelerate_ship inputs.controller_two.key_held.r1, state.ship_red
    end

    def input_turn_ship direction, ship
      ship.angle -= 3 * direction
    end

    def input_turn
      input_turn_ship inputs.controller_one.left_right + inputs.keyboard.left_right, state.ship_blue
      input_turn_ship inputs.controller_two.left_right, state.ship_red
    end

    def new_bullet x:, y:, ship:, angle:, speed:, lifetime:;
      { owner: ship,
        angle: angle,
        speed: speed,
        lifetime: lifetime,
        created_at: Kernel.tick_count,
        path: ship.bullet_sprite_path,
        anchor_x: 0.5,
        anchor_y: 0.5,
        w: 10,
        h: 10,
        x: x,
        y: y }
    end

    def input_bullet create_bullet, ship
      return unless create_bullet
      return if ship.dead
      return if ship.last_bullet_at.elapsed_time < ship.fire_rate

      ship.last_bullet_at = Kernel.tick_count

      state.bullets << new_bullet(x: ship.x + ship.angle.vector_x * 32,
                                  y: ship.y + ship.angle.vector_y * 32,
                                  ship: ship,
                                  angle: ship.angle,
                                  speed: 5 + ship.dx * ship.angle.vector_x + ship.dy * ship.angle.vector_y,
                                  lifetime: 120)
    end

    def input_mine create_mine, ship
      return unless create_mine
      return if ship.dead

      state.bullets << new_bullet(x: ship.x + ship.angle.vector_x * -50,
                                  y: ship.y + ship.angle.vector_y * -50,
                                  ship: ship,
                                  angle: 360.randomize(:sign, :ratio),
                                  speed: 0.02,
                                  lifetime: 600)
    end

    def input_bullets_and_mines
      return if state.bullets.length > 100

      input_bullet(inputs.controller_one.key_held.a || inputs.keyboard.key_held.space,
                   state.ship_blue)

      input_mine(inputs.controller_one.key_down.b || inputs.keyboard.key_down.down,
                 state.ship_blue)

      input_bullet(inputs.controller_two.key_held.a, state.ship_red)

      input_mine(inputs.controller_two.key_down.b, state.ship_red)
    end

    def calc_kill_ships
      alive_ships.find_all { |s| s.damage >= 5 }
                 .each do |s|
                   s.dead = true
                   create_explosion! source: s,
                                     particle_count: 20,
                                     max_speed: 20,
                                     lifetime: 30
                 end
    end

    def calc_score
      return if state.round_finished
      return if alive_ships.length > 1

      if alive_ships.first == state.ship_red
        state.ship_red_score += 1
      elsif alive_ships.first == state.ship_blue
        state.ship_blue_score += 1
      end

      state.round_finished = true
    end

    def calc_reset_ships
      return unless state.round_finished
      state.round_finished_at ||= Kernel.tick_count
      return if state.round_finished_at.elapsed_time <= 2.seconds
      start_new_round!
    end

    def start_new_round!
      state.ship_blue = new_blue_ship
      state.ship_red  = new_red_ship
      state.round_finished = false
      state.round_finished_at = nil
      state.flames.clear
      state.bullets.clear
    end

    def calc_winner
      calc_kill_ships
      calc_score
      calc_reset_ships
    end
  end

  $dueling_spaceship = DuelingSpaceships.new

  def tick args
    args.grid.origin_center!
    $dueling_spaceship.args = args
    $dueling_spaceship.tick
  end

```

### arcade/flappy dragon/credits.txt
```ruby
  # ./samples/99_genre_arcade/flappy_dragon/CREDITS.txt
  code: Amir Rajan, https://twitter.com/amirrajan
  graphics and audio: Nick Culbertson, https://twitter.com/MobyPixel


```

### arcade/flappy dragon/main.rb
```ruby
  # ./samples/99_genre_arcade/flappy_dragon/app/main.rb
  class FlappyDragon
    attr_accessor :grid, :inputs, :state, :outputs

    def tick
      defaults
      render
      calc
      process_inputs
    end

    def defaults
      state.flap_power              = 11
      state.gravity                 = 0.9
      state.ceiling                 = 600
      state.ceiling_flap_power      = 6
      state.wall_countdown_length   = 100
      state.wall_gap_size           = 100
      state.wall_countdown        ||= 0
      state.hi_score              ||= 0
      state.score                 ||= 0
      state.walls                 ||= []
      state.x                     ||= 50
      state.y                     ||= 500
      state.dy                    ||= 0
      state.scene                 ||= :menu
      state.scene_at              ||= 0
      state.difficulty            ||= :normal
      state.new_difficulty        ||= :normal
      state.countdown             ||= 4.seconds
      state.flash_at              ||= 0
    end

    def render
      outputs.sounds << "sounds/flappy-song.ogg" if Kernel.tick_count == 1
      render_score
      render_menu
      render_game
    end

    def render_score
      outputs.primitives << { x: 10, y: 710, text: "HI SCORE: #{state.hi_score}", **large_white_typeset }
      outputs.primitives << { x: 10, y: 680, text: "SCORE: #{state.score}", **large_white_typeset }
      outputs.primitives << { x: 10, y: 650, text: "DIFFICULTY: #{state.difficulty.upcase}", **large_white_typeset }
    end

    def render_menu
      return unless state.scene == :menu
      render_overlay

      outputs.labels << { x: 640, y: 700, text: "Flappy Dragon", size_enum: 50, alignment_enum: 1, **white }
      outputs.labels << { x: 640, y: 500, text: "Instructions: Press Spacebar to flap. Don't die.", size_enum: 4, alignment_enum: 1, **white }
      outputs.labels << { x: 430, y: 430, text: "[Tab]    Change difficulty", size_enum: 4, alignment_enum: 0, **white }
      outputs.labels << { x: 430, y: 400, text: "[Enter]  Start at New Difficulty ", size_enum: 4, alignment_enum: 0, **white }
      outputs.labels << { x: 430, y: 370, text: "[Escape] Cancel/Resume ", size_enum: 4, alignment_enum: 0, **white }
      outputs.labels << { x: 640, y: 300, text: "(mouse, touch, and game controllers work, too!) ", size_enum: 4, alignment_enum: 1, **white }
      outputs.labels << { x: 640, y: 200, text: "Difficulty: #{state.new_difficulty.capitalize}", size_enum: 4, alignment_enum: 1, **white }

      outputs.labels << { x: 10, y: 100, text: "Code:   @amirrajan",     **white }
      outputs.labels << { x: 10, y:  80, text: "Art:    @mobypixel",     **white }
      outputs.labels << { x: 10, y:  60, text: "Music:  @mobypixel",     **white }
      outputs.labels << { x: 10, y:  40, text: "Engine: DragonRuby GTK", **white }
    end

    def render_overlay
      overlay_rect = grid.rect.scale_rect(1.1, 0, 0)
      outputs.primitives << { x: overlay_rect.x,
                              y: overlay_rect.y,
                              w: overlay_rect.w,
                              h: overlay_rect.h,
                              r: 0, g: 0, b: 0, a: 230 }.solid!
    end

    def render_game
      render_game_over
      render_background
      render_walls
      render_dragon
      render_flash
    end

    def render_game_over
      return unless state.scene == :game
      outputs.labels << { x: 638, y: 358, text: score_text,     size_enum: 20, alignment_enum: 1 }
      outputs.labels << { x: 635, y: 360, text: score_text,     size_enum: 20, alignment_enum: 1, r: 255, g: 255, b: 255 }
      outputs.labels << { x: 638, y: 428, text: countdown_text, size_enum: 20, alignment_enum: 1 }
      outputs.labels << { x: 635, y: 430, text: countdown_text, size_enum: 20, alignment_enum: 1, r: 255, g: 255, b: 255 }
    end

    def render_background
      outputs.sprites << { x: 0, y: 0, w: 1280, h: 720, path: 'sprites/background.png' }

      scroll_point_at   = Kernel.tick_count
      scroll_point_at   = state.scene_at if state.scene == :menu
      scroll_point_at   = state.death_at if state.countdown > 0
      scroll_point_at ||= 0

      outputs.sprites << scrolling_background(scroll_point_at, 'sprites/parallax_back.png',   0.25)
      outputs.sprites << scrolling_background(scroll_point_at, 'sprites/parallax_middle.png', 0.50)
      outputs.sprites << scrolling_background(scroll_point_at, 'sprites/parallax_front.png',  1.00, -80)
    end

    def scrolling_background at, path, rate, y = 0
      [
        { x:    0 - at.*(rate) % 1440, y: y, w: 1440, h: 720, path: path },
        { x: 1440 - at.*(rate) % 1440, y: y, w: 1440, h: 720, path: path }
      ]
    end

    def render_walls
      state.walls.each do |w|
        w.sprites = [
          { x: w.x, y: w.bottom_height - 720, w: 100, h: 720, path: 'sprites/wall.png',       angle: 180 },
          { x: w.x, y: w.top_y,               w: 100, h: 720, path: 'sprites/wallbottom.png', angle: 0 }
        ]
      end
      outputs.sprites << state.walls.map(&:sprites)
    end

    def render_dragon
      state.show_death = true if state.countdown == 3.seconds

      if state.show_death == false || !state.death_at
        animation_index = state.flapped_at.frame_index 6, 2, false if state.flapped_at
        sprite_name = "sprites/dragon_fly#{animation_index.or(0) + 1}.png"
        state.dragon_sprite = { x: state.x, y: state.y, w: 100, h: 80, path: sprite_name, angle: state.dy * 1.2 }
      else
        sprite_name = "sprites/dragon_die.png"
        state.dragon_sprite = { x: state.x, y: state.y, w: 100, h: 80, path: sprite_name, angle: state.dy * 1.2 }
        sprite_changed_elapsed    = state.death_at.elapsed_time - 1.seconds
        state.dragon_sprite.angle += (sprite_changed_elapsed ** 1.3) * state.death_fall_direction * -1
        state.dragon_sprite.x     += (sprite_changed_elapsed ** 1.2) * state.death_fall_direction
        state.dragon_sprite.y     += (sprite_changed_elapsed * 14 - sprite_changed_elapsed ** 1.6)
      end

      outputs.sprites << state.dragon_sprite
    end

    def render_flash
      return unless state.flash_at

      outputs.primitives << { **grid.rect.to_hash,
                              **white,
                              a: 255 * state.flash_at.ease(20, :flip) }.solid!

      state.flash_at = 0 if state.flash_at.elapsed_time > 20
    end

    def calc
      return unless state.scene == :game
      reset_game if state.countdown == 1
      state.countdown -= 1 and return if state.countdown > 0
      calc_walls
      calc_flap
      calc_game_over
    end

    def calc_walls
      state.walls.each { |w| w.x -= 8 }

      walls_count_before_removal = state.walls.length

      state.walls.reject! { |w| w.x < -100 }

      state.score += 1 if state.walls.count < walls_count_before_removal

      state.wall_countdown -= 1 and return if state.wall_countdown > 0

      state.walls << state.new_entity(:wall) do |w|
        w.x             = grid.right
        w.opening       = grid.top
                              .randomize(:ratio)
                              .greater(200)
                              .lesser(520)
        w.bottom_height = w.opening - state.wall_gap_size
        w.top_y         = w.opening + state.wall_gap_size
      end

      state.wall_countdown = state.wall_countdown_length
    end

    def calc_flap
      state.y += state.dy
      state.dy = state.dy.lesser state.flap_power
      state.dy -= state.gravity
      return if state.y < state.ceiling
      state.y  = state.ceiling
      state.dy = state.dy.lesser state.ceiling_flap_power
    end

    def calc_game_over
      return unless game_over?

      state.death_at = Kernel.tick_count
      state.death_from = state.walls.first
      state.death_fall_direction = -1
      state.death_fall_direction =  1 if state.x > state.death_from.x
      outputs.sounds << "sounds/hit-sound.wav"
      begin_countdown
    end

    def process_inputs
      process_inputs_menu
      process_inputs_game
    end

    def process_inputs_menu
      return unless state.scene == :menu

      changediff = inputs.keyboard.key_down.tab || inputs.controller_one.key_down.select
      if inputs.mouse.click
        p = inputs.mouse.click.point
        if (p.y >= 165) && (p.y < 200) && (p.x >= 500) && (p.x < 800)
          changediff = true
        end
      end

      if changediff
        case state.new_difficulty
        when :easy
          state.new_difficulty = :normal
        when :normal
          state.new_difficulty = :hard
        when :hard
          state.new_difficulty = :flappy
        when :flappy
          state.new_difficulty = :easy
        end
      end

      if inputs.keyboard.key_down.enter || inputs.controller_one.key_down.start || inputs.controller_one.key_down.a
        state.difficulty = state.new_difficulty
        change_to_scene :game
        reset_game false
        state.hi_score = 0
        begin_countdown
      end

      if inputs.keyboard.key_down.escape || (inputs.mouse.click && !changediff) || inputs.controller_one.key_down.b
        state.new_difficulty = state.difficulty
        change_to_scene :game
      end
    end

    def process_inputs_game
      return unless state.scene == :game

      clicked_menu = false
      if inputs.mouse.click
        p = inputs.mouse.click.point
        clicked_menu = (p.y >= 620) && (p.x < 275)
      end

      if clicked_menu || inputs.keyboard.key_down.escape || inputs.keyboard.key_down.enter || inputs.controller_one.key_down.start
        change_to_scene :menu
      elsif (inputs.mouse.down || inputs.mouse.click || inputs.keyboard.key_down.space || inputs.controller_one.key_down.a) && state.countdown == 0
        state.dy = 0
        state.dy += state.flap_power
        state.flapped_at = Kernel.tick_count
        outputs.sounds << "sounds/fly-sound.wav"
      end
    end

    def white
      { r: 255, g: 255, b: 255 }
    end

    def large_white_typeset
      { size_enum: 5, alignment_enum: 0, r: 255, g: 255, b: 255 }
    end

    def at_beginning?
      state.walls.count == 0
    end

    def dragon_collision_box
      state.dragon_sprite
           .scale_rect(1.0 - collision_forgiveness, 0.5, 0.5)
           .rect_shift_right(10)
           .rect_shift_up(state.dy * 2)
    end

    def game_over?
      return true if state.y <= 0.-(500 * collision_forgiveness) && !at_beginning?

      state.walls
          .flat_map { |w| w.sprites }
          .any? do |s|
            s && s.intersect_rect?(dragon_collision_box)
          end
    end

    def collision_forgiveness
      case state.difficulty
      when :easy
        0.9
      when :normal
        0.7
      when :hard
        0.5
      when :flappy
        0.3
      else
        0.9
      end
    end

    def countdown_text
      state.countdown ||= -1
      return ""          if state.countdown == 0
      return "GO!"       if state.countdown.idiv(60) == 0
      return "GAME OVER" if state.death_at
      return "READY?"
    end

    def begin_countdown
      state.countdown = 4.seconds
    end

    def score_text
      return ""                        unless state.countdown > 1.seconds
      return ""                        unless state.death_at
      return "SCORE: 0 (LOL)"          if state.score == 0
      return "HI SCORE: #{state.score}" if state.score == state.hi_score
      return "SCORE: #{state.score}"
    end

    def reset_game set_flash = true
      state.flash_at = Kernel.tick_count if set_flash
      state.walls = []
      state.y = 500
      state.dy = 0
      state.hi_score = state.hi_score.greater(state.score)
      state.score = 0
      state.wall_countdown = state.wall_countdown_length.fdiv(2)
      state.show_death = false
      state.death_at = nil
    end

    def change_to_scene scene
      state.scene = scene
      state.scene_at = Kernel.tick_count
      inputs.keyboard.clear
      inputs.controller_one.clear
    end
  end

  $flappy_dragon = FlappyDragon.new

  def tick args
    $flappy_dragon.grid = args.grid
    $flappy_dragon.inputs = args.inputs
    $flappy_dragon.state = args.state
    $flappy_dragon.outputs = args.outputs
    $flappy_dragon.tick
  end

```

### Pong - main.rb
```ruby
  # ./samples/99_genre_arcade/pong/app/main.rb
  def tick args
    defaults args
    render args
    calc args
    input args
  end

  def defaults args
    args.state.ball ||= {
      debounce: 3 * 60,
      size: 10,
      size_half: 5,
      x: 640,
      y: 360,
      dx: 5.randomize(:sign),
      dy: 5.randomize(:sign)
    }

    args.state.paddle ||= {
      w: 10,
      h: 120
    }

    args.state.left_paddle  ||= { y: 360, score: 0 }
    args.state.right_paddle ||= { y: 360, score: 0 }
  end

  def render args
    render_center_line args
    render_scores args
    render_countdown args
    render_ball args
    render_paddles args
    render_instructions args
  end

  begin :render_methods
    def render_center_line args
      args.outputs.lines  << [640, 0, 640, 720]
    end

    def render_scores args
      args.outputs.labels << [
        { x: 320,
          y: 650,
          text: args.state.left_paddle.score,
          size_px: 40,
          anchor_x: 0.5,
          anchor_y: 0.5 },
        { x: 960,
          y: 650,
          text: args.state.right_paddle.score,
          size_px: 40,
          anchor_x: 0.5,
          anchor_y: 0.5 }
      ]
    end

    def render_countdown args
      return unless args.state.ball.debounce > 0
      args.outputs.labels << { x: 640,
                               y: 360,
                               text: "%.2f" % args.state.ball.debounce.fdiv(60),
                               size_px: 40,
                               anchor_x: 0.5,
                               anchor_y: 0.5 }
    end

    def render_ball args
      args.outputs.solids << solid_ball(args)
    end

    def render_paddles args
      args.outputs.solids << solid_left_paddle(args)
      args.outputs.solids << solid_right_paddle(args)
    end

    def render_instructions args
      args.outputs.labels << { x: 320,
                               y: 30,
                               text: "W and S keys to move left paddle.",
                               anchor_x: 0.5,
                               anchor_y: 0.5 }
      args.outputs.labels << { x: 920,
                               y: 30,
                               text: "O and L keys to move right paddle.",
                               anchor_x: 0.5,
                               anchor_y: 0.5 }
    end
  end

  def calc args
    args.state.ball.debounce -= 1 and return if args.state.ball.debounce > 0
    calc_move_ball args
    calc_collision_with_left_paddle args
    calc_collision_with_right_paddle args
    calc_collision_with_walls args
  end

  begin :calc_methods
    def calc_move_ball args
      args.state.ball.x += args.state.ball.dx
      args.state.ball.y += args.state.ball.dy
    end

    def calc_collision_with_left_paddle args
      if solid_left_paddle(args).intersect_rect? solid_ball(args)
        args.state.ball.dx *= -1
      elsif args.state.ball.x < 0
        args.state.right_paddle.score += 1
        calc_reset_round args
      end
    end

    def calc_collision_with_right_paddle args
      if solid_right_paddle(args).intersect_rect? solid_ball(args)
        args.state.ball.dx *= -1
      elsif args.state.ball.x > 1280
        args.state.left_paddle.score += 1
        calc_reset_round args
      end
    end

    def calc_collision_with_walls args
      if args.state.ball.y + args.state.ball.size_half > 720
        args.state.ball.y = 720 - args.state.ball.size_half
        args.state.ball.dy *= -1
      elsif args.state.ball.y - args.state.ball.size_half < 0
        args.state.ball.y = args.state.ball.size_half
        args.state.ball.dy *= -1
      end
    end

    def calc_reset_round args
      args.state.ball.x = 640
      args.state.ball.y = 360
      args.state.ball.dx = 5.randomize(:sign)
      args.state.ball.dy = 5.randomize(:sign)
      args.state.ball.debounce = 3 * 60
    end
  end

  def input args
    input_left_paddle args
    input_right_paddle args
  end

  def input_left_paddle args
    if args.inputs.controller_one.key_down.down  || args.inputs.keyboard.key_down.s
      args.state.left_paddle.y -= 40
    elsif args.inputs.controller_one.key_down.up || args.inputs.keyboard.key_down.w
      args.state.left_paddle.y += 40
    end
  end

  def input_right_paddle args
    if args.inputs.controller_two.key_down.down  || args.inputs.keyboard.key_down.l
      args.state.right_paddle.y -= 40
    elsif args.inputs.controller_two.key_down.up || args.inputs.keyboard.key_down.o
      args.state.right_paddle.y += 40
    end
  end

  def solid_ball args
    { x: args.state.ball.x,
      y: args.state.ball.y,
      w: args.state.ball.size,
      h: args.state.ball.size,
      anchor_x: 0.5,
      anchor_y: 0.5 }
  end

  def solid_left_paddle args
    { x: 0,
      y: args.state.left_paddle.y,
      w: args.state.paddle.w,
      h: args.state.paddle.h,
      anchor_y: 0.5 }
  end

  def solid_right_paddle args
    { x: 1280 - args.state.paddle.w,
      y: args.state.right_paddle.y,
      w: args.state.paddle.w,
      h: args.state.paddle.h,
      anchor_y: 0.5 }
  end

```

### Snakemoji - main.rb
```ruby
  # ./samples/99_genre_arcade/snakemoji/app/main.rb
  # coding: utf-8
  ################################
  #  So I was working on a snake game while
  #  learning DragonRuby, and at some point I had a thought
  #  what if I use "😀" as a function name, surely it wont work right...?
  #  RIGHT....?
  #  BUT IT DID, IT WORKED
  #  it all went downhill from then
  #  Created by Anton K. (ai Doge)
  #  https://gist.github.com/scorp200
  #############LICENSE############
  #  Feel free to use this anywhere and however you want
  #  You can sell this to EA for $1,000,000 if you want, its completely free.
  #  Just rememeber you are helping this... thing... to spread...
  #  ALSO! I am not liable for any mental, physical or financial damage caused.
  #############LICENSE############


  class Array
    #Helper function
    def move! vector
      self.x += vector.x
      self.y += vector.y
      return self
    end

    #Helper function to draw snake body
    def draw! 🎮, 📺, color
      translate 📺.solids, 🎮.⛓, [self.x * 🎮.⚖️ + 🎮.🛶 / 2, self.y * 🎮.⚖️ + 🎮.🛶 / 2, 🎮.⚖️ - 🎮.🛶, 🎮.⚖️ - 🎮.🛶, color]
    end

    #This is where it all started, I was trying to find  good way to multiply a map by a number, * is already used so is **
    #I kept trying different combinations of symbols, when suddenly...
    def 😀 value
      self.map {|d| d * value}
    end
  end

  #Draw stuff with an offset
  def translate output_collection, ⛓, what
    what.x += ⛓.x
    what.y += ⛓.y
    output_collection << what
  end

  BLUE = [33, 150, 243]
  RED = [244, 67, 54]
  GOLD = [255, 193, 7]
  LAST = 0

  def tick args
    defaults args.state
    render args.state, args.outputs
    input args.state, args.inputs
    update args.state
  end

  def update 🎮
    #Update every 10 frames
    if 🎮.tick_count.mod_zero? 10
      #Add new snake body piece at head's location
      🎮.🐍 << [*🎮.🤖]
      #Assign Next Direction to Direction
      🎮.🚗 = *🎮.🚦

      #Trim the snake a bit if its longer than current size
      if 🎮.🐍.length > 🎮.🛒
        🎮.🐍 = 🎮.🐍[-🎮.🛒..-1]
      end

      #Move the head in the Direction
      🎮.🤖.move! 🎮.🚗

      #If Head is outside the playing field, or inside snake's body restart game
      if 🎮.🤖.x < 0 || 🎮.🤖.x >= 🎮.🗺.x || 🎮.🤖.y < 0 || 🎮.🤖.y >= 🎮.🗺.y || 🎮.🚗 != [0, 0] && 🎮.🐍.any? {|s| s == 🎮.🤖}
        LAST = 🎮.💰
        🎮.as_hash.clear
        return
      end

      #If head lands on food add size and score
      if 🎮.🤖 == 🎮.🍎
        🎮.🛒 += 1
        🎮.💰 += (🎮.🛒 * 0.8).floor.to_i + 5
        spawn_🍎 🎮
        puts 🎮.🍎
      end
    end

    #Every second remove 1 point
    if 🎮.💰 > 0 && 🎮.tick_count.mod_zero?(60)
      🎮.💰 -= 1
    end
  end

  def spawn_🍎 🎮
    #Food
    🎮.🍎 ||= [*🎮.🤖]
    #Randomly spawns food inside the playing field, keep doing this if the food keeps landing on the snake's body
    while 🎮.🐍.any? {|s| s == 🎮.🍎} || 🎮.🍎 == 🎮.🤖 do
      🎮.🍎 = [rand(🎮.🗺.x), rand(🎮.🗺.y)]
    end
  end

  def render 🎮, 📺
    #Paint the background black
    📺.solids << [0, 0, 1280, 720, 0, 0, 0, 255]
    #Draw a border for the playing field
    translate 📺.borders, 🎮.⛓, [0, 0, 🎮.🗺.x * 🎮.⚖️, 🎮.🗺.y * 🎮.⚖️, 255, 255, 255]

    #Draw the snake's body
    🎮.🐍.map do |🐍| 🐍.draw! 🎮, 📺, BLUE end
    #Draw the head
    🎮.🤖.draw! 🎮, 📺, BLUE
    #Draw the food
    🎮.🍎.draw! 🎮, 📺, RED

    #Draw current score
    translate 📺.labels, 🎮.⛓, [5, 715, "Score: #{🎮.💰}", GOLD]
    #Draw your last score, if any
    translate 📺.labels, 🎮.⛓, [[*🎮.🤖.😀(🎮.⚖️)].move!([0, 🎮.⚖️ * 2]), "Your Last score is #{LAST}", 0, 1, GOLD] unless LAST == 0 || 🎮.🚗 != [0, 0]
    #Draw starting message, only if Direction is 0
    translate 📺.labels, 🎮.⛓, [🎮.🤖.😀(🎮.⚖️), "Press any Arrow key to start", 0, 1, GOLD] unless 🎮.🚗 != [0, 0]
  end

  def input 🎮, 🕹
    #Left and Right keyboard input, only change if X direction is 0
    if 🕹.keyboard.key_held.left && 🎮.🚗.x == 0
      🎮.🚦 = [-1, 0]
    elsif 🕹.keyboard.key_held.right && 🎮.🚗.x == 0
      🎮.🚦 = [1, 0]
    end

    #Up and Down keyboard input, only change if Y direction is 0
    if 🕹.keyboard.key_held.up && 🎮.🚗.y == 0
      🎮.🚦 = [0, 1]
    elsif 🕹.keyboard.key_held.down && 🎮.🚗.y == 0
      🎮.🚦 = [0, -1]
    end
  end

  def defaults 🎮
    #Playing field size
    🎮.🗺 ||= [20, 20]
    #Scale for drawing, screen height / Field height
    🎮.⚖️ ||= 720 / 🎮.🗺.y
    #Offset, offset all rendering to the center of the screen
    🎮.⛓ ||= [(1280 - 720).fdiv(2), 0]
    #Padding, make the snake body slightly smaller than the scale
    🎮.🛶 ||= (🎮.⚖️ * 0.2).to_i
    #Snake Size
    🎮.🛒 ||= 3
    #Snake head, the only part we are actually controlling
    🎮.🤖 ||= [🎮.🗺.x / 2, 🎮.🗺.y / 2]
    #Snake body map, follows the head
    🎮.🐍 ||= []
    #Direction the head moves to
    🎮.🚗 ||= [0, 0]
    #Next_Direction, during input check only change this variable and then when game updates asign this to Direction
    🎮.🚦 ||= [*🎮.🚗]
    #Your score
    🎮.💰 ||= 0
    #Spawns Food randomly
    spawn_🍎(🎮) unless 🎮.🍎
  end

```

### Solar System - main.rb
```ruby
  # ./samples/99_genre_arcade/solar_system/app/main.rb
  # Focused tutorial video: https://s3.amazonaws.com/s3.dragonruby.org/dragonruby-nddnug-workshop.mp4
  # Workshop/Presentation which provides motivation for creating a game engine: https://www.youtube.com/watch?v=S3CFce1arC8

  def defaults args
    args.outputs.background_color = [0, 0, 0]
    args.state.x ||= 640
    args.state.y ||= 360
    args.state.stars ||= 100.map do
      [1280 * rand, 720 * rand, rand.fdiv(10), 255 * rand, 255 * rand, 255 * rand]
    end

    args.state.sun ||= args.state.new_entity(:sun) do |s|
      s.s = 100
      s.path = 'sprites/sun.png'
    end

    args.state.planets = [
      [:mercury,   65,  5,          88],
      [:venus,    100, 10,         225],
      [:earth,    120, 10,         365],
      [:mars,     140,  8,         687],
      [:jupiter,  280, 30, 365 *  11.8],
      [:saturn,   350, 20, 365 *  29.5],
      [:uranus,   400, 15, 365 *    84],
      [:neptune,  440, 15, 365 * 164.8],
      [:pluto,    480,  5, 365 * 247.8],
    ].map do |name, distance, size, year_in_days|
      args.state.new_entity(name) do |p|
        p.path = "sprites/#{name}.png"
        p.distance = distance * 0.7
        p.s = size * 0.7
        p.year_in_days = year_in_days
      end
    end

    args.state.ship ||= args.state.new_entity(:ship) do |s|
      s.x = 1280 * rand
      s.y = 720 * rand
      s.angle = 0
    end
  end

  def to_sprite args, entity
    x = 0
    y = 0

    if entity.year_in_days
      day = Kernel.tick_count
      day_in_year = day % entity.year_in_days
      entity.random_start_day ||= day_in_year * rand
      percentage_of_year = day_in_year.fdiv(entity.year_in_days)
      angle = 365 * percentage_of_year
      x = angle.vector_x(entity.distance)
      y = angle.vector_y(entity.distance)
    end

    [640 + x - entity.s.half, 360 + y - entity.s.half, entity.s, entity.s, entity.path]
  end

  def render args
    args.outputs.solids << [0, 0, 1280, 720]

    args.outputs.sprites << args.state.stars.map do |x, y, _, r, g, b|
      [x, y, 10, 10, 'sprites/star.png', 0, 100, r, g, b]
    end

    args.outputs.sprites << to_sprite(args, args.state.sun)
    args.outputs.sprites << args.state.planets.map { |p| to_sprite args, p }
    args.outputs.sprites << [args.state.ship.x, args.state.ship.y, 20, 20, 'sprites/ship.png', args.state.ship.angle]
  end

  def calc args
    args.state.stars = args.state.stars.map do |x, y, speed, r, g, b|
      x += speed
      y += speed
      x = 0 if x > 1280
      y = 0 if y > 720
      [x, y, speed, r, g, b]
    end

    if Kernel.tick_count == 0
      args.audio[:bg_music] = {
        input: 'sounds/bg.ogg',
        looping: true
      }
    end
  end

  def process_inputs args
    if args.inputs.keyboard.left || args.inputs.controller_one.key_held.left
      args.state.ship.angle += 1
    elsif args.inputs.keyboard.right || args.inputs.controller_one.key_held.right
      args.state.ship.angle -= 1
    end

    if args.inputs.keyboard.up || args.inputs.controller_one.key_held.a
      args.state.ship.x += args.state.ship.angle.x_vector
      args.state.ship.y += args.state.ship.angle.y_vector
    end
  end

  def tick args
    defaults args
    render args
    calc args
    process_inputs args
  end

  def r
    $gtk.reset
  end

```

### Sound Golf - main.rb
```ruby
  # ./samples/99_genre_arcade/sound_golf/app/main.rb
  =begin

   APIs Listing that haven't been encountered in previous sample apps:

   - sample: Chooses random element from array.
     In this sample app, the target note is set by taking a sample from the collection
     of available notes.

   Reminders:
   - args.grid.(left|right|top|bottom): Pixel value for the boundaries of the virtual
     720 p screen (Dragon Ruby Game Toolkits's virtual resolution is always 1280x720).

   - args.state.new_entity: Used when we want to create a new object, like a sprite or button.
     For example, if we want to create a new button, we would declare it as a new entity and
     then define its properties.

   - String interpolation: Uses #{} syntax; everything between the #{ and the } is evaluated
     as Ruby code, and the placeholder is replaced with its corresponding value or result.

   - args.outputs.labels: An array. The values generate a label.
     The parameters are [X, Y, TEXT, SIZE, ALIGNMENT, RED, GREEN, BLUE, ALPHA, FONT STYLE]
     For more information about labels, go to mygame/documentation/02-labels.md.

   - find_all: Finds all elements from a collection that meet a certain requirements (and excludes the ones that don't).

   - first: Returns the first element of an array.

   - inside_rect: Returns true or false depending on if the point is inside the rect.

   - to_sym: Returns symbol corresponding to string. Will create a symbol if it does
     not already exist.

  =end

  # This sample app allows users to test their musical skills by matching the piano sound that plays in each
  # level to the correct note.

  # Runs all the methods necessary for the game to function properly.
  def tick args
    defaults args
    render args
    calc args
    input_mouse args
    tick_instructions args, "Sample app shows how to play sounds. args.outputs.sounds << \"path_to_wav.wav\""
  end

  # Sets default values and creates empty collections
  # Initialization happens in the first frame only
  def defaults args
    args.state.notes ||= []
    args.state.click_feedbacks ||= []
    args.state.current_level ||= 1
    args.state.times_wrong ||= 0 # when game starts, user hasn't guessed wrong yet
  end

  # Uses a label to display current level, and shows the score
  # Creates a button to play the sample note, and displays the available notes that could be a potential match
  def render args

    # grid.w_half positions the label in the horizontal center of the screen.
    args.outputs.labels << [args.grid.w_half, args.grid.top.shift_down(40), "Hole #{args.state.current_level} of 9", 0, 1, 0, 0, 0]

    render_score args # shows score on screen

    args.state.play_again_button ||= { x: 560, y: args.grid.h * 3 / 4 - 40, w: 160, h: 60, label: 'again' } # array definition, text/title
    args.state.play_note_button ||= { x: 560, y: args.grid.h * 3 / 4 - 40, w: 160, h: 60, label: 'play' }

    if args.state.game_over # if game is over, a "play again" button is shown
      # Calculations ensure that Play Again label is displayed in center of border
      # Remove calculations from y parameters and see what happens to border and label placement
      args.outputs.labels <<  [args.grid.w_half, args.grid.h * 3 / 4, "Play Again", 0, 1, 0, 0, 0] # outputs label
      args.outputs.borders << args.state.play_again_button # outputs border
    else # otherwise, if game is not over
      # Calculations ensure that label appears in center of border
      args.outputs.labels <<  [args.grid.w_half, args.grid.h * 3 / 4, "Play Note ##{args.state.current_level}", 0, 1, 0, 0, 0] # outputs label
      args.outputs.borders << args.state.play_note_button # outputs border
    end

    return if args.state.game_over # return if game is over

    args.outputs.labels <<   [args.grid.w_half, 400, "I think the note is a(n)...",  0, 1, 0, 0, 0] # outputs label

    # Shows all of the available notes that can be potential matches.
    available_notes.each_with_index do |note, i|
      args.state.notes[i] ||= piano_button(args, note, i + 1) # calls piano_button method on each note (creates label and border)
      args.outputs.labels <<   args.state.notes[i].label # outputs note on screen with a label and a border
      args.outputs.borders <<  args.state.notes[i].border
    end

    # Shows whether or not the user is correct by filling the screen with either red or green
    args.outputs.solids << args.state.click_feedbacks.map { |c| c.solid }
  end

  # Shows the score (number of times the user guesses wrong) onto the screen using labels.
  def render_score args
    if args.state.times_wrong == 0 # if the user has guessed wrong zero times, the score is par
      args.outputs.labels << [args.grid.w_half, args.grid.top.shift_down(80), "Score: PAR", 0, 1, 0, 0, 0]
    else # otherwise, number of times the user has guessed wrong is shown
      args.outputs.labels << [args.grid.w_half, args.grid.top.shift_down(80), "Score: +#{args.state.times_wrong}", 0, 1, 0, 0, 0] # shows score using string interpolation
    end
  end

  # Sets the target note for the level and performs calculations on click_feedbacks.
  def calc args
    args.state.target_note ||= available_notes.sample # chooses a note from available_notes collection as target note
    args.state.click_feedbacks.each    { |c| c.solid[-1] -= 5 } # remove this line and solid color will remain on screen indefinitely
    # comment this line out and the solid color will keep flashing on screen instead of being removed from click_feedbacks collection
    args.state.click_feedbacks.reject! { |c| c.solid[-1] <= 0 }
  end

  # Uses input from the user to play the target note, as well as the other notes that could be a potential match.
  def input_mouse args
    return unless args.inputs.mouse.click # return unless the mouse is clicked

    # finds button that was clicked by user
    button_clicked = args.outputs.borders.find_all do |b| # go through borders collection to find all borders that meet requirements
      args.inputs.mouse.click.point.inside_rect? b # find button border that mouse was clicked inside of
    end.find_all { |b| b.is_a? Hash }.first # reject, return first element

    return unless button_clicked # return unless button_clicked as a value (a button was clicked)

    queue_click_feedback args, # calls queue_click_feedback method on the button that was clicked
                         button_clicked.x,
                         button_clicked.y,
                         button_clicked.w,
                         button_clicked.h,
                         150, 100, 200 # sets color of button to shade of purple

    if button_clicked[:label] == 'play' # if "play note" button is pressed
      args.outputs.sounds << "sounds/#{args.state.target_note}.wav" # sound of target note is output
    elsif button_clicked[:label] == 'again' # if "play game again" button is pressed
      args.state.target_note = nil # no target note
      args.state.current_level = 1 # starts at level 1 again
      args.state.times_wrong = 0 # starts off with 0 wrong guesses
      args.state.game_over = false # the game is not over (because it has just been restarted)
    else # otherwise if neither of those buttons were pressed
      args.outputs.sounds << "sounds/#{button_clicked[:label]}.wav" # sound of clicked note is played
      if button_clicked[:label] == args.state.target_note # if clicked note is target note
        args.state.target_note = nil # target note is emptied

        if args.state.current_level < 9 # if game hasn't reached level 9
          args.state.current_level += 1 # game goes to next level
        else # otherwise, if game has reached level 9
          args.state.game_over = true # the game is over
        end

        queue_click_feedback args, 0, 0, args.grid.w, args.grid.h, 100, 200, 100 # green shown if user guesses correctly
      else # otherwise, if clicked note is not target note
        args.state.times_wrong += 1 # increments times user guessed wrong
        queue_click_feedback args, 0, 0, args.grid.w, args.grid.h, 200, 100, 100 # red shown is user guesses wrong
      end
    end
  end

  # Creates a collection of all of the available notes as symbols
  def available_notes
    [:C3, :D3, :E3, :F3, :G3, :A3, :B3, :C4]
  end

  # Creates buttons for each note, and sets a label (the note's name) and border for each note's button.
  def piano_button args, note, position
    args.state.new_entity(:button) do |b| # declares button as new entity
      b.label  =  [460 + 40.mult(position), args.grid.h * 0.4, "#{note}", 0, 1, 0, 0, 0] # label definition
      b.border =  { x: 460 + 40.mult(position) - 20, y: args.grid.h * 0.4 - 32, w: 40, h: 40, label: note } # border definition, text/title; 20 subtracted so label is in center of border
    end
  end

  # Color of click feedback changes depending on what button was clicked, and whether the guess is right or wrong
  # If a button is clicked, the inside of button is purple (see input_mouse method)
  # If correct note is clicked, screen turns green
  # If incorrect note is clicked, screen turns red (again, see input_mouse method)
  def queue_click_feedback args, x, y, w, h, *color
    args.state.click_feedbacks << args.state.new_entity(:click_feedback) do |c| # declares feedback as new entity
      c.solid =  [x, y, w, h, *color, 255] # sets color
    end
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

### Squares - main.rb
```ruby
  # ./samples/99_genre_arcade/squares/app/main.rb
  # game concept from: https://youtu.be/Tz-AinJGDIM

  # This class encapsulates the logic of a button that pulses when clicked.
  # It is used in the StartScene and GameOverScene classes.
  class PulseButton
    # a block is passed into the constructor and is called when the button is clicked,
    # and after the pulse animation is complete
    def initialize rect, text, &on_click
      @rect = rect
      @text = text
      @on_click = on_click
      @pulse_animation_spline = [[0.0, 0.90, 1.0, 1.0], [1.0, 0.10, 0.0, 0.0]]
      @duration = 10
    end

    # the button is ticked every frame and check to see if the mouse
    # intersects the button's bounding box.
    # if it does, then pertinent information is stored in the @clicked_at variable
    # which is used to calculate the pulse animation
    def tick tick_count, mouse
      @tick_count = tick_count

      if @clicked_at && @clicked_at.elapsed_time > @duration
        @clicked_at = nil
        @on_click.call
      end

      return if !mouse.click
      return if !mouse.inside_rect? @rect
      @clicked_at = tick_count
    end

    # this function returns an array of primitives that can be rendered
    def prefab easing
      # calculate the percentage of the pulse animation that has completed
      # and use the percentage to compute the size and position of the button
      perc = if @clicked_at
               easing.ease_spline @clicked_at, @tick_count, @duration, @pulse_animation_spline
             else
               0
             end

      rect = { x: @rect.x - 50 * perc / 2,
               y: @rect.y - 50 * perc / 2,
               w: @rect.w + 50 * perc,
               h: @rect.h + 50 * perc }

      point = { x: @rect.x + @rect.w / 2, y: @rect.y + @rect.h / 2 }
      [
        { **rect, path: :pixel },
        { **point, text: @text, size_px: 32, anchor_x: 0.5, anchor_y: 0.5 }
      ]
    end
  end

  # the start scene is loaded when the game is started
  # it contains a PulseButton that starts the game by setting the next_scene to :game and
  # setting the started_at time
  class StartScene
    attr_gtk

    def initialize args
      self.args = args
      @play_button = PulseButton.new layout.rect(row: 6, col: 11, w: 2, h: 2), "play" do
        state.next_scene = :game
        state.events.game_started_at = Kernel.tick_count
        state.events.game_over_at = nil
      end
    end

    def tick
      return if state.current_scene != :start
      @play_button.tick Kernel.tick_count, inputs.mouse
      outputs[:start_scene].transient!
      outputs[:start_scene].labels << layout.point(row: 0, col: 12).merge(text: "Squares", anchor_x: 0.5, anchor_y: 0.5, size_px: 64)
      outputs[:start_scene].primitives << @play_button.prefab(easing)
    end
  end

  # the game over scene is displayed when the game is over
  # it contains a PulseButton that restarts the game by setting the next_scene to :game and
  # setting the game_retried_at time
  class GameOverScene
    attr_gtk

    def initialize args
      self.args = args
      @replay_button = PulseButton.new layout.rect(row: 6, col: 11, w: 2, h: 2), "replay" do
        state.next_scene = :game
        state.events.game_retried_at = Kernel.tick_count
        state.events.game_over_at = nil
      end
    end

    def tick
      return if state.current_scene != :game_over
      @replay_button.tick Kernel.tick_count, inputs.mouse
      outputs[:game_over_scene].transient!
      outputs[:game_over_scene].labels << layout.point(row: 0, col: 12).merge(text: "Game Over", anchor_x: 0.5, anchor_y: 0.5, size_px: 64)
      outputs[:game_over_scene].primitives << @replay_button.prefab(easing)

      rect = layout.point row: 2, col: 12
      outputs[:game_over_scene].primitives << rect.merge(text: state.score_last_game, anchor_x: 0.5, anchor_y: 0.5, size_px: 128, **state.red_color)

      rect = layout.point row: 4, col: 12
      outputs[:game_over_scene].primitives << rect.merge(text: "BEST #{state.best_score}", anchor_x: 0.5, anchor_y: 0.5, size_px: 64, **state.gray_color)
    end
  end

  # the game scene contains the game logic
  class GameScene
    attr_gtk

    def tick
      defaults
      calc
      render
    end

    def defaults
      return if started_at != Kernel.tick_count

      # initalization of scene_state variables for the game
      scene_state.score_animation_spline = [[0.0, 0.66, 1.0, 1.0], [1.0, 0.33, 0.0, 0.0]]
      scene_state.launch_particle_queue = []
      scene_state.scale_down_particles_queue = []
      scene_state.score = 0
      scene_state.square_number = 1
      scene_state.squares = []
      scene_state.square_spawn_rate = 60
      scene_state.movement_outer_rect = layout.rect(row: 11, col: 7, w: 10, h: 1).merge(path: :pixel, **state.gray_color)

      scene_state.player = { x: geometry.rect_center_point(movement_outer_rect).x,
                             y: movement_outer_rect.y,
                             w: movement_outer_rect.h,
                             h: movement_outer_rect.h,
                             path: :pixel,
                             movement_direction: 1,
                             movement_speed: 8,
                             **args.state.red_color }

      scene_state.movement_inner_rect = { x: movement_outer_rect.x + player.w * 1,
                                          y: movement_outer_rect.y,
                                          w: movement_outer_rect.w - player.w * 2,
                                          h: movement_outer_rect.h }
    end

    def calc
      calc_game_over_at
      calc_particles

      # game logic is only calculated if the current scene is :game
      return if state.current_scene != :game

      # we don't want the game loop to start for half a second after the game starts
      # this gives enough time for the game scene to animate in
      return if !started_at || started_at.elapsed_time <= 30

      calc_player
      calc_squares
      calc_game_over
    end

    # this function calculates the point in the time the game is over
    # an intermediary variable stored in scene_state.death_at is consulted
    # before transitioning to the game over scene to ensure that particle animations
    # have enough time to complete before the game over scene is rendered
    def calc_game_over_at
      return if !death_at
      return if death_at.elapsed_time < 120
      state.events.game_over_at ||= Kernel.tick_count
    end

    # this function calculates the particles
    # there are two queues of particles that are processed
    # the launch_particle_queue contains particles that are launched when the player is hit
    # the scale_down_particles_queue contains particles that need to be scaled down
    def calc_particles
      return if !started_at

      scene_state.launch_particle_queue.each do |p|
        p.x += p.launch_angle.vector_x * p.speed
        p.y += p.launch_angle.vector_y * p.speed
        p.speed *= 0.90
        p.d_a ||= 1
        p.a -= 1 * p.d_a
        p.d_a *= 1.1
      end

      scene_state.launch_particle_queue.reject! { |p| p.a <= 0 }

      scene_state.scale_down_particles_queue.each do |p|
        next if p.start_at > Kernel.tick_count
        p.scale_speed = p.scale_speed.abs
        p.x += p.scale_speed
        p.y += p.scale_speed
        p.w -= p.scale_speed * 2
        p.h -= p.scale_speed * 2
      end

      scene_state.scale_down_particles_queue.reject! { |p| p.w <= 0 }
    end

    def render
      return if !started_at
      scene_outputs.primitives << game_scene_score_prefab
      scene_outputs.primitives << scene_state.movement_outer_rect.merge(a: 128)
      scene_outputs.primitives << squares
      scene_outputs.primitives << player_prefab
      scene_outputs.primitives << scene_state.launch_particle_queue
      scene_outputs.primitives << scene_state.scale_down_particles_queue
    end

    # this function returns the rendering primitive for the score
    def game_scene_score_prefab
      score = if death_at
                state.score_last_game
              else
                scene_state.score
              end

      label_scale_prec = easing.ease_spline(scene_state.score_at || 0, Kernel.tick_count, 15, scene_state.score_animation_spline)
      rect = layout.point row: 4, col: 12
      rect.merge(text: score, anchor_x: 0.5, anchor_y: 0.5, size_px: 128 + 50 * label_scale_prec, **state.gray_color)
    end

    def player_prefab
      return nil if death_at
      scale_perc = easing.ease(started_at + 30, Kernel.tick_count, 15, :smooth_start_quad, :flip)
      player.merge(x: player.x - player.w / 2 * scale_perc, y: player.y + player.h / 2 * scale_perc,
                   w: player.w * (1 - scale_perc), h: player.h * (1 - scale_perc))
    end

    # controls the player movement and change in direction of the player when the mouse is clicked
    def calc_player
      player.x += player.movement_speed * player.movement_direction
      player.movement_direction *= -1 if !geometry.inside_rect? player, scene_state.movement_outer_rect
      return if !inputs.mouse.click
      return if !geometry.inside_rect? player, movement_inner_rect
      player.movement_direction = -player.movement_direction
    end

    # computes the squares movement
    def calc_squares
      squares << new_square if Kernel.tick_count.zmod? scene_state.square_spawn_rate

      squares.each do |square|
        square.angle += 1
        square.x += square.dx
        square.y += square.dy
      end

      squares.reject! { |square| (square.y + square.h) < 0 }
    end

    # determines if score should be incremented or if the game should be over
    def calc_game_over
      collision = geometry.find_intersect_rect player, squares
      return if !collision
      if collision.type == :good
        scene_state.score += 1
        scene_state.score_at = Kernel.tick_count
        scene_state.scale_down_particles_queue << collision.merge(start_at: Kernel.tick_count, scale_speed: -2)
        squares.delete collision
      else
        generate_death_particles
        state.best_score = scene_state.score if scene_state.score > state.best_score
        squares.clear
        state.score_last_game = scene_state.score
        scene_state.score = 0
        scene_state.square_number = 1
        scene_state.death_at = Kernel.tick_count
        state.next_scene = :game_over
      end
    end

    # this function generates the particles when the player is hit
    def generate_death_particles
      square_particles = squares.map { |b| b.merge(start_at: Kernel.tick_count + 60, scale_speed: -1) }

      scene_state.scale_down_particles_queue.concat square_particles

      # generate 12 particles with random size, launch angle and speed
      player_particles = 12.map do
        size = rand * player.h * 0.5 + 10
        player.merge(w: size, h: size, a: 255, launch_angle: rand * 180, speed: 10 + rand * 50)
      end

      scene_state.launch_particle_queue.concat player_particles
    end

    # this function returns a new square
    # every 5th square is a good square (increases the score)
    def new_square
      x = movement_inner_rect.x + rand * movement_inner_rect.w

      dx = if x > geometry.rect_center_point(movement_inner_rect).x
             -0.9
           else
             0.9
           end

      if scene_state.square_number.zmod? 5
        type = :good
        color = state.red_color
      else
        type = :bad
        color = { r: 0, g: 0, b: 0 }
      end

      scene_state.square_number += 1

      { x: x - 16, y: 1300, w: 32, h: 32,
        dx: dx, dy: -5,
        angle: 0, type: type,
        path: :pixel, **color }
    end

    # death_at is the point in time that the player died
    # the death_at value is an intermediary variable that is used to calculate the death animation
    # before setting state.game_over_at
    def death_at
      return nil if !scene_state.death_at
      return nil if scene_state.death_at < started_at
      scene_state.death_at
    end

    # started_at is the point in time that the player started (or retried) the game
    def started_at
      state.events.game_retried_at || state.events.game_started_at
    end

    def scene_state
      state.game_scene ||= {}
    end

    def scene_outputs
      outputs[:game_scene].transient!
    end

    def player
      scene_state.player
    end

    def movement_outer_rect
      scene_state.movement_outer_rect
    end

    def movement_inner_rect
      scene_state.movement_inner_rect
    end

    def squares
      scene_state.squares
    end
  end

  class RootScene
    attr_gtk

    def initialize args
      self.args = args
      @start_scene = StartScene.new args
      @game_scene = GameScene.new
      @game_over_scene = GameOverScene.new args
    end

    def tick
      outputs.background_color = [237, 237, 237]
      init_game
      state.scene_at_tick_start = state.current_scene
      tick_start_scene
      tick_game_scene
      tick_game_over_scene
      render_scenes
      transition_to_next_scene
    end

    def tick_start_scene
      @start_scene.args = args
      @start_scene.tick
    end

    def tick_game_scene
      @game_scene.args = args
      @game_scene.tick
    end

    def tick_game_over_scene
      @game_over_scene.args = args
      @game_over_scene.tick
    end

    # initlalization of game state that is shared between scenes
    def init_game
      return if Kernel.tick_count != 0

      state.current_scene = :start

      state.red_color = { r: 222, g: 63, b: 66 }
      state.gray_color = { r: 128, g: 128, b: 128 }

      state.events ||= {
        game_over_at: nil,
        game_started_at: nil,
        game_retried_at: nil
      }

      state.score_last_game = 0
      state.best_score = 0
      state.viewport = { x: 0, y: 0, w: 1280, h: 720 }
    end

    def transition_to_next_scene
      if state.scene_at_tick_start != state.current_scene
        raise "state.current_scene was changed during the tick. This is not allowed (use state.next_scene to set the scene to transfer to)."
      end

      return if !state.next_scene
      state.current_scene = state.next_scene
      state.next_scene = nil
    end

    # this function renders the scenes with a transition effect
    # based off of timestamps stored in state.events
    def render_scenes
      if state.events.game_over_at
        in_y = transition_in_y state.events.game_over_at
        out_y = transition_out_y state.events.game_over_at
        outputs.sprites << state.viewport.merge(y: out_y, path: :game_scene)
        outputs.sprites << state.viewport.merge(y: in_y, path: :game_over_scene)
      elsif state.events.game_retried_at
        in_y = transition_in_y state.events.game_retried_at
        out_y = transition_out_y state.events.game_retried_at
        outputs.sprites << state.viewport.merge(y: out_y, path: :game_over_scene)
        outputs.sprites << state.viewport.merge(y: in_y, path: :game_scene)
      elsif state.events.game_started_at
        in_y = transition_in_y state.events.game_started_at
        out_y = transition_out_y state.events.game_started_at
        outputs.sprites << state.viewport.merge(y: out_y, path: :start_scene)
        outputs.sprites << state.viewport.merge(y: in_y, path: :game_scene)
      else
        in_y = transition_in_y 0
        start_scene_perc = easing.ease(0, Kernel.tick_count, 30, :smooth_stop_quad, :flip)
        outputs.sprites << state.viewport.merge(y: in_y, path: :start_scene)
      end
    end

    def transition_in_y start_at
      easing.ease(start_at, Kernel.tick_count, 30, :smooth_stop_quad, :flip) * -1280
    end

    def transition_out_y start_at
      easing.ease(start_at, Kernel.tick_count, 30, :smooth_stop_quad) * 1280
    end
  end

  def tick args
    $game ||= RootScene.new args
    $game.args = args
    $game.tick

    if args.inputs.keyboard.key_down.forward_slash
      @show_fps = !@show_fps
    end
    if @show_fps
      args.outputs.primitives << args.gtk.current_framerate_primitives
    end
  end

  $gtk.reset

```

### Twinstick - main.rb
```ruby
  # ./samples/99_genre_arcade/twinstick/app/main.rb
  def tick args
    args.state.player         ||= {x: 600, y: 320, w: 80, h: 80, path: 'sprites/circle-white.png', vx: 0, vy: 0, health: 10, cooldown: 0, score: 0}
    args.state.enemies        ||= []
    args.state.player_bullets ||= []
    spawn_enemies args
    kill_enemies args
    move_enemies args
    move_bullets args
    move_player args
    fire_player args
    args.state.player[:r] = args.state.player[:g] = args.state.player[:b] = (args.state.player[:health] * 25.5).clamp(0, 255)
    label_color           = args.state.player[:health] <= 5 ? 255 : 0
    args.outputs.labels << [
        {
            x: args.state.player.x + 40, y: args.state.player.y + 60, alignment_enum: 1, text: "#{args.state.player[:health]} HP",
            r: label_color, g: label_color, b: label_color
        }, {
            x: args.state.player.x + 40, y: args.state.player.y + 40, alignment_enum: 1, text: "#{args.state.player[:score]} PTS",
            r: label_color, g: label_color, b: label_color, size_enum: 2 - args.state.player[:score].to_s.length,
        }
    ]
    args.outputs.sprites << [args.state.player, args.state.enemies, args.state.player_bullets]
    args.state.clear! if args.state.player[:health] < 0 # Reset the game if the player's health drops below zero
  end

  def spawn_enemies args
    # Spawn enemies more frequently as the player's score increases.
    if rand < (100+args.state.player[:score])/(10000 + args.state.player[:score]) || Kernel.tick_count.zero?
      theta = rand * Math::PI * 2
      args.state.enemies << {
          x: 600 + Math.cos(theta) * 800, y: 320 + Math.sin(theta) * 800, w: 80, h: 80, path: 'sprites/circle-white.png',
          r: (256 * rand).floor, g: (256 * rand).floor, b: (256 * rand).floor
      }
    end
  end

  def kill_enemies args
    args.state.enemies.reject! do |enemy|
      # Check if enemy and player are within 80 pixels of each other (i.e. overlapping)
      if 6400 > (enemy.x - args.state.player.x) ** 2 + (enemy.y - args.state.player.y) ** 2
        # Enemy is touching player. Kill enemy, and reduce player HP by 1.
        args.state.player[:health] -= 1
      else
        args.state.player_bullets.any? do |bullet|
          # Check if enemy and bullet are within 50 pixels of each other (i.e. overlapping)
          if 2500 > (enemy.x - bullet.x + 30) ** 2 + (enemy.y - bullet.y + 30) ** 2
            # Increase player health by one for each enemy killed by a bullet after the first enemy, up to a maximum of 10 HP
            args.state.player[:health] += 1 if args.state.player[:health] < 10 && bullet[:kills] > 0
            # Keep track of how many enemies have been killed by this particular bullet
            bullet[:kills]             += 1
            # Earn more points by killing multiple enemies with one shot.
            args.state.player[:score]  += bullet[:kills]
          end
        end
      end
    end
  end

  def move_enemies args
    args.state.enemies.each do |enemy|
      # Get the angle from the enemy to the player
      theta   = Math.atan2(enemy.y - args.state.player.y, enemy.x - args.state.player.x)
      # Convert the angle to a vector pointing at the player
      dx, dy  = theta.to_degrees.vector 5
      # Move the enemy towards thr player
      enemy.x -= dx
      enemy.y -= dy
    end
  end

  def move_bullets args
    args.state.player_bullets.each do |bullet|
      # Move the bullets according to the bullet's velocity
      bullet.x += bullet[:vx]
      bullet.y += bullet[:vy]
    end
    args.state.player_bullets.reject! do |bullet|
      # Despawn bullets that are outside the screen area
      bullet.x < -20 || bullet.y < -20 || bullet.x > 1300 || bullet.y > 740
    end
  end

  def move_player args
    # Get the currently held direction.
    dx, dy                 = move_directional_vector args
    # Take the weighted average of the old velocities and the desired velocities.
    # Since move_directional_vector returns values between -1 and 1,
    #   and we want to limit the speed to 7.5, we multiply dx and dy by 7.5*0.1 to get 0.75
    args.state.player[:vx] = args.state.player[:vx] * 0.9 + dx * 0.75
    args.state.player[:vy] = args.state.player[:vy] * 0.9 + dy * 0.75
    # Move the player
    args.state.player.x    += args.state.player[:vx]
    args.state.player.y    += args.state.player[:vy]
    # If the player is about to go out of bounds, put them back in bounds.
    args.state.player.x    = args.state.player.x.clamp(0, 1201)
    args.state.player.y    = args.state.player.y.clamp(0, 640)
  end


  def fire_player args
    # Reduce the firing cooldown each tick
    args.state.player[:cooldown] -= 1
    # If the player is allowed to fire
    if args.state.player[:cooldown] <= 0
      dx, dy = shoot_directional_vector args # Get the bullet velocity
      return if dx == 0 && dy == 0 # If the velocity is zero, the player doesn't want to fire. Therefore, we just return early.
      # Add a new bullet to the list of player bullets.
      args.state.player_bullets << {
          x:     args.state.player.x + 30 + 40 * dx,
          y:     args.state.player.y + 30 + 40 * dy,
          w:     20, h: 20,
          path:  'sprites/circle-white.png',
          r:     0, g: 0, b: 0,
          vx:    10 * dx + args.state.player[:vx] / 7.5, vy: 10 * dy + args.state.player[:vy] / 7.5, # Factor in a bit of the player's velocity
          kills: 0
      }
      args.state.player[:cooldown] = 30 # Reset the cooldown
    end
  end

  # Custom function for getting a directional vector just for movement using WASD
  def move_directional_vector args
    dx = 0
    dx += 1 if args.inputs.keyboard.d
    dx -= 1 if args.inputs.keyboard.a
    dy = 0
    dy += 1 if args.inputs.keyboard.w
    dy -= 1 if args.inputs.keyboard.s
    if dx != 0 && dy != 0
      dx *= 0.7071
      dy *= 0.7071
    end
    [dx, dy]
  end

  # Custom function for getting a directional vector just for shooting using the arrow keys
  def shoot_directional_vector args
    dx = 0
    dx += 1 if args.inputs.keyboard.key_down.right || args.inputs.keyboard.key_held.right
    dx -= 1 if args.inputs.keyboard.key_down.left || args.inputs.keyboard.key_held.left
    dy = 0
    dy += 1 if args.inputs.keyboard.key_down.up || args.inputs.keyboard.key_held.up
    dy -= 1 if args.inputs.keyboard.key_down.down || args.inputs.keyboard.key_held.down
    if dx != 0 && dy != 0
      dx *= 0.7071
      dy *= 0.7071
    end
    [dx, dy]
  end

```
