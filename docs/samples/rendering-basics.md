### Labels - main.rb
```ruby
  # ./samples/01_rendering_basics/01_labels/app/main.rb
  =begin

  APIs listing that haven't been encountered in a previous sample apps:

  - args.outputs.labels: An array. Values in this array generate labels the screen.

  =end

  # Labels are used to represent text elements in DragonRuby

  # An example of creating a label is:
  # args.outputs.labels << [320, 640, "Example", 3, 1, 255, 0, 0, 200, manaspace.ttf]

  # The code above does the following:
  # 1. GET the place where labels go: args.outputs.labels
  # 2. Request a new LABEL be ADDED: <<
  # 3. The DEFINITION of a LABEL is the ARRAY:
  #     [320, 640, "Example
  #     [ X ,  Y,    TEXT]
  # 4. It's recommended to use hashes so that you're not reliant on positional values:
  #    { x: 320,
  #      y: 640,
  #      text: "Text",
  #      font: "fonts/font.ttf",
  #      anchor_x: 0.5, # or alignment_enum: 0, 1, or 2
  #      anchor_y: 0.5, # or vertical_alignment_enum: 0, 1, or 2
  #      r: 0,
  #      g: 0,
  #      b: 0,
  #      a: 255,
  #      size_px: 20,   # or size_enum: -10 to 10 (0 means "ledgible on small devices" ie: 20px)
  #      blendmode_enum: 1 }


  # The tick method is called by DragonRuby every frame
  # args contains all the information regarding the game.
  def tick args
    # render the current frame to the screen using a simple array
    # this is useful for quick and dirty output and is recommended to use
    # a Hash to render long term.
    args.outputs.labels << [640, 650, "frame: #{Kernel.tick_count}"]

    # render the current frame to the screen centered vertically and horizontally at 640, 620
    args.outputs.labels << { x: 640, y: 620, anchor_x: 0.5, anchor_y: 0.5, text: "frame: #{Kernel.tick_count}" }

    # Here are some examples of simple labels, with the minimum number of parameters
    # Note that the default values for the other parameters are 0, except for Alpha which is 255 and Font Style which is the default font
    args.outputs.labels << { x: 5,          y: 720 - 5, text: "This is a label located at the top left." }
    args.outputs.labels << { x: 5,          y:      30, text: "This is a label located at the bottom left." }
    args.outputs.labels << { x: 1280 - 420, y: 720 - 5, text: "This is a label located at the top right." }
    args.outputs.labels << { x: 1280 - 440, y: 30,      text: "This is a label located at the bottom right." }

    # Demonstration of the Size Enum Parameter

    # size_enum of -2 is equivalent to using size_px: 18
    args.outputs.labels << { x: 175 + 150, y: 635 - 50, text: "Smaller label.",  size_enum: -2 }
    args.outputs.labels << { x: 175 + 150, y: 620 - 50, text: "Smaller label.",  size_px: 18 }

    # size_enum of -1 is equivalent to using size_px: 20
    args.outputs.labels << { x: 175 + 150, y: 595 - 50, text: "Small label.",    size_enum: -1 }
    args.outputs.labels << { x: 175 + 150, y: 580 - 50, text: "Small label.",    size_px: 20 }

    # size_enum of  0 is equivalent to using size_px: 22
    args.outputs.labels << { x: 175 + 150, y: 550 - 50, text: "Medium label.",   size_enum:  0 }

    # size_enum of  0 is equivalent to using size_px: 24
    args.outputs.labels << { x: 175 + 150, y: 520 - 50, text: "Large label.",    size_enum:  1 }

    # size_enum of  0 is equivalent to using size_px: 26
    args.outputs.labels << { x: 175 + 150, y: 490 - 50, text: "Larger label.",   size_enum:  2 }

    # Demonstration of the Align Parameter
    args.outputs.lines  << { x: 175 + 150, y: 0, h: 720 }

    # alignment_enum: 0 is equivalent to anchor_x: 0
    # vertical_alignment_enum: 1 is equivalent to anchor_y: 0.5
    args.outputs.labels << { x: 175 + 150, y: 360 - 50, text: "Left aligned.",   alignment_enum: 0, vertical_alignment_enum: 1 }
    args.outputs.labels << { x: 175 + 150, y: 342 - 50, text: "Left aligned.",   anchor_x: 0, anchor_y: 0.5 }

    # alignment_enum: 1 is equivalent to anchor_x: 0.5
    args.outputs.labels << { x: 175 + 150, y: 325 - 50, text: "Center aligned.", alignment_enum: 1, vertical_alignment_enum: 1  }

    # alignment_enum: 2 is equivalent to anchor_x: 1
    args.outputs.labels << { x: 175 + 150, y: 305 - 50, text: "Right aligned.",  alignment_enum: 2 }

    # Demonstration of the RGBA parameters
    args.outputs.labels << { x: 600  + 150, y: 590 - 50, text: "Red Label.",   r: 255, g:   0, b:   0 }
    args.outputs.labels << { x: 600  + 150, y: 570 - 50, text: "Green Label.", r:   0, g: 255, b:   0 }
    args.outputs.labels << { x: 600  + 150, y: 550 - 50, text: "Blue Label.",  r:   0, g:   0, b: 255 }
    args.outputs.labels << { x: 600  + 150, y: 530 - 50, text: "Faded Label.", r:   0, g:   0, b:   0, a: 128 }

    # providing a custom font
    args.outputs.labels << { x: 690 + 150,
                             y: 330 - 50,
                             text: "Custom font (Hash)",
                             size_enum: 0,                 # equivalent to size_px:  22
                             alignment_enum: 1,            # equivalent to anchor_x: 0.5
                             vertical_alignment_enum: 2,   # equivalent to anchor_y: 1
                             r: 125,
                             g: 0,
                             b: 200,
                             a: 255,
                             font: "manaspc.ttf" }

    # Primitives can hold anything, and can be given a label in the following forms
    args.outputs.primitives << { x: 690 + 150,
                                 y: 330 - 80,
                                 text: "Custom font (.primitives Hash)",
                                 size_enum: 0,
                                 alignment_enum: 1,
                                 r: 125,
                                 g: 0,
                                 b: 200,
                                 a: 255,
                                 font: "manaspc.ttf" }

    args.outputs.labels << { x: 640,
                             y: 100,
                             anchor_x: 0.5,
                             anchor_y: 0.5,
                             text: "Ніколи не здам тебе. Ніколи не підведу тебе. Ніколи не буду бігати навколо і залишати тебе." }
  end

```

