### 3d Cube - main.rb
```ruby
  # ./samples/99_genre_3d/01_3d_cube/app/main.rb
  STARTX             = 0.0
  STARTY             = 0.0
  ENDY               = 20.0
  ENDX               = 20.0
  SPINPOINT          = 10
  SPINDURATION       = 400
  POINTSIZE          = 8
  BOXDEPTH           = 40
  YAW                = 1
  DISTANCE           = 10

  def tick args
    args.outputs.background_color = [0, 0, 0]
    a = Math.sin(Kernel.tick_count / SPINDURATION) * Math.tan(Kernel.tick_count / SPINDURATION)
    s = Math.sin(a)
    c = Math.cos(a)
    x = STARTX
    y = STARTY
    offset_x = (1280 - (ENDX - STARTX)) / 2
    offset_y =  (360 - (ENDY - STARTY)) / 2

    srand(1)
    while y < ENDY do
      while x < ENDX do
        if (y == STARTY ||
            y == (ENDY / 0.5) * 2 ||
            y == (ENDY / 0.5) * 2 + 0.5 ||
            y == ENDY - 0.5 ||
            x == STARTX ||
            x == ENDX - 0.5)
          z = rand(BOXDEPTH)
          z *= Math.sin(a / 2)
          x -= SPINPOINT
          u = (x * c) - (z * s)
          v = (x * s) + (z * c)
          k = DISTANCE.fdiv(100) + (v / 500 * YAW)
          u = u / k
          v = y / k
          w = POINTSIZE / 10 / k
          args.outputs.sprites << { x: offset_x + u - w, y: offset_y + v - w, w: w, h: w, path: 'sprites/square-blue.png'}
          x += SPINPOINT
        end
        x += 0.5
      end
      y += 0.5
      x = STARTX
    end
  end

  $gtk.reset

```

### Wireframe - main.rb
```ruby
  # ./samples/99_genre_3d/02_wireframe/app/main.rb
  def tick args
    args.state.model   ||= Object3D.new('data/shuttle.off')
    args.state.mtx     ||= rotate3D(0, 0, 0)
    args.state.inv_mtx ||= rotate3D(0, 0, 0)
    delta_mtx          = rotate3D(args.inputs.up_down * 0.01, input_roll(args) * 0.01, args.inputs.left_right * 0.01)
    args.outputs.lines << args.state.model.edges
    args.state.model.fast_3x3_transform! args.state.inv_mtx
    args.state.inv_mtx = mtx_mul(delta_mtx.transpose, args.state.inv_mtx)
    args.state.mtx     = mtx_mul(args.state.mtx, delta_mtx)
    args.state.model.fast_3x3_transform! args.state.mtx
    args.outputs.background_color = [0, 0, 0]
    args.outputs.debug << args.gtk.framerate_diagnostics_primitives
  end

  def input_roll args
    roll = 0
    roll += 1 if args.inputs.keyboard.e
    roll -= 1 if args.inputs.keyboard.q
    roll
  end

  def rotate3D(theta_x = 0.1, theta_y = 0.1, theta_z = 0.1)
    c_x, s_x = Math.cos(theta_x), Math.sin(theta_x)
    c_y, s_y = Math.cos(theta_y), Math.sin(theta_y)
    c_z, s_z = Math.cos(theta_z), Math.sin(theta_z)
    rot_x    = [[1, 0, 0], [0, c_x, -s_x], [0, s_x, c_x]]
    rot_y    = [[c_y, 0, s_y], [0, 1, 0], [-s_y, 0, c_y]]
    rot_z    = [[c_z, -s_z, 0], [s_z, c_z, 0], [0, 0, 1]]
    mtx_mul(mtx_mul(rot_x, rot_y), rot_z)
  end

  def mtx_mul(a, b)
    is = (0...a.length)
    js = (0...b[0].length)
    ks = (0...b.length)
    is.map do |i|
      js.map do |j|
        ks.map do |k|
          a[i][k] * b[k][j]
        end.reduce(&:plus)
      end
    end
  end

  class Object3D
    attr_reader :vert_count, :face_count, :edge_count, :verts, :faces, :edges

    def initialize(path)
      @vert_count = 0
      @face_count = 0
      @edge_count = 0
      @verts      = []
      @faces      = []
      @edges      = []
      _init_from_file path
    end

    def _init_from_file path
      file_lines = $gtk.read_file(path).split("\n")
                       .reject { |line| line.start_with?('#') || line.split(' ').length == 0 } # Strip out simple comments and blank lines
                       .map { |line| line.split('#')[0] } # Strip out end of line comments
                       .map { |line| line.split(' ') } # Tokenize by splitting on whitespace
      raise "OFF file did not start with OFF." if file_lines.shift != ["OFF"] # OFF meshes are supposed to begin with "OFF" as the first line.
      raise "<NVertices NFaces NEdges> line malformed" if file_lines[0].length != 3 # The second line needs to have 3 numbers. Raise an error if it doesn't.
      @vert_count, @face_count, @edge_count = file_lines.shift&.map(&:to_i) # Update the counts
      # Only the vertex and face counts need to be accurate. Raise an error if they are inaccurate.
      raise "Incorrect number of vertices and/or faces (Parsed VFE header: #{@vert_count} #{@face_count} #{@edge_count})" if file_lines.length != @vert_count + @face_count
      # Grab all the lines describing vertices.
      vert_lines = file_lines[0, @vert_count]
      # Grab all the lines describing faces.
      face_lines = file_lines[@vert_count, @face_count]
      # Create all the vertices
      @verts = vert_lines.map_with_index { |line, id| Vertex.new(line, id) }
      # Create all the faces
      @faces = face_lines.map { |line| Face.new(line, @verts) }
      # Create all the edges
      @edges = @faces.flat_map(&:edges).uniq do |edge|
        sorted = edge.sorted
        [sorted.point_a, sorted.point_b]
      end
    end

    def fast_3x3_transform! mtx
      @verts.each { |vert| vert.fast_3x3_transform! mtx }
    end
  end

  class Face

    attr_reader :verts, :edges

    def initialize(data, verts)
      vert_count = data[0].to_i
      vert_ids   = data[1, vert_count].map(&:to_i)
      @verts     = vert_ids.map { |i| verts[i] }
      @edges     = []
      (0...vert_count).each { |i| @edges[i] = Edge.new(verts[vert_ids[i - 1]], verts[vert_ids[i]]) }
      @edges.rotate! 1
    end
  end

  class Edge
    attr_reader :point_a, :point_b

    def initialize(point_a, point_b)
      @point_a = point_a
      @point_b = point_b
    end

    def sorted
      @point_a.id < @point_b.id ? self : Edge.new(@point_b, @point_a)
    end

    def draw_override ffi
      ffi.draw_line(@point_a.render_x, @point_a.render_y, @point_b.render_x, @point_b.render_y, 255, 0, 0, 128)
      ffi.draw_line(@point_a.render_x+1, @point_a.render_y, @point_b.render_x+1, @point_b.render_y, 255, 0, 0, 128)
      ffi.draw_line(@point_a.render_x, @point_a.render_y+1, @point_b.render_x, @point_b.render_y+1, 255, 0, 0, 128)
      ffi.draw_line(@point_a.render_x+1, @point_a.render_y+1, @point_b.render_x+1, @point_b.render_y+1, 255, 0, 0, 128)
    end

    def primitive_marker
      :line
    end
  end

  class Vertex
    attr_accessor :x, :y, :z, :id

    def initialize(data, id)
      @x  = data[0].to_f
      @y  = data[1].to_f
      @z  = data[2].to_f
      @id = id
    end

    def fast_3x3_transform! mtx
      _x, _y, _z = @x, @y, @z
      @x         = mtx[0][0] * _x + mtx[0][1] * _y + mtx[0][2] * _z
      @y         = mtx[1][0] * _x + mtx[1][1] * _y + mtx[1][2] * _z
      @z         = mtx[2][0] * _x + mtx[2][1] * _y + mtx[2][2] * _z
    end

    def render_x
      @x * (10 / (5 - @y)) * 170 + 640
    end

    def render_y
      @z * (10 / (5 - @y)) * 170 + 360
    end
  end
```

### Wireframe - Data - what-is-this.txt
```ruby
  # ./samples/99_genre_3d/02_wireframe/data/what-is-this.txt
  https://en.wikipedia.org/wiki/OFF_(file_format)
```

### Yaw Pitch Roll - main.rb
```ruby
  # ./samples/99_genre_3d/03_yaw_pitch_roll/app/main.rb
  class Game
    include MatrixFunctions

    attr_gtk

    def tick
      defaults
      render
      input
    end

    def player_ship
      [
        # engine back
        (vec4  -1,  -1,  1,  0),
        (vec4  -1,   1,  1,  0),

        (vec4  -1,   1,  1,  0),
        (vec4   1,   1,  1,  0),

        (vec4   1,   1,  1,  0),
        (vec4   1,  -1,  1,  0),

        (vec4   1,  -1,  1,  0),
        (vec4  -1,  -1,  1,  0),

        # engine front
        (vec4  -1,  -1,  -1,  0),
        (vec4  -1,   1,  -1,  0),

        (vec4  -1,   1,  -1,  0),
        (vec4   1,   1,  -1,  0),

        (vec4   1,   1,  -1,  0),
        (vec4   1,  -1,  -1,  0),

        (vec4   1,  -1,  -1,  0),
        (vec4  -1,  -1,  -1,  0),

        # engine left
        (vec4  -1,   -1,  -1,  0),
        (vec4  -1,   -1,   1,  0),

        (vec4  -1,   -1,   1,  0),
        (vec4  -1,    1,   1,  0),

        (vec4  -1,    1,   1,  0),
        (vec4  -1,    1,  -1,  0),

        (vec4  -1,    1,  -1,  0),
        (vec4  -1,   -1,  -1,  0),

        # engine right
        (vec4   1,   -1,  -1,  0),
        (vec4   1,   -1,   1,  0),

        (vec4   1,   -1,   1,  0),
        (vec4   1,    1,   1,  0),

        (vec4   1,    1,   1,  0),
        (vec4   1,    1,  -1,  0),

        (vec4   1,    1,  -1,  0),
        (vec4   1,   -1,  -1,  0),

        # top front of engine to front of ship
        (vec4   1,    1,  1,  0),
        (vec4   0,   -1,  9,  0),

        (vec4   0,   -1,  9,  0),
        (vec4  -1,    1,  1,  0),

        # bottom front of engine
        (vec4   1,   -1,  1,  0),
        (vec4   0,   -1,  9,  0),

        (vec4  -1,   -1,  1,  0),
        (vec4   0,   -1,  9,  0),

        # right wing
        # front of wing
        (vec4  1,  0.10,   1,  0),
        (vec4  9,  0.10,  -1,  0),

        (vec4   9,  0.10,  -1,  0),
        (vec4  10,  0.10,  -2,  0),

        # back of wing
        (vec4  1,  0.10,  -1,  0),
        (vec4  9,  0.10,  -1,  0),

        (vec4  10,  0.10,  -2,  0),
        (vec4   8,  0.10,  -1,  0),

        # front of wing
        (vec4  1,  -0.10,   1,  0),
        (vec4  9,  -0.10,  -1,  0),

        (vec4   9,  -0.10,  -1,  0),
        (vec4  10,  -0.10,  -2,  0),

        # back of wing
        (vec4  1,  -0.10,  -1,  0),
        (vec4  9,  -0.10,  -1,  0),

        (vec4  10,  -0.10,  -2,  0),
        (vec4   8,  -0.10,  -1,  0),

        # left wing
        # front of wing
        (vec4  -1,  0.10,   1,  0),
        (vec4  -9,  0.10,  -1,  0),

        (vec4  -9,  0.10,  -1,  0),
        (vec4  -10,  0.10,  -2,  0),

        # back of wing
        (vec4  -1,  0.10,  -1,  0),
        (vec4  -9,  0.10,  -1,  0),

        (vec4  -10,  0.10,  -2,  0),
        (vec4  -8,  0.10,  -1,  0),

        # front of wing
        (vec4  -1,  -0.10,   1,  0),
        (vec4  -9,  -0.10,  -1,  0),

        (vec4  -9,  -0.10,  -1,  0),
        (vec4  -10,  -0.10,  -2,  0),

        # back of wing
        (vec4  -1,  -0.10,  -1,  0),
        (vec4  -9,  -0.10,  -1,  0),
        (vec4  -10,  -0.10,  -2,  0),
        (vec4   -8,  -0.10,  -1,  0),

        # left fin
        # top
        (vec4  -1,  0.10,  1,  0),
        (vec4  -1,  3,  -3,  0),

        (vec4  -1,  0.10,  -1,  0),
        (vec4  -1,  3,  -3,  0),

        (vec4  -1.1,  0.10,  1,  0),
        (vec4  -1.1,  3,  -3,  0),

        (vec4  -1.1,  0.10,  -1,  0),
        (vec4  -1.1,  3,  -3,  0),

        # bottom
        (vec4  -1,  -0.10,  1,  0),
        (vec4  -1,  -2,  -2,  0),

        (vec4  -1,  -0.10,  -1,  0),
        (vec4  -1,  -2,  -2,  0),

        (vec4  -1.1,  -0.10,  1,  0),
        (vec4  -1.1,  -2,  -2,  0),

        (vec4  -1.1,  -0.10,  -1,  0),
        (vec4  -1.1,  -2,  -2,  0),

        # right fin
        (vec4   1,  0.10,  1,  0),
        (vec4   1,  3,  -3,  0),

        (vec4   1,  0.10,  -1,  0),
        (vec4   1,  3,  -3,  0),

        (vec4   1.1,  0.10,  1,  0),
        (vec4   1.1,  3,  -3,  0),

        (vec4   1.1,  0.10,  -1,  0),
        (vec4   1.1,  3,  -3,  0),

        # bottom
        (vec4   1,  -0.10,  1,  0),
        (vec4   1,  -2,  -2,  0),

        (vec4   1,  -0.10,  -1,  0),
        (vec4   1,  -2,  -2,  0),

        (vec4   1.1,  -0.10,  1,  0),
        (vec4   1.1,  -2,  -2,  0),

        (vec4   1.1,  -0.10,  -1,  0),
        (vec4   1.1,  -2,  -2,  0),
      ]
    end

    def defaults
      state.points ||= player_ship
      state.shifted_points ||= state.points.map { |point| point }

      state.scale   ||= 1
      state.angle_x ||= 0
      state.angle_y ||= 0
      state.angle_z ||= 0
    end

    def angle_z_matrix degrees
      cos_t = Math.cos degrees.to_radians
      sin_t = Math.sin degrees.to_radians
      (mat4 cos_t, -sin_t, 0, 0,
            sin_t,  cos_t, 0, 0,
            0,      0,     1, 0,
            0,      0,     0, 1)
    end

    def angle_y_matrix degrees
      cos_t = Math.cos degrees.to_radians
      sin_t = Math.sin degrees.to_radians
      (mat4  cos_t,  0, sin_t, 0,
             0,      1, 0,     0,
             -sin_t, 0, cos_t, 0,
             0,      0, 0,     1)
    end

    def angle_x_matrix degrees
      cos_t = Math.cos degrees.to_radians
      sin_t = Math.sin degrees.to_radians
      (mat4  1,     0,      0, 0,
             0, cos_t, -sin_t, 0,
             0, sin_t,  cos_t, 0,
             0,     0,      0, 1)
    end

    def scale_matrix factor
      (mat4 factor,      0,      0, 0,
            0,      factor,      0, 0,
            0,           0, factor, 0,
            0,           0,      0, 1)
    end

    def input
      if (inputs.keyboard.shift && inputs.keyboard.p)
        state.scale -= 0.1
      elsif  inputs.keyboard.p
        state.scale += 0.1
      end

      if inputs.mouse.wheel
        state.scale += inputs.mouse.wheel.y
      end

      state.scale = state.scale.clamp(0.1, 1000)

      if (inputs.keyboard.shift && inputs.keyboard.y) || inputs.keyboard.right
        state.angle_y += 1
      elsif (inputs.keyboard.y) || inputs.keyboard.left
        state.angle_y -= 1
      end

      if (inputs.keyboard.shift && inputs.keyboard.x) || inputs.keyboard.down
        state.angle_x -= 1
      elsif (inputs.keyboard.x || inputs.keyboard.up)
        state.angle_x += 1
      end

      if inputs.keyboard.shift && inputs.keyboard.z
        state.angle_z += 1
      elsif inputs.keyboard.z
        state.angle_z -= 1
      end

      if inputs.keyboard.zero
        state.angle_x = 0
        state.angle_y = 0
        state.angle_z = 0
      end

      angle_x = state.angle_x
      angle_y = state.angle_y
      angle_z = state.angle_z
      scale   = state.scale

      s_matrix = scale_matrix state.scale
      x_matrix = angle_z_matrix angle_z
      y_matrix = angle_y_matrix angle_y
      z_matrix = angle_x_matrix angle_x

      state.shifted_points = state.points.map do |point|
        (mul point, y_matrix, x_matrix, z_matrix, s_matrix).merge(original: point)
      end
    end

    def thick_line line
      [
        line.merge(y: line.y - 1, y2: line.y2 - 1, r: 0, g: 0, b: 0),
        line.merge(x: line.x - 1, x2: line.x2 - 1, r: 0, g: 0, b: 0),
        line.merge(x: line.x - 0, x2: line.x2 - 0, r: 0, g: 0, b: 0),
        line.merge(y: line.y + 1, y2: line.y2 + 1, r: 0, g: 0, b: 0),
        line.merge(x: line.x + 1, x2: line.x2 + 1, r: 0, g: 0, b: 0)
      ]
    end

    def render
      outputs.lines << state.shifted_points.each_slice(2).map do |(p1, p2)|
        perc = 0
        thick_line({ x:  p1.x.*(10) + 640, y:  p1.y.*(10) + 320,
                     x2: p2.x.*(10) + 640, y2: p2.y.*(10) + 320,
                     r: 255 * perc,
                     g: 255 * perc,
                     b: 255 * perc })
      end

      outputs.labels << [ 10, 700, "angle_x: #{state.angle_x.to_sf}", 0]
      outputs.labels << [ 10, 670, "x, shift+x", 0]

      outputs.labels << [210, 700, "angle_y: #{state.angle_y.to_sf}", 0]
      outputs.labels << [210, 670, "y, shift+y", 0]

      outputs.labels << [410, 700, "angle_z: #{state.angle_z.to_sf}", 0]
      outputs.labels << [410, 670, "z, shift+z", 0]

      outputs.labels << [610, 700, "scale: #{state.scale.to_sf}", 0]
      outputs.labels << [610, 670, "p, shift+p", 0]
    end
  end

  $game = Game.new

  def tick args
    $game.args = args
    $game.tick
  end

  def set_angles x, y, z
    $game.state.angle_x = x
    $game.state.angle_y = y
    $game.state.angle_z = z
  end

  $gtk.reset

```