### Labels - Logs - console_history.txt
```ruby
  # ./samples/01_rendering_basics/01_labels/logs/console_history.txt
  $gtk.reset seed: 1716763913
  $gtk.reset seed: 1716763903
  $gtk.reset seed: 1716763811
  $gtk.reset seed: 1716763784
  $gtk.reset seed: 1716763767
  $gtk.reset seed: 1716763734
  $gtk.reset seed: 1716761293
  $gtk.reset seed: 1716761040
  $gtk.reset seed: 1716671785
  $args.geometry.quadtree_bounding_box_c([{ x: 0, y: 0, w: 100, h: 100 }])
  $args.geometry.quadtree_bounding_box_c([{ x: 0, y: 0, w: 100, h: 100 }, { x: 200, y: 200, w: 100, h: 100 }])
  $args.geometry.quadtree_bounding_box_c([{ x: 0, y: 0, w: 100, h: 100 }, { x: 200, y: 200, w: 100, h: 100 }].to_enum)
  $args.geometry.quadtree_bounding_box_c([{ x: 0, y: 0, w: 100, h: 100 }, { x: 200, y: 200, w: 100, h: 100 }].to_enum.find_all {|f| true })
  Player.class.methods(false)
  $gtk.reset seed: 1694051179
  $gtk.reset seed: 1694051398
  Player.new.dx
  Player.new.method(:dx)
  Object.new.dx
  m = Player.new.method(:dx)
  m.source
  m.source_location
  $gtk.reset seed: 1694051806
  $gtk.reset seed: 1694052084
  $gtk.reset seed: 1694052358
  $gtk.reset seed: 1694053291
  pretty_print $state.player
  [[:a 10]].to_h
  [[:a, 10]].to_h
  $state.player.instance_variables
  Fn.pp $state.player
  Fn.pretty_print $state.player
  pretty_print $state.player.dx
  puts state.player.dx
  puts state.player.dy
  $gtk.reset seed: 1694055336
  $gtk.reset seed: 100\
  $recording.stop "replay.txt"
  $gtk.reset seed: 1694057
  $gtk.reset seed: 1694059107eeeeeeeee
  $game.focal_point
  $gtk.reset seed: 1694059107
  $state.player.death_at
  $state.player.on_floor
  $gtk.reset seed: 1694065645
  $gtk.reset seed: 1694069059
  $gtk.reset seed: 1694381125
  $gtk.reset seed: 1694406521
  $args.grid.keys
  $args.grid.methods
  $args.grid.render_width
  $args.grid.all_screen_width
  $args.grid.methods(false)
  $args.grid.allscreen_width
  $args.grid.allscreen_height
  $args.grid.allscreen_scale
  $args.grid.render_scale
  $state.player.shift_rect
  $args.inputs.methods(false)
  $args.geometry.methods(false)
  pretty_print $args.geometry.methods(false)
  $cvars.keys["game_metadata.hd"]
  $cvars["game_metadata.hd"].locked
  $cvars["game_metadata.hd"].value = false
  $cvars["game_metadata.hd"].methods
  $cvars["game_metadata.hd"].methods(false)
  $gtk.reset seed: 1695608916
  $state.bombs.clear
  $gtk.reset seed: 1695713798
  $state.level.storylines
  $state.level.storylines[0].id = 0
  $state.level_editor.deleted_storyline_text
  $gtk.reset seed: 16957157
  a = [1]
  a.unshift
  a.shift
  $state.urinals
  $gtk.reset seed: 1696092949
  $state.money = 10
  $gtk.reset seed: 1696096502
  $geometry.uudi
  $gtk.uuid
  $geometry.uuid
  Meeple.defaults
  $gtk.reset seed: 1696105892
  $gtk.reset seed: 1696107002
  GTK::Easing.docs
  $gtk.easing.docs
  docs_search "easing"
  $gtk.reset seed: 1696110128
  $gtk.reset seed: 1696115042
  $gtk.reset seed: 1696119149
  $state.fx_queue
  $state.fade_out_queue.length
  $state.cleaners
  $state.cleaners[0]
  $state.cleaners[0].ivar(:m)
  $state.purchase_cleaner_button
  $gtk.reset seed: 1696121778
  $state.minigun_unlocked = true
  $gtk.reset seed: 1696131951
  $gtk.reset seed: 1696136079
  $gtk.reset seed: 1696182064
  $state.money = 100
  $gtk.reset seed: 1696776905
  $state.fx_queue.clear
  a = [1, 2]
  a.reject! {|i| i == 1 }
  $gtk.reset seed: 1696782065
  $state.guides
  $state.player.x = 1106; state.player.y = 1330
  $state.level.guides_loaded
  $state.level.guides
  $state.level.guides_loaded = false
  $state.collected_guides.length
  $state.player.oms_celles
  $state.player.oms_cells
  $state.collected_guides
  $gtk.reset seed: 1696784388
  $args.inputs.locale = "en"
  $args.inputs.locale = "ru"
  $args.inputs.locale = "tr"
  Object.respond_to? :eventttt
  Object.respond_to? :eventtt
  Object.respond_to? :a
  Object.respond_to? :event
  $gtk.disable_aggressive_gc!
  reset_with count: 210000
  8675309/8675310
  1./(2)
  1/2
  1.div(2)
  $gtk.reset seed: 1697234254
  $wizards.ios.start env: :sim, sim_name: "iPhone SE"
  $wizards.ios.start env: :sim, sim_name: "Pro"
  a = {}
  a.respond_to?(:x)
  a.respond_to?(:fodkdjfjsk)
  $args.grid.native_width
  $args.grid.native_height
  $gtk.set_window_scale 100
  $wizards.ios.start env: :sim, sim_name: "iPhone 14"
  $wizards.ios.start env: :sim, sim_name: "Plus"
  $grid.window_width
  $wizards.ios.start env: :sim, sim_name: "Standard"
  $wizards.ios.start env: :sim, sim_name: "CE"
  $wizards.ios.start env: :sim, sim_name: "14p"
  $wizards.ios.start env: :sim, sim_name: "SE"
  $wizards.ios.start env: :sim, sim_name: "iPad"
  $wizards.ios.start env: :sim, sim_name: "Max"
  $wizards.ios.simctl_list_devices
  $wizards.ios.reset_simulators
  $wizards.itch.help
  $wizards.itch.set_devid "amirrajan"
  $wizards.itch.set_devtitle "Amir Rajan"
  $wizards.itch.set_gameid "a-car-that-turns"
  $wizards.itch.set_gametitle "A Car That Turns"
  $wizards.itch.set_version "19.4"
  $wizards.itch.reset
  $wizards.itch.start
  $wizards.itch.set_devid "myname"
  $wizards.itch.set_devtitle "My Name"
  $wizards.itch.set_gameid "mygame"
  $wizards.itch.set_gametitle "My Game"
  $wizards.itch.set_version "0.1"
  $wizards.itch.set_icon "metadata/icon.png"
  $wizards.ios.get_steps_to_execute
  $wizards.ios.start
  $wizards.ios.restart
  $wizards.ios.reset
  $wizards.ios.last_executed_steps
  "hello".capitalize
  $args.inputs.keyboard.truthy_keys
  $args.inputs.keyboard.keys
  $args.inputs.keyboard.key_held.keys
  Kernel.open_docs!
  Kernel.open_docs
  $args.state.keys
  $args.state.tts
  $args.state.tts.speak("hello world")
  $args.state.tts.speak("exactly what do you think you're doing?")
  $args.start.player.dy
  $args.state.player.dy
  $state.audio
  $geometry.angle_from({x: 0, y: 0}, { x: 1, y: 1})
  $geometry.angle_from({x: 1, y: 1}, { x: 0, y: 0})
  $geometry.angle
  $gtk.reset seed: $gtk.seed
  puts $gtk.seed
  $gtk.reset 100
  $gtk.reset seed: 300
  $gtk.reset $gtk.started_at
  $args.audio.clear
  $state.gravity
  $state.gravity = 1.3
  $state.gravity = 10
  $state.player.gravity = 0.6
  $gtk.reset seed: 1700724065
  $gtk.reset seed: 1700879017
  $gtk.seed
  $gtk.set_rng
  $gtk.set_rng 100
  $gtk.reset seed: {:seed=>100}
  Kernel.export_docs!
  $gtk.open_docs
  Kernel.export_docs!; $gtk.open_docs
  $state.player.dx
  $gtk.reset seed: 1701582735
  $gtk.reset seed: 1701582816
  {}.yield_self
  {}.yield_self { |o| puts o.class }
  $gtk.reset seed: 1701630761
  $gtk.get_framerate_diagnostics
  $root_scene.level_editor.selected_tile
  $state.slide
  $state.keys
  $state.as_hash.keys
  $state.keeper.angle
  $gtk.set_window_scale 1.50
  1280 * $grid.native_scale
  $grid.hd_width * $grid.native_scale
  $grid.offset_x
  2054
  $grid.allscreen_w
  $gtk.set_window_scale = 1.5
  $gtk.set_window_scale 1.5
  3.0 / 1.25
  1280 * 3.0
  3840 / 1280
  3840 / 1.25
  1600 * 1.25
  1200 * 2.5
  1200 * 1.25
  1280 * 1.25
  1280 * 2
  3840 * 2560
  3840 / 2560
  $gtk.set_window_scale = 1.0
  $grid.window_w
  $grid.window_h
  $grid.native_enum
  $grid.native_h
  $grid.offset_y
  $grid.allscreen_offset_x
  $grid.allscreen_offset_y
  a |> puts
  $gtk.reset seed: 1710919754
  GTK::open_docs
  GTK::export_docs!
  GTK::export_docs!;
  GTK::export_docs!; GTK::open_docs
  $gtk.list_files "../samples"
  $gtk.list_files "samples
  $gtk.list_files "/samples"
  export_docs!
  $gtk.export_docs!
  raise "foobar"
  $gtk.ffi_file.mount(File.expand_path("./samples"))
  puts $gtk.list_files "."
  puts $gtk.list_files "/"
  puts $gtk.list_files "/samples"
  puts File.expand_path("./samples")
  File.expand_path("./samples")
  DocsOrganizer.get_docsify_content "docs/api/audio.md", "# Audio"
  $args.docs_easing
  $args.docs
  GTK::Args.docs_easing
  GTK::Args.docs_cvars
  puts Geometry.docs_class
  r = Geometry.docs_find_intersect_rect
  r
  $gtk.console.include_header_marker? r
  $gtk.console.include_header_marker? r.each_line.to_a[0]
  puts "* Hello"
  puts "** Hello"
  Geometry.docs_find_all_intersect_rect
  Geometry.docs_create_quad_tree
  Geometry.docs_find_all_intersect_rect_quad_tree
  Geometry.docs_find_intersect_rect
  Geometry.docs_anchor_rect
  Geometry.docs_paoint_inside_circle?
  Geometry.docs_class
  Geometry.docs_point_inside_circle?
  Geometry.docs_line_intersect
  Geometry.docs_ray_intersect
  Geometry.docs_rect_navigate
  Array.docs
  Array.docs_class
  Array.docs_map_2d
  Array.docs_map
  1.to_si
  ReadMe.docs
  ReadMe.docs_hello_world
  $gtk.export_docs;
  Layout.docs_rect
  GTK::docs_class_macros
  GTK.docs_environment_functions
  GTK.docs_all
  GTK::docs_dlopen
  $gtk.export_docs!;
  $gtk.export_docs!; $gtk.open_docs
  raise "Foobar"
  $recording.start_replay "replay.txt"
  $state
  $state.class
  Object.const_defined? :NONE
  GTK::NONE
  GTK.const_defined? :NONE
  NONE = Object.new
  NONE
  GTK.list_files("/samples")
  GTK.list_files("samples/")
  GTK.list_files("docs")
  $recording.start
  $gtk.reset seed: 1711188973
  $state.player.
  $state.player
  $state.player.action_lookup
  $state.player.actions_lookup
  $state.player.actions_lookup.slash_0
  $state.terrain
  pretty_print $state.terrain
  $args.state.terrain
  $gtk.reset seed: 1711192576
  $outputs.debug.respond_to? :watch
  $outputs.debug.respond_to? :reset_watch_label_count
  Grid.origin_center!
  $recording.stop 'replay-2.txt'
  $gtk.reset seed: 100
  $grid.w
  $grid.native_w
  $grid.hd_offset_y
  $grid.hd_offset_x
  $grid.scale_enum
  $grid.hd_scale
  $grid.native_scale
  $grid.native_scale_enum
  $grid.h_native
  $grid.w_native
  Grid.window_w
  Grid.window_h
  $grid.hd_width
  $grid.hd_w
  $grid.hd_h
  $grid.h_hd
  $grid.w_hd
  Grid.right
  Grid.name
  Grid.origin_name
  Grid.offset_x
  Grid.hd_left
  4412 / Grid.native_scale
  2056 * 2
  1286 * 2
  Grid.hd_width
  1280 * 3
  Grid.hd_offset_x
  Grid.device_width
  2056 / 16
  128.5 * 9
  Grid.native_enum
  1280 * 2.5
  1280
  3456 / 1280
  3456
  3456 / 16
  Grid.window_height
  Grid.window_width
  Grid.hd_right
  Grid.hd_bottom
  Grid.native_height
  720 * 2.7
  Grid.hd_height
  Grid.native_width
  Grid.native_scale
  Grid.native_scale_enum
  $grid.name
  $grid.hd_top
  $grid.hd_left
  $grid.hd_right
  $grid.hd_bottom
  Grid.allscreen_px
  Grid.top_pt
  Grid.top_px
  $cvars.keys
  $cvars.keys["game_metadata.hd_letterbox"]
  $cvars.key["game_metadata.hd_letterbox"]
  $cvars["game_metadata.hd_letterbox"]
  $cvars["game_metadata.hd_letterbox"].value
  Cvar["game_metadata.hd_letterbox"].value
  Cvars["game_metadata.hd"]
  GTK::Runtime::Cvars
  GTK::Runtime::Cvars.to_s
  Cvars["game_metadata.hd_letterbox"].value
  self.respond_to? :Cvars
  {}
  Cvars
  pretty_print Cvars.keys
  Grid.w_pt
  Grid.w_px
  Grid.allscreen_w_pt
  Grid.h_px
  Grid.texture_scale * 1280
  Grid.allscreen_h_pt
  Grid.allscreen_h_px / Grid.allscreen_h_pt
  Grid.allscreen_h_pt / 2.0
  1440 / 1280
  1280 / 1440
  Grid.allscreen_offset_x_px
  Grid.allscreen_x_px
  1280 * Grid.texture_scale
  Grid.allscreen_w_px
  Grid.allscreen_w_px / Grid.texture_scale
  Grid.allscreen_h_px / Grid.texture_scale
  1478 / 720
  Grid.texture_scale_enum
  Grid.allscreen_h_px
  1612 - 1280
  332 / 2
  Grid.allscreen_offset_y_px
  Grid.allscreen_offset_y_px / Grid.texture_scale
  1612 - 358 * 2
  Grid.allscreen_h
  Grid.allscreen_offset_h
  Grid.allscreen_offset_y
  $gtk.set_window_scale 1.25
  GTK.gen_docs!; GTK.open_docs
  GTK.export_docs!;
  Grid.allscreen_w
  GTK.export_docs!; GTK.open_docs
  Grid.rect
  Grid.rect_px
  Grid.x_px
  $gtk.open_root_dir
  $gtk.open_game_dir
  $gtk.write_file_root "tmp/ios/foobar.txt"
  $gtk.write_file_root "tmp/ios/foobar.txt", "test"
  pwd
  GTK.exec "pwd"
  $wizards.ios.tmp_directory
  $gtk.exec "pwd"
  GTK.ffi_misc.get_local_ip_address
  $gtk.a11y_emulation_enabled?
  $gtk.reset seed: 1711563427
  $gtk.reset seed: 1711563814
  $gtk.reset seed: 1711567598
  $gtk.reset seed: 1711568701
  $args.audio.mute
  h = {}
  h.store(:a, 5)
  h
  $gtk.reset seed: 1712324718
  $game.stores[:bullets] = 1
  $game.stores[:battery] = 1
  $game.stores[:wood] = 9999
  $game.stores[:teeth] = 0
  $game.stores[:scales]= 0
  $game.stores[:fur] = 9999
  $game.stores[:leather] = 1000
  $game.stores[:cloth] = 1
  $game.stores[:iron_sword] = 1
  $game.stores[:bolas] = 1
  $game.stores[:steel_sword] = 1
  $game.stores[:katana] = 1
  $game.stores[:rifle] = 1
  $game.stores[:bullets] = 100
  $game.stores[:carbine] = 1
  $game.stores[:battery] = 99
  $game.stores[:grenade] = 1
  $game.stores[:bullets] = 99
  $game.stores[:jewel] = 1
  $game.stores.delete :iron_sword
  $game.stores.delete :steel_sword
  $game.world.stores[:bolas] = 1
  $game.world.stores[:rifle] = 1
  $game.world.stores[:carbine] = 1
  10.times { $game.tick }
  $game.world.stores[:steel_sword] = 1
  $game.world.stores[:bullets] = 99
  $game.world.stores[:bone_spear] = 1
  $game.world.stores[:iron_sword] = 1
  $game.world.visible_landmarks
  $game.world.visible_locations
  $game.stores[:coal] = 9999
  $game.stores[:steel] = 9999
  $game.stores[:sulphur] = 9999
  $recording.start_recording 100, 2
  $recording.start_recording 100, 10
  $recording.stop 'replay.txt'
  $replay.start 'replay.txt', speed: 1
  $replay.start 'replay.txt', speed: 10
  $replay.start 'replay.txt', speed: 20
  $replay.start 'replay.txt', speed: 50
  300.times { $game.tick }
  $gtk.reset seed: 1712884724
  $gtk.reset seed: 1712884857
  $gtk.reset seed: 1712904956
  10.0.fdiv(5)
  $gtk.ffi_misc.export_user_defaults(["fire"])
  $gtk.reset seed: 1713035551
  $gtk.reset seed: 1713056037f
  $gtk.reset seed: 1713056037
  CVars
  Cvars["game_metadata.user_directory"]
  Cvars["game_metadata.user_directory"].value
  $gtk.ffi_file.mount
  $gtk.exec "ls ."
  $gtk.exec "ls *.zip"
  $gtk.ffi_file.mount "dragonruby-standard-macos.zip"
  $gtk.ffi_file.mount "mnt.zip"
  $gtk.list_files "mnt", "/mnt"
  $gtk.ffi_file.mount "mnt", "/mnt"
  $gtk.list_files "/mnt"
  $gtk.list_files "mnt"
  $gtk.read_file "foobar.txt"
  $gtk.stat_file "mnt.zip"
  $gtk.list_files "mnt.zip"
  $gtk.list_files "mnt.zip/foobar.txt"
  $gtk.ffi_file.mount "mnt.zip", "/mnt"
  $gtk.list_files "mnt.zip/"
  $gtk.list_files "cmake-build"
  $gtk.list_files "cmake-build/"
  $gtk.list_files "."
  $gtk.list_files "./samples"
  $gtk.list_files "samples"
  $gtk.list_files "/app"
  $gtk.list_files "./app"
  $gtk.list_files "app"
  $gtk.list_files "vscode.zip/"
  $gtk.list_files "vscode.zip"
  $gkt.list_files "."
  $gkt.list_files "/"
  $gtk.list_files "/"
  $gtk.list_files "/vscode.zip"
  $gtk.list_files "/vscode.zip/Contents"
  $gkt.read_file "vscode.zip/Visual Studio Code.app/Contents/Info.plist"
  $gtk.read_file "vscode.zip/Visual Studio Code.app/Contents/Info.plist"
  $gkt.read_file "vscode/Visual Studio Code.app/Contents/Info.plist"
  $gtk.read_file "vscode/Visual Studio Code.app/Contents/Info.plist"
  $gtk.ffi_file.list_files "vscode.zip"
  $gtk.ffi_file.list("vscode.zip")
  $gtk.ffi_file.mount "vscode.zip", "vscode.zip"
  $gtk.ffi_file.list("vscode.zip/")
  $gtk.ffi_file.mount "vscode.zip", "vscode"
  $gtk.ffi_file.list("vscode")
  $gtk.ffi_file.list("vscode/")
  $gtk.ffi_file.mount "vscode.zip"
  $gtk.ffi_file.list "vscode.zip"
  :wq
  Grid.bottom
  $wizards.ios.root_folder
  $wizards.ios.app_path
  Cvars["game_metadata.ignored_directories"].values
  Cvars["game_metadata.ignored_directories"].value
  CVars["game_metadata.ignored_directories"].value
  Cvars["game_metadata.ignored_directories"]
  Cvars.keys
  Cvars["game_metadata.ignore_directories"]
  Cvars["game_metadata.ignore_directories"].value
  $gtk.list_files ""
  $game.room.forest_unlocked
  $game.builder_status
  $game.room.builder_status
  $inputs.controller_one
  $inputs.controller_one.name
  $game.world.keys
  $game.world.keys.map { |k| k.last }
  $game.world.keys.map { |k| k.last }.max
  $game.world.aesthetics.keys
  $game.world.aesthetics.keys.map { |k| k.last }.max
  $gtk.reset seed: 1713311238
  $wizards.ios.start env: :hotload, uninstall: :false
  $wizards.ios.start env: :dev, uninstall: :false
  $wizards.ios.start env: :dev, uninstall: false
  $args.outputs.primitives.push nil
  $args.outputs.primitives << {}
  $args.outputs.primitives << nil
  $game.world.stores.keys
  $game.world.stores[:coal] = 1
  $game.world.stores[:teeth] = 1
  $game.world.stores[:meat] = 1
  $game.world.stores[:scales] = 1
  $game.world.stores[:cloth] = 1
  $game.world.stores[:sulphur] = 1
  $game.world.stores[:steel] = 1
  $game.world.stores[:iron] = 1
  $game.world.stores[:jewel] = 1
  $game.world.stores[:alien_alloy] = 1
  $gtk.ffi_misc.android "hello"
  $game.outside.population
  $game.outside.population = 16
  $game.stores[:wood] = 1000
  $game.stores[:fur] = 400
  $game.stores[:leather] = 25
  $gtk.enable_a11y_emulation!
  $args.audio.volume = 0
  $game.stores[:cured_meat] = 100
  $game.stores[:torch] = 1
  $game.stores[:iron] = 100
  $game.world.stores[:katana] = 1
  $gtk.reset seed: 1713407292
  $game.world.stores[:grenade]
  $game.to_go_final_stage!
  $game.to_go_final_stage
  $game.world.stores[:grenade] = 1
  $gtk.platform = "Foo"
  GTK.platform_mappings
  $gtk.platform = "Android"
  $gtk.is_steam_release = true
  $gtk.is_steam_release = false
  $gtk.platform = "iOS"
  $gtk.platform = "Mac OS X"
  ios false=
  $game.room.fire = :roaring
  ios false
  iosh
  $gtk.reset seed: 1714407917
  $wizards.ios.start env: :sim
  $gtk.reset seed: 1715259836
  $game.world.stores[:bolas] = 5
  $game.world.god_mode!
  $game.stores[:coal] = 100
  $game.stores[:steel] = 100
  $game.stores[:sulphur] = 50
  $game.stores[:alien_alloy] = 30
  GTK.platform = "iOS"
  $game.world.compass_direction
  GTK.a11y_enable!
  iosh false
  $game.room.fire = :dead
  $wizards.ios.start env: :prod
  $game.go_to_final_stage
  100.times { $game.tick }
  $game.world.in_battle?
  $game.world.event.in_battle?
  $game.world.event.title
  $game.world.event.text
  $game.world.event.current_scene
  $gtk.reset seed: 1715737972
  $scene.option_1_button
  $scene.current_event.options
  $scene.current_event[:options]
  $scene.current_scene[:options]
  $gtk.reset seed: 1715744703
  $game.frame_tick
  $game.instance_variable_get(:@frame_tick)
  $gtk.reset seed: 1715747233
  $gtk.ffi_misc.generate_uuid
  GTK.create_uuid
  args.outputs.solids.owner.name
  args.outputs.solids.owner
  args.outputs.solids.owner.target
  args.outputs[:foobar].solids.owner.target
  args.outputs.solids.class
  $args.outputs.solids.owner
  $game.world.current_hp = 2
  $game.just_woke_up_from_nightmare
  $game.world.available_attacks
  $game.world.available_actions
  $game.world.available_actions.first.name
  $game.world.available_actions.first.action_name
  $game.world.available_actions.map { |a| a.action_name}
  $game.world.attacks
  $game.world.available_actions.first
  $game.world.available_actions.first.class
  $game.world.available_actions.first.methods
  $game.world.available_actions.first.public_methods(false)
  $game.world.available_actions.first.percentage
  $game.world.actions[:fists]
  $game.world.actions
  $scene.gen_spots!
  $scene.progress_bars
  $scene.battle_last_attack_result
  $scene.battle_last_attack_result.methods(false)
  $scene.battle_last_attack_result.attacked
  $args.state.next_scene = :world_scene
  $gtk.reset seed: 1715754423
  $game.total_defector_deaths
  $game.world.event_on_death
  $game.world.tutorial_mode?
  $game.world.total_deaths
  $args.inputs.mouse.left_click
  $args.inputs.mouse.right_click
  $args.inputs.mouse.buttons
  $args.inputs.mouse.button_bits[1]
  $args.inputs.mouse.button_bits
  $gtk.reset seed: 1715776417
  $scene.option_controls
  $scene.weapon_controls
  $gtk.reset seed: 1715777538
  $scene.supply_controls
  $scene.loot_controls
  $game.world.current_hp
  $gtk.save_state
  $game.view_state
  GTK.stat_file "foobar.txt"
  $game.has_save?
  $game.world[[28,30]]
  $game.world.copy
  $game.world[[28,31]]
  $game.save_synchronously
  $game.world
  $game.world.to_h
  $game.world.to_h[[21, 30]]]
  $game.world.to_h[[21, 30]]
  $game.world.to_h[[$game.world.x, $game.world.y]]
  $game.world.to_h[[$game.world.x, $game.world.y + 1]]
  $game.world.aesthetics
  $game.mind_games.message
  $game.mind_games.message_history
  $game.world.world_stores
  $game.world.world_stores_hash
  $game.world.stores
  $game.world.swamp_stores
  $game.world.swamp_weapon_stores
  $game.story_line.message
  $game.world.weapon_stores << IronSword.new
  $game.world.weapon_stores << StealSword.new
  $game.world.weapon_stores << SteelSword.new
  GameStateNew.load $game
  $game.world.cleared
  $game.world.aborted
  $game.world.percentage_cleared_this_time
  GameStateNew.save $game
  Marshal
  Marshal.methods
  Marshal.dump
  a = { x: 100, y: 100, w: 10, h: 10, flip_vertically: true }
  Marshal.dump a
  ad = Marshal.dump a
  Marshal.load ad
  w = IronSword.new
  Marshal.dump w
  v = Marshal.dump w
  w
  Marshal.load v
  Marshal.load(v).to_h
  GameStateNew.save_marsharl $game
  GameStateNew.save_marshal $game
  $args.state.next_scene = :game_over
  $gtk.reset seed: 1715955386
  $args.state.next_scene = :game_over_scene
  $game.world.weapon_stores.clear
  $scene.weapon_loot
  $game.world.current_hp = 25
  $game.save
  Layout.rect.h
  Layout.rect(h: 1.5).h
  $args.state.current_scene
  $args.state.game.current_scene
  $state.camera
  $gtk.reset
  GTK::Grid
  GTK::Grid.h
  $game.world.current_hp = 50
  $scene.current_scene[:cutscene
  $game.world.event[:cutscene]
  $scene.current_scene[:cutscene]
  $args.inputs.keyboard.key_down.colon
  $scene.current_scene.class
  $scene.cutscene_landmarks_label
  $scene.current_event
  $gtk.reset seed: 1715992924
  Grid.top
  Grid.left
  Grid.x
  Grid.allscreen_x
  Grid.allscreen_right
  Grid.allscreen_top
  Grid.allscreen_bottom
  Grid.allscreen_left
  puts "hello"
  puts 'hi'
  hello
  reset_with count: 100
  $gtk.reset seed: 1716074819
  $game.world.event.init_scenes
  $gtk.reset seed: 1716086145
  $game.world.landmark_locations :ship
  $gtk.reset seed: 1716156656jj
  $gtk.reset seed: 1716156656
  @game.world.event
  $scene.metadata.world.class
  $scene.world.class
  $gtk.reset seed: 1716172621
  $root_scene.world_in_context
  $root_scene.world_in_context.class
  $gtk.reset seed: 1716232258
  $scene.game.world.event[:enemy]
  $scene.game.world.event
  $scene.game.world.event.current_event
  $scene.game.world.event.current_scene
  $scene
  $scene.world
  $scene.world.defector_x
  $scene.world.defector_y
  $scene.game
  $scene.mini_world.class
  $scene.mini_world.event
  $scene.mini_world.event.current_scene
  $scene.mini_world.current_scene
  $gtk.reset seed: 1716234064
  $game.world.current_hp = 100; $game.world.water = 100
  $state.scene_at
  $gtk.reset seed: 1716241690
  $gtk.reset seed: 1716241984
  $state.next_scene
  $state.queued_scene
  $state.queued_at
  $state.queued_scene_at
  $state.queued_scene_at.elapsed_time
  $gtk.set_window_scale 1.0
  $gtk.set_window_scale 0.75
  $gtk.set_window_scale 0.5
  $gtk.reset seed: 1716322978
  $gtk.reset seed: 1716406535
  $scene.max_visible_columns
  29 - 15
  352 / 14
  $gtk.reset seed: 1716419861
  $gtk.reset seed: 1716421297
  hi
  $args.state.player
  $args.state.player.x = 200
  GTK.set_window_scale 0.5
  $gtk.reset seed: 1716490635
  $game.world.current_hp = 100
  $game.world.water = 100
  $gtk.reset seed: 1716496019
  $game.world.death_reason
  $args.outputs.background_color
  $scene.metadata_background_color
  $scene.prefab.notifications
  $scene.prefab.notifications.first.at.elapsed_time
  $scene.prefab.notifications.first.at
  $scene.prefab.notifications[:water]
  $scene.prefab.notifications[:water].at
  $scene.prefab.notifications[:water].at.elapsed_time
  "".to_i
  $game.world.event.scenes.length
  $scene.current_scene_text
  $scene.current_scene
  $gtk.reset seed: 1716499353
  $scene.metadata.text_split_length = 27
  $game.world.current_hp = 30
  $game.world.deaths_by_defector
  $game.world.x
  $game.world.y
  $game.world.defector_y = 30
  $game.world.defector_y
  $game.world.defector_x
  $game.world.defector_x = 18
  $game.world.base_vision_radius = 10
  $game.world.event.class
  $game.world.stores[:torch]
  $state.scene
  $scene.metadata.text_split_length = 28
  $scene.metadata.text_split_length = 30
  $game.world.action_hash
  $game.world.actions_hash
  $game.world.actions_hash[:fist]
  $game.world.actions_hash[:fists].use
  $game.world.actions_hash[:fists].
  $game.world.actions_hash[:fists]
  $game.world.actions_hash[:fists].class
  $game.world.actions_hash[:fists].can_use?
  $game.world.actions_hash[:fists].current_cooldown
  $scene.actions_hash[:fists].percentage
  $scene.actions_hash[:fists].tick
  $scene.actions_hash
  Layout.gutter_bottom
  $gtk.reset seed: 1716528661
  $game.world.stores[:food] = 10
  $game.world.weapon_stores
  $gtk.reset seed: 1716564599
  $game.world.current_hp = 10
  $scene.metadata.text_split_length = 29
  $game.world.container
  $game.world.container[:max]
  $scene.metadata
  $scene.metadata.text = "only have one thing to say really...\n\n never gonna."
  $scene.last_punch_level
  $scene.last_punch_level = 1
  GameState.save $game
  $scene.class
  $gtk.reset seed: 1716569922
  $game.world.move_count
  $game.world.event
  $wizards.ios.start env: :dev
  $scene.mini_world
  $scene.mini_world.end_game_sequence
  $scene.mini_world.end_game_message
  $scene.mini_world.ticks
  $gtk.reset seed: 1716588839
  $scene.scroll_view.target_y_offset = 360
  $scene.scroll_view.y_offset
  $scene.scroll_view.target_y_offset = 100; GTK.close_console
  $scene.scroll_view.target_y_offset = 100; $gtk.console.close
  $wizards.ios.start env: :hotload
  Grid.texture_scale
  1 + 2
  GTK.reset
  $state.player.x
  $state.player.x = 100
  go_to_final_stage
  $game.world.base_vision_radius
  $game.world.landmark_location :murder_house
  $game.world.landmark_locations :murder_house
  $game.world.x = 13
  $game.world.y = 41
  $game.world.thought_message
  $game.world.thoughts_message
  $game.world.landmark_locations :mother_and_baby
  $game.world.y = 36
  $game.world.x = 11
  $game.world.current_hp = 9999
  $game.world.weapon_stores << Katana.new
  $scene.will_appear
  $scene.action_hash
  $scene.actions_hadh
  $scene.actions_hash[:rifle]
  $scene.actions_hash[:rifle].durability
  $scene.actions_hash[:rifle].current_durability
  $game.world.stores[:torch] = 10
  $scene.current_scene[:enemy]
  $scene.current_scene[:stunned]
  $game.world.stores[:torch] = 1
  $scene.debug_weapons
  $game.story_line.process
  $game.story_line.current_message
  $game.story_line.message_history
  $game.tick_count
  $game.world.admiral_visits
  $game.world.swamp_message?
  $game.story_line.swamp_message?
  $game.world.last_admiral_cutscene_visited = :none
  $game.world.current_admiral_cutsene
  $game.world.current_admiral_cutscene
  game.world.landmarks[[0, 0]]
  $game.world.landmarks[[0, 0]]
  $game.world.landmark_locations(:swamp]
  $game.world.landmark_locations(:swamp)
  $game.world.last_admiral_cutscene_visited
  $scene.cutscene
  $scene.cutscene.init_map
  $scene.cutscene.y
  $scene.cutscene.x
  $game.world.weapon_stores << Masamune.new
  $gtk.reset seed: 1716760633
  GameState.load $game
  $game.world.weapon_stores << Murasame.new
  $gtk.reset seed: 1716763696
  $gtk.reset seed: 1716763848
```

### Labels Text Wrapping - main.rb
```ruby
  # ./samples/01_rendering_basics/01_labels_text_wrapping/app/main.rb
  def tick args
    # create a really long string
    args.state.really_long_string =  "Lorem ipsum dolor sit amet, consectetur adipiscing elit. In vulputate viverra metus et vehicula. Aenean quis accumsan dolor. Nulla tempus, ex et lacinia elementum, nisi felis ullamcorper sapien, sed sagittis sem justo eu lectus. Etiam ut vehicula lorem, nec placerat ligula. Duis varius ultrices magna non sagittis. Aliquam et sem vel risus viverra hendrerit. Maecenas dapibus congue lorem, a blandit mauris feugiat sit amet."
    args.state.really_long_string += "\n"
    args.state.really_long_string += "Sed quis metus lacinia mi dapibus fermentum nec id nunc. Donec tincidunt ante a sem bibendum, eget ultricies ex mollis. Quisque venenatis erat quis pretium bibendum. Pellentesque vel laoreet nibh. Cras gravida nisi nec elit pulvinar, in feugiat leo blandit. Quisque sodales quam sed congue consequat. Vivamus placerat risus vitae ex feugiat viverra. In lectus arcu, pellentesque vel ipsum ac, dictum finibus enim. Quisque consequat leo in urna dignissim, eu tristique ipsum accumsan. In eros sem, iaculis ac rhoncus eu, laoreet vitae ipsum. In sodales, ante eu tempus vehicula, mi nulla luctus turpis, eu egestas leo sapien et mi."

    # length of characters on line
    max_character_length = 80

    # line height
    line_height = 25

    long_string = args.state.really_long_string

    # API: args.string.wrapped_lines string, max_character_length
    long_strings_split = args.string.wrapped_lines long_string, max_character_length

    # render a label for each line and offset by the line_height
    args.outputs.labels << long_strings_split.map_with_index do |s, i|
      {
        x: 60,
        y: 60.from_top - (i * line_height),
        text: s
      }
    end
  end

```