### Ray Caster - main.rb
```ruby
  # ./samples/99_genre_3d/04_ray_caster/app/main.rb
  # https://github.com/BrennerLittle/DragonRubyRaycast
  # https://github.com/3DSage/OpenGL-Raycaster_v1
  # https://www.youtube.com/watch?v=gYRrGTC7GtA&ab_channel=3DSage

  def tick args
    defaults args
    calc args
    render args
    args.outputs.sprites << { x: 0, y: 0, w: 1280 * 2.66, h: 720 * 2.25, path: :screen }
    args.outputs.labels  << { x: 30, y: 30.from_top, text: "FPS: #{args.gtk.current_framerate.to_sf}" }
  end

  def defaults args
    args.state.stage ||= {
      w: 8,
      h: 8,
      sz: 64,
      layout: [
        1, 1, 1, 1, 1, 1, 1, 1,
        1, 0, 1, 0, 0, 0, 0, 1,
        1, 0, 1, 0, 0, 1, 0, 1,
        1, 0, 1, 0, 0, 0, 0, 1,
        1, 0, 0, 0, 0, 0, 0, 1,
        1, 0, 0, 0, 0, 1, 0, 1,
        1, 0, 0, 0, 0, 0, 0, 1,
        1, 1, 1, 1, 1, 1, 1, 1,
      ]
    }

    args.state.player ||= {
      x: 250,
      y: 250,
      dx: 1,
      dy: 0,
      angle: 0
    }
  end

  def calc args
    xo = 0

    if args.state.player.dx < 0
      xo = -20
    else
      xo = 20
    end

    yo = 0

    if args.state.player.dy < 0
      yo = -20
    else
      yo = 20
    end

    ipx = args.state.player.x.idiv 64.0
    ipx_add_xo = (args.state.player.x + xo).idiv 64.0
    ipx_sub_xo = (args.state.player.x - xo).idiv 64.0

    ipy = args.state.player.y.idiv 64.0
    ipy_add_yo = (args.state.player.y + yo).idiv 64.0
    ipy_sub_yo = (args.state.player.y - yo).idiv 64.0

    if args.inputs.keyboard.right
      args.state.player.angle -= 5
      args.state.player.angle = args.state.player.angle % 360
      args.state.player.dx = args.state.player.angle.cos_d
      args.state.player.dy = -args.state.player.angle.sin_d
    end

    if args.inputs.keyboard.left
      args.state.player.angle += 5
      args.state.player.angle = args.state.player.angle % 360
      args.state.player.dx = args.state.player.angle.cos_d
      args.state.player.dy = -args.state.player.angle.sin_d
    end

    if args.inputs.keyboard.up
      if args.state.stage.layout[ipy * args.state.stage.w + ipx_add_xo] == 0
        args.state.player.x += args.state.player.dx * 5
      end

      if args.state.stage.layout[ipy_add_yo * args.state.stage.w + ipx] == 0
        args.state.player.y += args.state.player.dy * 5
      end
    end

    if args.inputs.keyboard.down
      if args.state.stage.layout[ipy * args.state.stage.w + ipx_sub_xo] == 0
        args.state.player.x -= args.state.player.dx * 5
      end

      if args.state.stage.layout[ipy_sub_yo * args.state.stage.w + ipx] == 0
        args.state.player.y -= args.state.player.dy * 5
      end
    end
  end

  def render args
    args.outputs[:screen].transient!
    args.outputs[:screen].sprites << { x: 0,
                                       y: 160,
                                       w: 750,
                                       h: 160,
                                       path: :pixel,
                                       r: 89,
                                       g: 125,
                                       b: 206 }

    args.outputs[:screen].sprites << { x: 0,
                                       y: 0,
                                       w: 750,
                                       h: 160,
                                       path: :pixel,
                                       r: 117,
                                       g: 113,
                                       b: 97 }


    ra = (args.state.player.angle + 30) % 360

    60.times do |r|
      dof = 0
      side = 0
      dis_v = 100000
      ra_tan = ra.tan_d

      if ra.cos_d > 0.001
        rx = ((args.state.player.x >> 6) << 6) + 64
        ry = (args.state.player.x - rx) * ra_tan + args.state.player.y;
        xo = 64
        yo = -xo * ra_tan
      elsif ra.cos_d < -0.001
        rx = ((args.state.player.x >> 6) << 6) - 0.0001
        ry = (args.state.player.x - rx) * ra_tan + args.state.player.y
        xo = -64
        yo = -xo * ra_tan
      else
        rx = args.state.player.x
        ry = args.state.player.y
        dof = 8
      end

      while dof < 8
        mx = rx >> 6
        mx = mx.to_i
        my = ry >> 6
        my = my.to_i
        mp = my * args.state.stage.w + mx
        if mp > 0 && mp < args.state.stage.w * args.state.stage.h && args.state.stage.layout[mp] == 1
          dof = 8
          dis_v = ra.cos_d * (rx - args.state.player.x) - ra.sin_d * (ry - args.state.player.y)
        else
          rx += xo
          ry += yo
          dof += 1
        end
      end

      vx = rx
      vy = ry

      dof = 0
      dis_h = 100000
      ra_tan = 1.0 / ra_tan

      if ra.sin_d > 0.001
        ry = ((args.state.player.y >> 6) << 6) - 0.0001;
        rx = (args.state.player.y - ry) * ra_tan + args.state.player.x;
        yo = -64;
        xo = -yo * ra_tan;
      elsif ra.sin_d < -0.001
        ry = ((args.state.player.y >> 6) << 6) + 64;
        rx = (args.state.player.y - ry) * ra_tan + args.state.player.x;
        yo = 64;
        xo = -yo * ra_tan;
      else
        rx = args.state.player.x
        ry = args.state.player.y
        dof = 8
      end

      while dof < 8
        mx = (rx) >> 6
        my = (ry) >> 6
        mp = my * args.state.stage.w + mx
        if mp > 0 && mp < args.state.stage.w * args.state.stage.h && args.state.stage.layout[mp] == 1
          dof = 8
          dis_h = ra.cos_d * (rx - args.state.player.x) - ra.sin_d * (ry - args.state.player.y)
        else
          rx += xo
          ry += yo
          dof += 1
        end
      end

      color = { r: 52, g: 101, b: 36 }

      if dis_v < dis_h
        rx = vx
        ry = vy
        dis_h = dis_v
        color = { r: 109, g: 170, b: 44 }
      end

      ca = (args.state.player.angle - ra) % 360
      dis_h = dis_h * ca.cos_d
      line_h = (args.state.stage.sz * 320) / (dis_h)
      line_h = 320 if line_h > 320

      line_off = 160 - (line_h >> 1)

      args.outputs[:screen].sprites << {
        x: r * 8,
        y: line_off,
        w: 8,
        h: line_h,
        path: :pixel,
        **color
      }

      ra = (ra - 1) % 360
    end
  end

```