### Lines - main.rb
```ruby
  # ./samples/01_rendering_basics/02_lines/app/main.rb
  =begin
  APIs listing that haven't been encountered in a previous sample apps:

  - args.outputs.lines: Provided an Array or a Hash, lines will be rendered to the screen.
  - Kernel.tick_count: This property contains an integer value that
    represents the current frame. DragonRuby renders at 60 FPS. A value of 0
    for Kernel.tick_count represents the initial load of the game.
  =end

  # The parameters required for lines are:
  # 1. The initial point (x, y)
  # 2. The end point (x2, y2)
  # 3. The rgba values for the color and transparency (r, g, b, a)
  #    Creating a line using an Array (quick and dirty):
  #    [x, y, x2, y2, r, g, b, a]
  #    args.outputs.lines << [100, 100, 300, 300, 255, 0, 255, 255]
  #    This would create a line from (100, 100) to (300, 300)
  #    The RGB code (255, 0, 255) would determine its color, a purple
  #    It would have an Alpha value of 255, making it completely opaque
  # 4. Using Hashes, the keys are :x, :y, :x2, :y2, :r, :g, :b, and :a
  def tick args
    args.outputs.labels << { x: 640,
                             y: 700,
                             text: "Sample app shows how to create lines.",
                             size_px: 22,
                             anchor_x: 0.5,
                             anchor_y: 0.5 }

    # Render lines using Arrays/Tuples
    # This is quick and dirty and it's recommended to use Hashes long term
    args.outputs.lines  << [380, 450, 675, 450]
    args.outputs.lines  << [380, 410, 875, 410]

    # These examples utilize Kernel.tick_count to change the length of the lines over time
    # Kernel.tick_count is the ticks that have occurred in the game
    # This is accomplished by making either the starting or ending point based on the Kernel.tick_count
    args.outputs.lines  << { x:  380,
                             y:  370,
                             x2: 875,
                             y2: 370,
                             r:  Kernel.tick_count % 255,
                             g:  0,
                             b:  0,
                             a:  255 }

    args.outputs.lines  << { x:  380,
                             y:  330 - Kernel.tick_count % 25,
                             x2: 875,
                             y2: 330,
                             r:  0,
                             g:  0,
                             b:  0,
                             a:  255 }

    args.outputs.lines  << { x:  380 + Kernel.tick_count % 400,
                             y:  290,
                             x2: 875,
                             y2: 290,
                             r:  0,
                             g:  0,
                             b:  0,
                             a:  255 }
  end

```

### Solids Borders - main.rb
```ruby
  # ./samples/01_rendering_basics/03_solids_borders/app/main.rb
  =begin
  APIs listing that haven't been encountered in a previous sample apps:

  - args.outputs.solids: Provided an Array or a Hash, solid squares will be
    rendered to the screen.
  - args.outputs.borders: Provided an Array or a Hash, borders
    will be rendered to the screen.
  - args.outputs.primitives: Provided an Hash with a :primitive_marker key,
    either a solid square or border will be rendered to the screen.
  =end

  # The parameters required for rects are:
  # 1. The bottom left corner (x, y)
  # 2. The width (w)
  # 3. The height (h)
  # 4. The rgba values for the color and transparency (r, g, b, a)
  # [100, 100, 400, 500, 0, 255, 0, 180]
  # Whether the rect would be filled or not depends on if
  # it is added to args.outputs.solids or args.outputs.borders
  # (or its :primitive_marker if Hash is sent to args.outputs.primitives)
  def tick args
    args.outputs.labels << { x: 640,
                             y: 700,
                             text: "Sample app shows how to create solid squares and borders.",
                             size_px: 22,
                             anchor_x: 0.5,
                             anchor_y: 0.5 }

    # Render solids/borders using Arrays/Tuples
    # This is quick and dirty and it's recommended to use Hashes long term
    args.outputs.solids << [470, 520, 50, 50]
    args.outputs.solids << [530, 520, 50, 50, 0, 0, 0]
    args.outputs.solids << [590, 520, 50, 50, 255, 0, 0]
    args.outputs.solids << [650, 520, 50, 50, 255, 0, 0, 128]

    args.outputs.borders << [470, 320, 50, 50]
    args.outputs.borders << [530, 320, 50, 50, 0, 0, 0]
    args.outputs.borders << [590, 320, 50, 50, 255, 0, 0]
    args.outputs.borders << [650, 320, 50, 50, 255, 0, 0, 128]

    # using Hashes
    args.outputs.solids << { x: 710,
                             y: 520,
                             w: 50,
                             h: 50,
                             r: 0,
                             g: 80,
                             b: 40,
                             a: Kernel.tick_count % 255 }

    # primitives outputs requires a primitive_marker to differentiate
    # between a solid or a border
    args.outputs.primitives << { x: 770,
                                 y: 520,
                                 w: 50,
                                 h: 50,
                                 r: 0,
                                 g: 80,
                                 b: 40,
                                 a: Kernel.tick_count % 255,
                                 primitive_marker: :solid }

    args.outputs.borders << { x: 710,
                              y: 320,
                              w: 50,
                              h: 50,
                              r: 0,
                              g: 80,
                              b: 40,
                              a: Kernel.tick_count % 255 }

    # primitives outputs requires a primitive_marker to differentiate
    # between a solid or a border
    args.outputs.borders << { x: 770,
                              y: 320,
                              w: 50,
                              h: 50,
                              r: 0,
                              g: 80,
                              b: 40,
                              a: Kernel.tick_count % 255,
                              primitive_marker: :border }
  end

```