### Ray Caster Advanced - main.rb
```ruby
  # ./samples/99_genre_3d/04_ray_caster_advanced/app/main.rb
  =begin

  This sample is a more advanced example of raycasting that extends the previous 04_ray_caster sample.
  Refer to the prior sample to to understand the fundamental raycasting algorithm.
  This sample adds:
   * higher resolution of raycasting
   * Wall textures
   * Simple "drop off" lighting
   * Weapon firing
   * Drawing of sprites within the level.

  # Contributors outside of DragonRuby who also hold Copyright:
  # - James Stocks: https://github.com/james-stocks

  =end

  # https://github.com/BrennerLittle/DragonRubyRaycast
  # https://github.com/3DSage/OpenGL-Raycaster_v1
  # https://www.youtube.com/watch?v=gYRrGTC7GtA&ab_channel=3DSage

  def tick args
    defaults args
    update_player args
    update_missiles args
    update_enemies args
    render args
    args.outputs.sprites << { x: 0, y: 0, w: 1280 * 1.5, h: 720 * 1.2, path: :screen }
    args.outputs.labels  << { x: 30, y: 30.from_top, text: "FPS: #{args.gtk.current_framerate.to_sf} X: #{args.state.player.x} Y: #{args.state.player.y}" }
  end

  def defaults args
    args.state.stage ||= {
      w: 8,       # Width of the tile map
      h: 8,       # Height of the tile map
      sz: 64,     # To define a 3D space, define a size (in arbitrary units) we consider one map tile to be.
      layout: [
        1, 1, 1, 1, 2, 1, 1, 1,
        1, 0, 1, 0, 0, 0, 0, 1,
        1, 0, 1, 0, 0, 3, 0, 1,
        1, 0, 1, 0, 0, 0, 0, 2,
        1, 0, 0, 0, 0, 0, 0, 1,
        1, 0, 0, 0, 0, 3, 0, 1,
        1, 0, 0, 0, 0, 0, 0, 1,
        1, 1, 1, 2, 1, 1, 1, 1,
      ]
    }

    args.state.player ||= {
      x: 250,
      y: 250,
      dx: 1,
      dy: 0,
      angle: 0,
      fire_cooldown_wait: 0,
      fire_cooldown_duration: 15
    }

    # Add an initial alien enemy.
    # The :bright property indicates that this entity doesn't produce light and should appear dimmer over distance.
    args.state.enemies ||= [{ x: 280, y: 280, type: :alien, bright: false, expired: false }]
    args.state.missiles ||= []
    args.state.splashes ||= []
  end

  # Update the player's input and movement
  def update_player args

    player = args.state.player
    player.fire_cooldown_wait -= 1 if player.fire_cooldown_wait > 0

    xo = 0

    if player.dx < 0
      xo = -20
    else
      xo = 20
    end

    yo = 0

    if player.dy < 0
      yo = -20
    else
      yo = 20
    end

    ipx = player.x.idiv 64.0
    ipx_add_xo = (player.x + xo).idiv 64.0
    ipx_sub_xo = (player.x - xo).idiv 64.0

    ipy = player.y.idiv 64.0
    ipy_add_yo = (player.y + yo).idiv 64.0
    ipy_sub_yo = (player.y - yo).idiv 64.0

    if args.inputs.keyboard.right
      player.angle -= 5
      player.angle = player.angle % 360
      player.dx = player.angle.cos_d
      player.dy = -player.angle.sin_d
    end

    if args.inputs.keyboard.left
      player.angle += 5
      player.angle = player.angle % 360
      player.dx = player.angle.cos_d
      player.dy = -player.angle.sin_d
    end

    if args.inputs.keyboard.up
      if args.state.stage.layout[ipy * args.state.stage.w + ipx_add_xo] == 0
        player.x += player.dx * 5
      end

      if args.state.stage.layout[ipy_add_yo * args.state.stage.w + ipx] == 0
        player.y += player.dy * 5
      end
    end

    if args.inputs.keyboard.down
      if args.state.stage.layout[ipy * args.state.stage.w + ipx_sub_xo] == 0
        player.x -= player.dx * 5
      end

      if args.state.stage.layout[ipy_sub_yo * args.state.stage.w + ipx] == 0
        player.y -= player.dy * 5
      end
    end

    if args.inputs.keyboard.key_down.space && player.fire_cooldown_wait == 0
      m = { x: player.x, y: player.y, angle: player.angle, speed: 6, type: :missile, bright: true, expired: false }
      # Immediately move the missile forward a frame so it spawns ahead of the player
      m.x += m.angle.cos_d * m.speed
      m.y -= m.angle.sin_d * m.speed
      args.state.missiles << m
      player.fire_cooldown_wait = player.fire_cooldown_duration
    end
  end

  def update_missiles args
    # Remove expired missiles by mapping expired missiles to `nil` and then calling `compact!` to
    # remove nil entries.
    args.state.missiles.map! { |m| m.expired ? nil : m }
    args.state.missiles.compact!

    args.state.missiles.each do |m|
      new_x = m.x + m.angle.cos_d * m.speed
      new_y = m.y - m.angle.sin_d * m.speed
      # Hit enemies
      args.state.enemies.each do |e|
          if (new_x - e.x).abs < 16 && (new_y - e.y).abs < 16
              e.expired = true
              m.expired = true
              args.state.splashes << { x: m.x, y: m.y, ttl: 5, type: :splash, bright: true }
              next
          end
      end
      # Hit walls
      if(args.state.stage.layout[(new_y / 64).to_i * args.state.stage.w + (new_x / 64).to_i] != 0)
        m.expired = true
        args.state.splashes << { x: m.x, y: m.y, ttl: 5, type: :splash, bright: true }
      else
        m.x = new_x
        m.y = new_y
      end
    end
    args.state.splashes.map! { |s| s.ttl <= 0 ? nil : s }
    args.state.splashes.compact!
    args.state.splashes.each do |s|
      s.ttl -= 1
    end
  end

  def update_enemies args
      args.state.enemies.map! { |e| e.expired ?  nil : e }
      args.state.enemies.compact!
  end

  def render args
    # Render the sky
    args.outputs[:screen].transient!
    args.outputs[:screen].sprites << { x: 0,
                                       y: 320,
                                       w: 960,
                                       h: 320,
                                       path: :pixel,
                                       r: 89,
                                       g: 125,
                                       b: 206 }

    # Render the floor
    args.outputs[:screen].sprites << { x: 0,
                                       y: 0,
                                       w: 960,
                                       h: 320,
                                       path: :pixel,
                                       r: 117,
                                       g: 113,
                                       b: 97 }

    ra = (args.state.player.angle + 30) % 360

    # Collect sprites for the raycast view into an array - these will all be rendered with a single draw call.
    # This gives a substantial performance improvement over the previous sample where there was one draw call
    # per sprite.
    sprites_to_draw = []

    # Save distances of each wall hit. This is used subsequently when drawing sprites.
    depths = []

    # Cast 120 rays across 60 degress - we'll consider the next 0.5 degrees each ray
    120.times do |r|

      # The next ~120 lines are largely the same as the previous sample. The changes are:
      # - Increment by 0.5 degrees instead of 1 degree for the next ray.
      # - When a wall hit is found, the distance is stored in the `depths` array.
      #   - `depths` is used later when rendering enemies and bullet.
      # - We draw a slice of a wall texture instead of a solid color.
      # - The wall strip for the array hit is appended to `sprites_to_draw` instead of being drawn immediately.
      dof = 0
      max_dof = 8
      dis_v = 100000

      ra_tan = Math.tan(ra * Math::PI / 180)

      if ra.cos_d > 0.001
        rx = ((args.state.player.x >> 6) << 6) + 64

        ry = (args.state.player.x - rx) * ra_tan + args.state.player.y;
        xo = 64
        yo = -xo * ra_tan
      elsif ra.cos_d < -0.001
        rx = ((args.state.player.x >> 6) << 6) - 0.0001
        ry = (args.state.player.x - rx) * ra_tan + args.state.player.y
        xo = -64
        yo = -xo * ra_tan
      else
        rx = args.state.player.x
        ry = args.state.player.y
        dof = max_dof
      end

      while dof < max_dof
        mx = rx >> 6
        mx = mx.to_i
        my = ry >> 6
        my = my.to_i
        mp = my * args.state.stage.w + mx
        if mp > 0 && mp < args.state.stage.w * args.state.stage.h && args.state.stage.layout[mp] > 0
          dof = max_dof
          dis_v = ra.cos_d * (rx - args.state.player.x) - ra.sin_d * (ry - args.state.player.y)
          wall_texture_v = args.state.stage.layout[mp]
        else
          rx += xo
          ry += yo
          dof += 1
        end
      end

      vx = rx
      vy = ry

      dof = 0
      dis_h = 100000
      ra_tan = 1.0 / ra_tan

      if ra.sin_d > 0.001
        ry = ((args.state.player.y >> 6) << 6) - 0.0001;
        rx = (args.state.player.y - ry) * ra_tan + args.state.player.x;
        yo = -64;
        xo = -yo * ra_tan;
      elsif ra.sin_d < -0.001
        ry = ((args.state.player.y >> 6) << 6) + 64;
        rx = (args.state.player.y - ry) * ra_tan + args.state.player.x;
        yo = 64;
        xo = -yo * ra_tan;
      else
        rx = args.state.player.x
        ry = args.state.player.y
        dof = 8
      end

      while dof < 8
        mx = (rx) >> 6
        my = (ry) >> 6
        mp = my * args.state.stage.w + mx
        if mp > 0 && mp < args.state.stage.w * args.state.stage.h && args.state.stage.layout[mp] > 0
          dof = 8
          dis_h = ra.cos_d * (rx - args.state.player.x) - ra.sin_d * (ry - args.state.player.y)
          wall_texture = args.state.stage.layout[mp]
        else
          rx += xo
          ry += yo
          dof += 1
        end
      end

      dist = dis_h
      if dis_v < dis_h
        rx = vx
        ry = vy
        dist = dis_v
        wall_texture = wall_texture_v
      end
      # Store the distance for a wall hit at this angle
      depths << dist

      # Adjust for fish-eye across FOV
      ca = (args.state.player.angle - ra) % 360
      dist = dist * ca.cos_d
      # Determine the render height for the strip proportional to the display height
      line_h = (args.state.stage.sz * 640) / (dist)

      line_off = 320 - (line_h >> 1)

      # Tint the wall strip - the further away it is, the darker.
      tint = 1.0 - (dist / 500)

      # Wall texturing - Determine the section of source texture to use
      tx = dis_v > dis_h ? (rx.to_i % 64).to_i : (ry.to_i % 64).to_i
      # If player is looking backwards towards a tile then flip the side of the texture to sample.
      # The sample wall textures have a diagonal stripe pattern - if you comment out these 2 lines,
      # you will see what goes wrong with texturing.
      tx = 63 - tx if (ra > 180 && dis_v > dis_h)
      tx = 63 - tx if (ra > 90 && ra < 270 && dis_v < dis_h)

      sprites_to_draw << {
        x: r * 8,
        y: line_off,
        w: 8,
        h: line_h,
        path: "sprites/wall_#{wall_texture}.png",
        source_x: tx,
        source_w: 1,
        r: 255 * tint,
        g: 255 * tint,
        b: 255 * tint
      }

      # Increment the raycast angle for the next iteration of this loop
      ra = (ra - 0.5) % 360
    end

    # Render sprites
    # Use common render code for enemies, missiles and explosion splashes.
    # This works because they are all hashes with :x, :y, and :type fields.
    things_to_draw = []
    things_to_draw.push(*args.state.enemies)
    things_to_draw.push(*args.state.missiles)
    things_to_draw.push(*args.state.splashes)

    # Do a first-pass on the things to draw, calculate distance from player and then
    # sort so more-distant things are drawn first.
    things_to_draw.each do |t|
      t[:dist] = args.geometry.distance([args.state.player[:x],args.state.player[:y]],[t[:x],t[:y]]).abs
    end
    things_to_draw = things_to_draw.sort_by { |t| t[:dist] }.reverse

    # Now draw everything, most distant entities first.
    things_to_draw.each do |t|
        distance_to_thing = t[:dist]
        # The crux of drawing a sprite in a raycast view is to:
        #   1. rotate the enemy around the player's position and viewing angle to get a position relative to the view.
        #   2. Translate that position from "3D space" to screen pixels.
        # The next 6 lines get the entitiy's position relative to the player position and angle:
        tx = t[:x] - args.state.player.x
        ty = t[:y] - args.state.player.y
        cs = Math.cos(args.state.player.angle * Math::PI / 180)
        sn = Math.sin(args.state.player.angle * Math::PI / 180)
        dx = ty * cs + tx * sn
        dy = tx * cs - ty * sn

        # The next 5 lines determine the screen x and y of (the center of) the entity, and a scale
        next if dy == 0 # Avoid invalid Infinity/NaN calculations if the projected Y is 0
        ody = dy
        dx = dx*640/(dy) + 480
        dy = 32/dy + 192
        scale = 64*360/(ody / 2)

        tint = t[:bright] ? 1.0 : 1.0 - (distance_to_thing / 500)

        # Now we know the x and y on-screen for the entity, and its scale, we can draw it.
        # Simply drawing the sprite on the screen doesn't work in a raycast view because the entity might be partly obscured by a wall.
        # Instead we draw the entity in vertical strips, skipping strips if a wall is closer to the player on that strip of the screen.

        # Since dx stores the center x of the enemy on-screen, we start half the scale of the enemy to the left of dx
        x = dx - scale/2
        next if (x > 960 or (dx + scale/2 <= 0)) # Skip rendering if the X position is entirely off-screen
        strip = 0                    # Keep track of the number of strips we've drawn
        strip_width = scale / 64     # Draw the sprite in 64 strips
        sample_width = 1             # For each strip we will sample 1/64 of sprite image, here we assume 64x64 sprites

        until x >= dx + scale/2 do
            if x > 0 && x < 960
                # Here we get the distance to the wall for this strip on the screen
                wall_depth = depths[(x.to_i/8)]
                if ((distance_to_thing < wall_depth))
                    sprites_to_draw << {
                        x: x,
                        y: dy + 120 - scale * 0.6,
                        w: strip_width,
                        h: scale,
                        path: "sprites/#{t[:type]}.png",
                        source_x: strip * sample_width,
                        source_w: sample_width,
                        r: 255 * tint,
                        g: 255 * tint,
                        b: 255 * tint
                    }
                end
            end
            x += strip_width
            strip += 1
        end
    end

    # Draw all the sprites we collected in the array to the render target
    args.outputs[:screen].sprites << sprites_to_draw
  end

```