### Sprites - main.rb
```ruby
  # ./samples/01_rendering_basics/04_sprites/app/main.rb
  =begin
  APIs listing that haven't been encountered in a previous sample apps:
  - args.outputs.sprites: Provided an Array or a Hash, a sprite will be
    rendered to the screen.

  Properties of a sprite:
  {
    # common properties
    x: 0,
    y: 0,
    w: 100,
    h: 100,
    path: "sprites/square/blue.png",
    angle: 90,
    a: 255,

    # anchoring (float value representing a percentage to offset w and h)
    anchor_x: 0,
    anchor_y: 0,
    angle_anchor_x: 0,
    angle_anchor_y: 0,

    # color saturation
    r: 255,
    g: 255,
    b: 255,

    # flip rendering
    flip_horizontally: false,
    flip_vertically: false

    # sprite sheet properties/clipped rect (using the top-left as the origin)
    tile_x: 0,
    tile_y: 0,
    tile_w: 20,
    tile_h: 20

    # sprite sheet properties/clipped rect (using the bottom-left as the origin)
    source_x: 0,
    source_y: 0,
    source_w: 20,
    source_h: 20,
  }
  =end
  def tick args
    args.outputs.labels << { x: 640,
                             y: 700,
                             text: "Sample app shows how to render a sprite.",
                             size_px: 22,
                             anchor_x: 0.5,
                             anchor_y: 0.5 }

    # ==================
    # ROW 1 Simple Rendering
    # ==================
    args.outputs.labels << { x: 460,
                             y: 600,
                             text: "Simple rendering." }

    # using quick and dirty Array (use Hashes for long term maintainability)
    args.outputs.sprites << [460, 470, 128, 101, 'dragonruby.png']

    # using Hashes
    args.outputs.sprites << { x: 610,
                              y: 470,
                              w: 128,
                              h: 101,
                              path: 'dragonruby.png',
                              a: Kernel.tick_count % 255 }

    args.outputs.sprites << { x: 760 + 64,
                              y: 470 + 50,
                              w: 128,
                              h: 101,
                              anchor_x: 0.5,
                              anchor_y: 0.5,
                              path: 'dragonruby.png',
                              flip_horizontally: true,
                              flip_vertically: true,
                              a: Kernel.tick_count % 255 }

    # ==================
    # ROW 2 Angle/Angle Anchors
    # ==================
    args.outputs.labels << { x: 460,
                             y: 400,
                             text: "Angle/Angle Anchors." }
    # rotation using angle (in degrees)
    args.outputs.sprites << { x: 460,
                              y: 270,
                              w: 128,
                              h: 101,
                              path: 'dragonruby.png',
                              angle: Kernel.tick_count % 360 }

    # rotation anchor using angle_anchor_x
    args.outputs.sprites << { x: 760,
                              y: 270,
                              w: 128,
                              h: 101,
                              path: 'dragonruby.png',
                              angle: Kernel.tick_count % 360,
                              angle_anchor_x: 0,
                              angle_anchor_y: 0 }

    # ==================
    # ROW 3 Sprite Cropping
    # ==================
    args.outputs.labels << { x: 460,
                             y: 200,
                             text: "Cropping (tile sheets)." }

    # tiling using top left as the origin
    args.outputs.sprites << { x: 460,
                              y: 90,
                              w: 80,
                              h: 80,
                              path: 'dragonruby.png',
                              tile_x: 0,
                              tile_y: 0,
                              tile_w: 80,
                              tile_h: 80 }

    # overlay to see how tile_* crops
    args.outputs.sprites << { x: 460,
                              y: 70,
                              w: 128,
                              h: 101,
                              path: 'dragonruby.png',
                              a: 80 }

    # tiling using bottom left as the origin
    args.outputs.sprites << { x: 610,
                              y: 70,
                              w: 80,
                              h: 80,
                              path: 'dragonruby.png',
                              source_x: 0,
                              source_y: 0,
                              source_w: 80,
                              source_h: 80 }

    # overlay to see how source_* crops
    args.outputs.sprites << { x: 610,
                              y: 70,
                              w: 128,
                              h: 101,
                              path: 'dragonruby.png',
                              a: 80 }
  end

```

### Sounds - main.rb
```ruby
  # ./samples/01_rendering_basics/05_sounds/app/main.rb
  =begin

   APIs Listing that haven't been encountered in previous sample apps:

   - sample: Chooses random element from array.
     In this sample app, the target note is set by taking a sample from the collection
     of available notes.

   Reminders:

   - String interpolation: Uses #{} syntax; everything between the #{ and the } is evaluated
     as Ruby code, and the placeholder is replaced with its corresponding value or result.

   - args.outputs.labels: An array. The values generate a label.
     The parameters are [X, Y, TEXT, SIZE, ALIGNMENT, RED, GREEN, BLUE, ALPHA, FONT STYLE]
     For more information about labels, go to mygame/documentation/02-labels.md.
  =end

  # This sample app allows users to test their musical skills by matching the piano sound that plays in each
  # level to the correct note.

  # Runs all the methods necessary for the game to function properly.
  def tick args
    args.outputs.labels << [640, 360, "Click anywhere to play a random sound.", 0, 1]
    args.state.notes ||= [:C3, :D3, :E3, :F3, :G3, :A3, :B3, :C4]

    if args.inputs.mouse.click
      # Play a sound by adding a string to args.outputs.sounds
      args.outputs.sounds << "sounds/#{args.state.notes.sample}.wav" # sound of target note is output
    end
  end

```
