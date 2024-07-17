### Choose Your Own Adventure - decision.rb
```ruby
  # ./samples/99_genre_rpg_narrative/choose_your_own_adventure/app/decision.rb
  # Hey there! Welcome to Four Decisions. Here is how you
  # create your decision tree. Remove =being and =end from the text to
  # enable the game (just save the file). Change stuff and see what happens!

  def game
    {
      starting_decision: :stormy_night,
      decisions: {
        stormy_night: {
          description: 'It was a dark and stormy night. (storyline located in decision.rb)',
          option_one: {
            description: 'Go to sleep.',
            decision: :nap
          },
          option_two: {
            description: 'Watch a movie.',
            decision: :movie
          },
          option_three: {
            description: 'Go outside.',
            decision: :go_outside
          },
          option_four: {
            description: 'Get a snack.',
            decision: :get_a_snack
          }
        },
        nap: {
          description: 'You took a nap. The end.',
          option_one: {
            description: 'Start over.',
            decision: :stormy_night
          }
        }
      }
    }
  end

```

### Choose Your Own Adventure - main.rb
```ruby
  # ./samples/99_genre_rpg_narrative/choose_your_own_adventure/app/main.rb
  =begin

   Reminders:

   - Hashes: Collection of unique keys and their corresponding values. The values can be found
     using their keys.

     In this sample app, the decisions needed for the game are stored in a hash. In fact, the
     decision.rb file contains hashes inside of other hashes!

     Each option is a key in the first hash, but also contains a hash (description and
     decision being its keys) as its value.
     Go into the decision.rb file and take a look before diving into the code below.

   - args.outputs.labels: An array. The values generate a label.
     The parameters are [X, Y, TEXT, SIZE, ALIGNMENT, RED, GREEN, BLUE, ALPHA, FONT STYLE]
     For more information about labels, go to mygame/documentation/02-labels.md.

   - args.keyboard.key_down.KEY: Determines if a key is in the down state or pressed down.
     For more information about the keyboard, go to mygame/documentation/06-keyboard.md.

   - String interpolation: uses #{} syntax; everything between the #{ and the } is evaluated
     as Ruby code, and the placeholder is replaced with its corresponding value or result.

  =end

  # This sample app provides users with a story and multiple decisions that they can choose to make.
  # Users can make a decision using their keyboard, and the story will move forward based on user choices.

  # The decisions available to users are stored in the decision.rb file.
  # We must have access to it for the game to function properly.
  GAME_FILE = 'app/decision.rb' # found in app folder

  require GAME_FILE # require used to load another file, import class/method definitions

  # Instructions are given using labels to users if they have not yet set up their story in the decision.rb file.
  # Otherwise, the game is run.
  def tick args
    if !args.state.loaded && !respond_to?(:game) # if game is not loaded and not responding to game symbol's method
      args.labels << [640, 370, 'Hey there! Welcome to Four Decisions.', 0, 1] # a welcome label is shown
      args.labels << [640, 340, 'Go to the file called decision.rb and tell me your story.', 0, 1]
    elsif respond_to?(:game) # otherwise, if responds to game
      args.state.loaded = true
      tick_game args # calls tick_game method, runs game
    end

    if Kernel.tick_count.mod_zero? 60 # update every 60 frames
      t = args.gtk.ffi_file.mtime GAME_FILE # mtime returns modification time for named file
      if t != args.state.mtime
        args.state.mtime = t
        require GAME_FILE # require used to load file
        args.state.game_definition = nil # game definition and decision are empty
        args.state.decision_id = nil
      end
    end
  end

  # Runs methods needed for game to function properly
  # Creates a rectangular border around the screen
  def tick_game args
    defaults args
    args.borders << args.grid.rect
    render_decision args
    process_inputs args
  end

  # Sets default values and uses decision.rb file to define game and decision_id
  # variable using the starting decision
  def defaults args
    args.state.game_definition ||= game
    args.state.decision_id ||= args.state.game_definition[:starting_decision]
  end

  # Outputs the possible decision descriptions the user can choose onto the screen
  # as well as what key to press on their keyboard to make their decision
  def render_decision args
    decision = current_decision args
    # text is either the value of decision's description key or warning that no description exists
    args.labels << [640, 360, decision[:description] || "No definition found for #{args.state.decision_id}. Please update decision.rb.", 0, 1] # uses string interpolation

    # All decisions are stored in a hash
    # The descriptions output onto the screen are the values for the description keys of the hash.
    if decision[:option_one]
      args.labels << [10, 360, decision[:option_one][:description], 0, 0] # option one's description label
      args.labels << [10, 335, "(Press 'left' on the keyboard to select this decision)", -5, 0] # label of what key to press to select the decision
    end

    if decision[:option_two]
      args.labels << [1270, 360, decision[:option_two][:description], 0, 2] # option two's description
      args.labels << [1270, 335, "(Press 'right' on the keyboard to select this decision)", -5, 2]
    end

    if decision[:option_three]
      args.labels << [640, 45, decision[:option_three][:description], 0, 1] # option three's description
      args.labels << [640, 20, "(Press 'down' on the keyboard to select this decision)", -5, 1]
    end

    if decision[:option_four]
      args.labels << [640, 700, decision[:option_four][:description], 0, 1] # option four's description
      args.labels << [640, 675, "(Press 'up' on the keyboard to select this decision)", -5, 1]
    end
  end

  # Uses keyboard input from the user to make a decision
  # Assigns the decision as the value of the decision_id variable
  def process_inputs args
    decision = current_decision args # calls current_decision method

    if args.keyboard.key_down.left! && decision[:option_one] # if left key pressed and option one exists
      args.state.decision_id = decision[:option_one][:decision] # value of option one's decision hash key is set to decision_id
    end

    if args.keyboard.key_down.right! && decision[:option_two] # if right key pressed and option two exists
      args.state.decision_id = decision[:option_two][:decision] # value of option two's decision hash key is set to decision_id
    end

    if args.keyboard.key_down.down! && decision[:option_three] # if down key pressed and option three exists
      args.state.decision_id = decision[:option_three][:decision] # value of option three's decision hash key is set to decision_id
    end

    if args.keyboard.key_down.up! && decision[:option_four] # if up key pressed and option four exists
      args.state.decision_id = decision[:option_four][:decision] # value of option four's decision hash key is set to decision_id
    end
  end

  # Uses decision_id's value to keep track of current decision being made
  def current_decision args
    args.state.game_definition[:decisions][args.state.decision_id] || {} # either has value or is empty
  end

  # Resets the game.
  $gtk.reset

```

### Return Of Serenity - lowrez_simulator.rb
```ruby
  # ./samples/99_genre_rpg_narrative/return_of_serenity/app/lowrez_simulator.rb
  ###################################################################################
  # YOU CAN PLAY AROUND WITH THE CODE BELOW, BUT USE CAUTION AS THIS IS WHAT EMULATES
  # THE 64x64 CANVAS.
  ###################################################################################

  TINY_RESOLUTION       = 64
  TINY_SCALE            = 720.fdiv(TINY_RESOLUTION + 5)
  CENTER_OFFSET         = 10
  EMULATED_FONT_SIZE    = 20
  EMULATED_FONT_X_ZERO  = 0
  EMULATED_FONT_Y_ZERO  = 46

  def tick args
    sprites = []
    labels = []
    borders = []
    solids = []
    mouse = emulate_lowrez_mouse args
    args.state.show_gridlines = false
    lowrez_tick args, sprites, labels, borders, solids, mouse
    render_gridlines_if_needed args
    render_mouse_crosshairs args, mouse
    emulate_lowrez_scene args, sprites, labels, borders, solids, mouse
  end

  def emulate_lowrez_mouse args
    args.state.new_entity_strict(:lowrez_mouse) do |m|
      m.x = args.mouse.x.idiv(TINY_SCALE) - CENTER_OFFSET.idiv(TINY_SCALE) - 1
      m.y = args.mouse.y.idiv(TINY_SCALE)
      if args.mouse.click
        m.click = [
          args.mouse.click.point.x.idiv(TINY_SCALE) - CENTER_OFFSET.idiv(TINY_SCALE) - 1,
          args.mouse.click.point.y.idiv(TINY_SCALE)
        ]
        m.down = m.click
      else
        m.click = nil
        m.down = nil
      end

      if args.mouse.up
        m.up = [
          args.mouse.up.point.x.idiv(TINY_SCALE) - CENTER_OFFSET.idiv(TINY_SCALE) - 1,
          args.mouse.up.point.y.idiv(TINY_SCALE)
        ]
      else
        m.up = nil
      end
    end
  end

  def render_mouse_crosshairs args, mouse
    return unless args.state.show_gridlines
    args.labels << [10, 25, "mouse: #{mouse.x} #{mouse.y}", 255, 255, 255]
  end

  def emulate_lowrez_scene args, sprites, labels, borders, solids, mouse
    args.render_target(:lowrez).transient!
    args.render_target(:lowrez).solids  << [0, 0, 1280, 720]
    args.render_target(:lowrez).sprites << sprites
    args.render_target(:lowrez).borders << borders
    args.render_target(:lowrez).solids  << solids
    args.outputs.primitives << labels.map do |l|
      as_label = l.label
      l.text.each_char.each_with_index.map do |char, i|
        [CENTER_OFFSET + EMULATED_FONT_X_ZERO + (as_label.x * TINY_SCALE) + i * 5 * TINY_SCALE,
         EMULATED_FONT_Y_ZERO + (as_label.y * TINY_SCALE), char,
         EMULATED_FONT_SIZE, 0, as_label.r, as_label.g, as_label.b, as_label.a, 'fonts/dragonruby-gtk-4x4.ttf'].label
      end
    end

    args.sprites    << [CENTER_OFFSET, 0, 1280 * TINY_SCALE, 720 * TINY_SCALE, :lowrez]
  end

  def render_gridlines_if_needed args
    if args.state.show_gridlines && args.static_lines.length == 0
      args.static_lines << 65.times.map do |i|
        [
          [CENTER_OFFSET + i * TINY_SCALE + 1,  0,
           CENTER_OFFSET + i * TINY_SCALE + 1,  720,                128, 128, 128],
          [CENTER_OFFSET + i * TINY_SCALE,      0,
           CENTER_OFFSET + i * TINY_SCALE,      720,                128, 128, 128],
          [CENTER_OFFSET,                       0 + i * TINY_SCALE,
           CENTER_OFFSET + 720,                 0 + i * TINY_SCALE, 128, 128, 128],
          [CENTER_OFFSET,                       1 + i * TINY_SCALE,
           CENTER_OFFSET + 720,                 1 + i * TINY_SCALE, 128, 128, 128]
        ]
      end
    elsif !args.state.show_gridlines
      args.static_lines.clear
    end
  end

```

### Return Of Serenity - main.rb
```ruby
  # ./samples/99_genre_rpg_narrative/return_of_serenity/app/main.rb
  require 'app/require.rb'

  def defaults args
    args.outputs.background_color = [0, 0, 0]
    args.state.last_story_line_text ||= ""
    args.state.scene_history ||= []
    args.state.storyline_history ||= []
    args.state.word_delay ||= 8
    if Kernel.tick_count == 0
      args.gtk.stop_music
      args.outputs.sounds << 'sounds/static-loop.ogg'
    end

    if args.state.last_story_line_text
      lines = args.state
                  .last_story_line_text
                  .gsub("-", "")
                  .gsub("~", "")
                  .wrapped_lines(50)

      args.outputs.labels << lines.map_with_index { |l, i| [690, 200 - (i * 25), l, 1, 0, 255, 255, 255] }
    elsif args.state.storyline_history[-1]
      lines = args.state
                  .storyline_history[-1]
                  .gsub("-", "")
                  .gsub("~", "")
                  .wrapped_lines(50)

      args.outputs.labels << lines.map_with_index { |l, i| [690, 200 - (i * 25), l, 1, 0, 255, 255, 255] }
    end

    return if args.state.current_scene
    set_scene(args, day_one_beginning(args))
  end

  def inputs_move_player args
    if args.state.scene_changed_at.elapsed_time > 5
      if args.keyboard.down  || args.keyboard.s || args.keyboard.j
        args.state.player.y -= 0.25
      elsif args.keyboard.up || args.keyboard.w || args.keyboard.k
        args.state.player.y += 0.25
      end

      if args.keyboard.left     || args.keyboard.a  || args.keyboard.h
        args.state.player.x -= 0.25
      elsif args.keyboard.right || args.keyboard.d  || args.keyboard.l
        args.state.player.x += 0.25
      end

      args.state.player.y = 60 if args.state.player.y > 63
      args.state.player.y =  0 if args.state.player.y < -3
      args.state.player.x = 60 if args.state.player.x > 63
      args.state.player.x =  0 if args.state.player.x < -3
    end
  end

  def null_or_empty? ary
    return true unless ary
    return true if ary.length == 0
    return false
  end

  def calc_storyline_hotspot args
    hotspots = args.state.storylines.find_all do |hs|
      args.state.player.inside_rect?(hs.shift_rect(-2, 0))
    end

    if !null_or_empty?(hotspots) && !args.state.inside_storyline_hotspot
      _, _, _, _, storyline = hotspots.first
      queue_storyline_text(args, storyline)
      args.state.inside_storyline_hotspot = true
    elsif null_or_empty?(hotspots)
      args.state.inside_storyline_hotspot = false

      args.state.storyline_queue_empty_at ||= Kernel.tick_count
      args.state.is_storyline_dialog_active = false
      args.state.scene_storyline_queue.clear
    end
  end

  def calc_scenes args
    hotspots = args.state.scenes.find_all do |hs|
      args.state.player.inside_rect?(hs.shift_rect(-2, 0))
    end

    if !null_or_empty?(hotspots) && !args.state.inside_scene_hotspot
      _, _, _, _, scene_method_or_hash = hotspots.first
      if scene_method_or_hash.is_a? Symbol
        set_scene(args, send(scene_method_or_hash, args))
        args.state.last_hotspot_scene = scene_method_or_hash
        args.state.scene_history << scene_method_or_hash
      else
        set_scene(args, scene_method_or_hash)
      end
      args.state.inside_scene_hotspot = true
    elsif null_or_empty?(hotspots)
      args.state.inside_scene_hotspot = false
    end
  end

  def null_or_whitespace? word
    return true if !word
    return true if word.strip.length == 0
    return false
  end

  def calc_storyline_presentation args
    return unless Kernel.tick_count > args.state.next_storyline
    return unless args.state.scene_storyline_queue
    next_storyline = args.state.scene_storyline_queue.shift
    if null_or_whitespace? next_storyline
      args.state.storyline_queue_empty_at ||= Kernel.tick_count
      args.state.is_storyline_dialog_active = false
      return
    end
    args.state.storyline_to_show = next_storyline
    args.state.is_storyline_dialog_active = true
    args.state.storyline_queue_empty_at = nil
    if next_storyline.end_with?(".") || next_storyline.end_with?("!") || next_storyline.end_with?("?") || next_storyline.end_with?("\"")
      args.state.next_storyline += 60
    elsif next_storyline.end_with?(",")
      args.state.next_storyline += 50
    elsif next_storyline.end_with?(":")
      args.state.next_storyline += 60
    else
      default_word_delay = 13 + args.state.word_delay - 8
      if next_storyline.gsub("-", "").gsub("~", "").length <= 4
        default_word_delay = 11 + args.state.word_delay - 8
      end
      number_of_syllabals = next_storyline.length - next_storyline.gsub("-", "").length
      args.state.next_storyline += default_word_delay + number_of_syllabals * (args.state.word_delay + 1)
    end
  end

  def inputs_reload_current_scene args
    return
    if args.inputs.keyboard.key_down.r!
      reload_current_scene
    end
  end

  def inputs_dismiss_current_storyline args
    if args.inputs.keyboard.key_down.x!
      args.state.scene_storyline_queue.clear
    end
  end

  def inputs_restart_game args
    if args.inputs.keyboard.exclamation_point
      args.gtk.reset_state
    end
  end

  def inputs_change_word_delay args
    if args.inputs.keyboard.key_down.plus || args.inputs.keyboard.key_down.equal_sign
      args.state.word_delay -= 2
      if args.state.word_delay < 0
        args.state.word_delay = 0
        # queue_storyline_text args, "Text speed at MAXIMUM. Geez, how fast do you read?"
      else
        # queue_storyline_text args, "Text speed INCREASED."
      end
    end

    if args.inputs.keyboard.key_down.hyphen || args.inputs.keyboard.key_down.underscore
      args.state.word_delay += 2
      # queue_storyline_text args, "Text speed DECREASED."
    end
  end

  def multiple_lines args, x, y, texts, size = 0, minimum_alpha = nil
    texts.each_with_index.map do |t, i|
      [x, y - i * (25 + size * 2), t, size, 0, 255, 255, 255, adornments_alpha(args, 255, minimum_alpha)]
    end
  end

  def lowrez_tick args, lowrez_sprites, lowrez_labels, lowrez_borders, lowrez_solids, lowrez_mouse
    # args.state.show_gridlines = true
    defaults args
    render_current_scene args, lowrez_sprites, lowrez_labels, lowrez_solids
    render_controller args, lowrez_borders
    lowrez_solids << [0, 0, 64, 64, 0, 0, 0]
    calc_storyline_presentation args
    calc_scenes args
    calc_storyline_hotspot args
    inputs_move_player args
    inputs_print_mouse_rect args, lowrez_mouse
    inputs_reload_current_scene args
    inputs_dismiss_current_storyline args
    inputs_change_word_delay args
    inputs_restart_game args
  end

  def render_controller args, lowrez_borders
    args.state.up_button    = [85, 40, 15, 15, 255, 255, 255]
    args.state.down_button  = [85, 20, 15, 15, 255, 255, 255]
    args.state.left_button  = [65, 20, 15, 15, 255, 255, 255]
    args.state.right_button = [105, 20, 15, 15, 255, 255, 255]
    lowrez_borders << args.state.up_button
    lowrez_borders << args.state.down_button
    lowrez_borders << args.state.left_button
    lowrez_borders << args.state.right_button
  end

  def inputs_print_mouse_rect args, lowrez_mouse
    if lowrez_mouse.up
      args.state.mouse_held = false
    elsif lowrez_mouse.click
      mouse_rect = [lowrez_mouse.x, lowrez_mouse.y, 1, 1]
      if args.state.up_button.intersect_rect? mouse_rect
        args.state.player.y += 1
      end

      if args.state.down_button.intersect_rect? mouse_rect
        args.state.player.y -= 1
      end

      if args.state.left_button.intersect_rect? mouse_rect
        args.state.player.x -= 1
      end

      if args.state.right_button.intersect_rect? mouse_rect
        args.state.player.x += 1
      end
      args.state.mouse_held = true
    elsif args.state.mouse_held
      mouse_rect = [lowrez_mouse.x, lowrez_mouse.y, 1, 1]
      if args.state.up_button.intersect_rect? mouse_rect
        args.state.player.y += 0.25
      end

      if args.state.down_button.intersect_rect? mouse_rect
        args.state.player.y -= 0.25
      end

      if args.state.left_button.intersect_rect? mouse_rect
        args.state.player.x -= 0.25
      end

      if args.state.right_button.intersect_rect? mouse_rect
        args.state.player.x += 0.25
      end
    end

    if lowrez_mouse.click
      dx = lowrez_mouse.click.x - args.state.previous_mouse_click.x
      dy = lowrez_mouse.click.y - args.state.previous_mouse_click.y
      x, y, w, h = args.state.previous_mouse_click.x, args.state.previous_mouse_click.y, dx, dy
      puts "x #{lowrez_mouse.click.x}, y: #{lowrez_mouse.click.y}"
      if args.state.previous_mouse_click

        if dx < 0 && dx < 0
          x = x + w
          w = w.abs
          y = y + h
          h = h.abs
        end

        w += 1
        h += 1

        args.state.previous_mouse_click = nil
      else
        args.state.previous_mouse_click = lowrez_mouse.click
        square_x, square_y = lowrez_mouse.click
      end
    end
  end

  def try_centering! word
    word ||= ""
    just_word = word.gsub("-", "").gsub(",", "").gsub(".", "").gsub("'", "").gsub('""', "\"-\"")
    return word if just_word.strip.length == 0
    return word if just_word.include? "~"
    return "~#{word}" if just_word.length <= 2
    if just_word.length.mod_zero? 2
      center_index = just_word.length.idiv(2) - 1
    else
      center_index = (just_word.length - 1).idiv(2)
    end
    return "#{word[0..center_index - 1]}~#{word[center_index]}#{word[center_index + 1..-1]}"
  end

  def queue_storyline args, scene
    queue_storyline_text args, scene[:storyline]
  end

  def queue_storyline_text args, text
    args.state.last_story_line_text = text
    args.state.storyline_history << text if text
    words = (text || "").split(" ")
    words = words.map { |w| try_centering! w }
    args.state.scene_storyline_queue = words
    if args.state.scene_storyline_queue.length != 0
      args.state.scene_storyline_queue.unshift "~$--"
      args.state.storyline_to_show = "~."
    else
      args.state.storyline_to_show = ""
    end
    args.state.scene_storyline_queue << ""
    args.state.next_storyline = Kernel.tick_count
  end

  def set_scene args, scene
    args.state.current_scene = scene
    args.state.background = scene[:background] ||  'sprites/todo.png'
    args.state.scene_fade = scene[:fade] || 0
    args.state.scenes = (scene[:scenes] || []).reject { |s| !s }
    args.state.scene_render_override = scene[:render_override]
    args.state.storylines = (scene[:storylines] || []).reject { |s| !s }
    args.state.scene_changed_at = Kernel.tick_count
    if scene[:player]
      args.state.player = scene[:player]
    end
    args.state.inside_scene_hotspot = false
    args.state.inside_storyline_hotspot = false
    queue_storyline args, scene
  end

  def replay_storyline_rect
    [26, -1, 7, 4]
  end

  def labels_for_word word
    left_side_of_word = ""
    center_letter = ""
    right_side_of_word = ""

    if word[0] == "~"
      left_side_of_word = ""
      center_letter = word[1]
      right_side_of_word = word[2..-1]
    elsif word.length > 0
      left_side_of_word, right_side_of_word = word.split("~")
      center_letter = right_side_of_word[0]
      right_side_of_word = right_side_of_word[1..-1]
    end

    right_side_of_word = right_side_of_word.gsub("-", "")

    {
      left:   [29 - left_side_of_word.length * 4 - 1 * left_side_of_word.length, 2, left_side_of_word],
      center: [29, 2, center_letter, 255, 0, 0],
      right:  [34, 2, right_side_of_word]
    }
  end

  def render_scenes args, lowrez_sprites
    lowrez_sprites << args.state.scenes.flat_map do |hs|
      hotspot_square args, hs.x, hs.y, hs.w, hs.h
    end
  end

  def render_storylines args, lowrez_sprites
    lowrez_sprites << args.state.storylines.flat_map do |hs|
      hotspot_square args, hs.x, hs.y, hs.w, hs.h
    end
  end

  def adornments_alpha args, target_alpha = nil, minimum_alpha = nil
    return (minimum_alpha || 80) unless args.state.storyline_queue_empty_at
    target_alpha ||= 255
    target_alpha * args.state.storyline_queue_empty_at.ease(60)
  end

  def hotspot_square args, x, y, w, h
    if w >= 3 && h >= 3
      [
        [x + w.idiv(2) + 1, y, w.idiv(2), h, 'sprites/label-background.png', 0, adornments_alpha(args, 50), 23, 23, 23],
        [x, y, w.idiv(2), h, 'sprites/label-background.png', 0, adornments_alpha(args, 100), 223, 223, 223],
        [x + 1, y + 1, w - 2, h - 2, 'sprites/label-background.png', 0, adornments_alpha(args, 200), 40, 140, 40],
      ]
    else
      [
        [x, y, w, h, 'sprites/label-background.png', 0, adornments_alpha(args, 200), 0, 140, 0],
      ]
    end
  end

  def render_storyline_dialog args, lowrez_labels, lowrez_sprites
    return unless args.state.is_storyline_dialog_active
    return unless args.state.storyline_to_show
    labels = labels_for_word args.state.storyline_to_show
    if true # high rez version
      scale = 8.88
      offset = 45
      size = 25
      args.outputs.labels << [offset + labels[:left].x.-(1) * scale,
                              labels[:left].y * TINY_SCALE + 55,
                              labels[:left].text, size, 0, 0, 0, 0, 255,
                              'fonts/manaspc.ttf']
      center_text = labels[:center].text
      center_text = "|" if center_text == "$"
      args.outputs.labels << [offset + labels[:center].x * scale,
                              labels[:center].y * TINY_SCALE + 55,
                              center_text, size, 0, 255, 0, 0, 255,
                              'fonts/manaspc.ttf']
      args.outputs.labels << [offset + labels[:right].x * scale,
                              labels[:right].y * TINY_SCALE + 55,
                              labels[:right].text, size, 0, 0, 0, 0, 255,
                              'fonts/manaspc.ttf']
    else
      lowrez_labels << labels[:left]
      lowrez_labels << labels[:center]
      lowrez_labels << labels[:right]
    end
    args.state.is_storyline_dialog_active = true
    render_player args, lowrez_sprites
    lowrez_sprites <<  [0, 0, 64, 8, 'sprites/label-background.png']
  end

  def render_player args, lowrez_sprites
    lowrez_sprites << player_md_down(args, *args.state.player)
  end

  def render_adornments args, lowrez_sprites
    render_scenes args, lowrez_sprites
    render_storylines args, lowrez_sprites
    return if args.state.is_storyline_dialog_active
    lowrez_sprites << player_md_down(args, *args.state.player)
  end

  def global_alpha_percentage args, max_alpha = 255
    return 255 unless args.state.scene_changed_at
    return 255 unless args.state.scene_fade
    return 255 unless args.state.scene_fade > 0
    return max_alpha * args.state.scene_changed_at.ease(args.state.scene_fade)
  end

  def render_current_scene args, lowrez_sprites, lowrez_labels, lowrez_solids
    lowrez_sprites << [0, 0, 64, 64, args.state.background, 0, (global_alpha_percentage args)]
    if args.state.scene_render_override
      send args.state.scene_render_override, args, lowrez_sprites, lowrez_labels, lowrez_solids
    end
    storyline_to_show = args.state.storyline_to_show || ""
    render_adornments args, lowrez_sprites
    render_storyline_dialog args, lowrez_labels, lowrez_sprites

    if args.state.background == 'sprites/tribute-game-over.png'
      lowrez_sprites << [0, 0, 64, 11, 'sprites/label-background.png', 0, adornments_alpha(args, 200), 0, 0, 0]
      lowrez_labels << [9, 6, 'Return of', 255, 255, 255]
      lowrez_labels << [9, 1, ' Serenity', 255, 255, 255]
      if !args.state.ended
        args.gtk.stop_music
        args.outputs.sounds << 'sounds/music-loop.ogg'
        args.state.ended = true
      end
    end
  end

  def player_md_right args, x, y
    [x, y, 4, 11, 'sprites/player-right.png', 0, (global_alpha_percentage args)]
  end

  def player_md_left args, x, y
    [x, y, 4, 11, 'sprites/player-left.png', 0, (global_alpha_percentage args)]
  end

  def player_md_up args, x, y
    [x, y, 4, 11, 'sprites/player-up.png', 0, (global_alpha_percentage args)]
  end

  def player_md_down args, x, y
    [x, y, 4, 11, 'sprites/player-down.png', 0, (global_alpha_percentage args)]
  end

  def player_sm args, x, y
    [x, y, 3, 7, 'sprites/player-zoomed-out.png', 0, (global_alpha_percentage args)]
  end

  def player_xs args, x, y
    [x, y, 1, 4, 'sprites/player-zoomed-out.png', 0, (global_alpha_percentage args)]
  end

```

### Return Of Serenity - require.rb
```ruby
  # ./samples/99_genre_rpg_narrative/return_of_serenity/app/require.rb
  require 'app/lowrez_simulator.rb'
  require 'app/storyline_day_one.rb'
  require 'app/storyline_blinking_light.rb'
  require 'app/storyline_serenity_introduction.rb'
  require 'app/storyline_speed_of_light.rb'
  require 'app/storyline_serenity_alive.rb'
  require 'app/storyline_serenity_bio.rb'
  require 'app/storyline_anka.rb'
  require 'app/storyline_final_message.rb'
  require 'app/storyline_final_decision.rb'
  require 'app/storyline.rb'

```

### Return Of Serenity - storyline.rb
```ruby
  # ./samples/99_genre_rpg_narrative/return_of_serenity/app/storyline.rb
  def hotspot_top
    [4, 61, 56, 3]
  end

  def hotspot_bottom
    [4, 0, 56, 3]
  end

  def hotspot_top_right
    [62, 35, 3, 25]
  end

  def hotspot_bottom_right
    [62, 0, 3, 25]
  end

  def storyline_history_include? args, text
    args.state.storyline_history.any? { |s| s.gsub("-", "").gsub(" ", "").include? text.gsub("-", "").gsub(" ", "") }
  end

  def blinking_light_side_of_home_render args, lowrez_sprites, lowrez_labels, lowrez_solids
    lowrez_sprites << [48, 44, 5, 5, 'sprites/square.png', 0,  50 * (Kernel.tick_count % 50).fdiv(50), 0, 255, 0]
    lowrez_sprites << [49, 45, 3, 3, 'sprites/square.png', 0, 100 * (Kernel.tick_count % 50).fdiv(50), 0, 255, 0]
    lowrez_sprites << [50, 46, 1, 1, 'sprites/square.png', 0, 255 * (Kernel.tick_count % 50).fdiv(50), 0, 255, 0]
  end

  def blinking_light_mountain_pass_render args, lowrez_sprites, lowrez_labels, lowrez_solids
    lowrez_sprites << [18, 47, 5, 5, 'sprites/square.png', 0,  50 * (Kernel.tick_count % 50).fdiv(50), 0, 255, 0]
    lowrez_sprites << [19, 48, 3, 3, 'sprites/square.png', 0, 100 * (Kernel.tick_count % 50).fdiv(50), 0, 255, 0]
    lowrez_sprites << [20, 49, 1, 1, 'sprites/square.png', 0, 255 * (Kernel.tick_count % 50).fdiv(50), 0, 255, 0]
  end

  def blinking_light_path_to_observatory_render args, lowrez_sprites, lowrez_labels, lowrez_solids
    lowrez_sprites << [0, 26, 5, 5, 'sprites/square.png', 0,  50 * (Kernel.tick_count % 50).fdiv(50), 0, 255, 0]
    lowrez_sprites << [1, 27, 3, 3, 'sprites/square.png', 0, 100 * (Kernel.tick_count % 50).fdiv(50), 0, 255, 0]
    lowrez_sprites << [2, 28, 1, 1, 'sprites/square.png', 0, 255 * (Kernel.tick_count % 50).fdiv(50), 0, 255, 0]
  end

  def blinking_light_observatory_render args, lowrez_sprites, lowrez_labels, lowrez_solids
    lowrez_sprites << [23, 59, 5, 5, 'sprites/square.png', 0,  50 * (Kernel.tick_count % 50).fdiv(50), 0, 255, 0]
    lowrez_sprites << [24, 60, 3, 3, 'sprites/square.png', 0, 100 * (Kernel.tick_count % 50).fdiv(50), 0, 255, 0]
    lowrez_sprites << [25, 61, 1, 1, 'sprites/square.png', 0, 255 * (Kernel.tick_count % 50).fdiv(50), 0, 255, 0]
  end

  def blinking_light_inside_observatory_render args, lowrez_sprites, lowrez_labels, lowrez_solids
    lowrez_sprites << [30, 30, 5, 5, 'sprites/square.png', 0,  50 * (Kernel.tick_count % 50).fdiv(50), 0, 255, 0]
    lowrez_sprites << [31, 31, 3, 3, 'sprites/square.png', 0, 100 * (Kernel.tick_count % 50).fdiv(50), 0, 255, 0]
    lowrez_sprites << [32, 32, 1, 1, 'sprites/square.png', 0, 255 * (Kernel.tick_count % 50).fdiv(50), 0, 255, 0]
  end

  def decision_graph context_message, context_action, context_result_one, context_result_two, context_result_three = [], context_result_four = []
    result_one_scene, result_one_label, result_one_text = context_result_one
    result_two_scene, result_two_label, result_two_text = context_result_two
    result_three_scene, result_three_label, result_three_text = context_result_three
    result_four_scene, result_four_label, result_four_text = context_result_four

    top_level_hash = {
      background: 'sprites/decision.png',
      fade: 60,
      player: [20, 36],
      storylines: [ ],
      scenes: [ ]
    }

    confirmation_result_one_hash = {
      background: 'sprites/decision.png',
      scenes: [ ],
      storylines: [ ]
    }

    confirmation_result_two_hash = {
      background: 'sprites/decision.png',
      scenes: [ ],
      storylines: [ ]
    }

    confirmation_result_three_hash = {
      background: 'sprites/decision.png',
      scenes: [ ],
      storylines: [ ]
    }

    confirmation_result_four_hash = {
      background: 'sprites/decision.png',
      scenes: [ ],
      storylines: [ ]
    }

    top_level_hash[:storylines] << [ 5, 35, 4, 4, context_message]
    top_level_hash[:storylines] << [20, 35, 4, 4, context_action]

    confirmation_result_one_hash[:scenes]       << [20, 35, 4, 4, top_level_hash]
    confirmation_result_one_hash[:scenes]       << [60, 50, 4, 4, result_one_scene]
    confirmation_result_one_hash[:storylines]   << [40, 50, 4, 4, "#{result_one_label}: \"#{result_one_text}\""]
    confirmation_result_one_hash[:scenes]       << [40, 40, 4, 4, confirmation_result_four_hash] if result_four_scene
    confirmation_result_one_hash[:scenes]       << [40, 30, 4, 4, confirmation_result_three_hash] if result_three_scene
    confirmation_result_one_hash[:scenes]       << [40, 20, 4, 4, confirmation_result_two_hash]

    confirmation_result_two_hash[:scenes]       << [20, 35, 4, 4, top_level_hash]
    confirmation_result_two_hash[:scenes]       << [40, 50, 4, 4, confirmation_result_one_hash]
    confirmation_result_two_hash[:scenes]       << [40, 40, 4, 4, confirmation_result_four_hash] if result_four_scene
    confirmation_result_two_hash[:scenes]       << [40, 30, 4, 4, confirmation_result_three_hash] if result_three_scene
    confirmation_result_two_hash[:scenes]       << [60, 20, 4, 4, result_two_scene]
    confirmation_result_two_hash[:storylines]   << [40, 20, 4, 4, "#{result_two_label}: \"#{result_two_text}\""]

    confirmation_result_three_hash[:scenes]     << [20, 35, 4, 4, top_level_hash]
    confirmation_result_three_hash[:scenes]     << [40, 50, 4, 4, confirmation_result_one_hash]
    confirmation_result_three_hash[:scenes]     << [40, 40, 4, 4, confirmation_result_four_hash]
    confirmation_result_three_hash[:scenes]     << [60, 30, 4, 4, result_three_scene]
    confirmation_result_three_hash[:storylines] << [40, 30, 4, 4, "#{result_three_label}: \"#{result_three_text}\""]
    confirmation_result_three_hash[:scenes]     << [40, 20, 4, 4, confirmation_result_two_hash]

    confirmation_result_four_hash[:scenes]      << [20, 35, 4, 4, top_level_hash]
    confirmation_result_four_hash[:scenes]      << [40, 50, 4, 4, confirmation_result_one_hash]
    confirmation_result_four_hash[:scenes]      << [60, 40, 4, 4, result_four_scene]
    confirmation_result_four_hash[:storylines]  << [40, 40, 4, 4, "#{result_four_label}: \"#{result_four_text}\""]
    confirmation_result_four_hash[:scenes]      << [40, 30, 4, 4, confirmation_result_three_hash]
    confirmation_result_four_hash[:scenes]      << [40, 20, 4, 4, confirmation_result_two_hash]

    top_level_hash[:scenes]     << [40, 50, 4, 4, confirmation_result_one_hash]
    top_level_hash[:scenes]     << [40, 40, 4, 4, confirmation_result_four_hash] if result_four_scene
    top_level_hash[:scenes]     << [40, 30, 4, 4, confirmation_result_three_hash] if result_three_scene
    top_level_hash[:scenes]     << [40, 20, 4, 4, confirmation_result_two_hash]

    top_level_hash
  end

  def ship_control_hotspot offset_x, offset_y, a, b, c, d
    results = []
    results << [ 6 + offset_x, 0 + offset_y, 4, 4, a]  if a
    results << [ 1 + offset_x, 5 + offset_y, 4, 4, b]  if b
    results << [ 6 + offset_x, 5 + offset_y, 4, 4, c]  if c
    results << [ 11 + offset_x, 5 + offset_y, 4, 4, d] if d
    results
  end

  def reload_current_scene
    if $gtk.args.state.last_hotspot_scene
      set_scene $gtk.args, send($gtk.args.state.last_hotspot_scene, $gtk.args)
      tick $gtk.args
    elsif respond_to? :set_scene
      set_scene $gtk.args, (replied_to_serenity_alive_firmly $gtk.args)
      tick $gtk.args
    end
    $gtk.console.close
  end

```

### Return Of Serenity - storyline_anka.rb
```ruby
  # ./samples/99_genre_rpg_narrative/return_of_serenity/app/storyline_anka.rb
  def anka_inside_room args
    {
      background: 'sprites/inside-home.png',
      player: [34, 35],
      storylines: [
        [34, 34, 4, 4, "Ahhhh!!! Oh god, it was just- a nightmare."],
      ],
      scenes: [
        [32, -1, 8, 3, :anka_observatory]
      ]
    }
  end

  def anka_observatory args
    {
      background: 'sprites/inside-observatory.png',
      fade: 60,
      player: [51, 12],
      storylines: [
        [50, 10, 4, 4,   "Breathe, Hiro. Just see what's there... everything--- will- be okay."]
      ],
      scenes: [
        [30, 18, 5, 12, :anka_inside_mainframe]
      ],
      render_override: :blinking_light_inside_observatory_render
    }
  end

  def anka_inside_mainframe args
    {
      player: [32, 4],
      background: 'sprites/mainframe.png',
      fade: 60,
      storylines: [
        [22, 45, 17, 4, (anka_last_reply args)],
        [45, 45,  4, 4, (anka_current_reply args)],
      ],
      scenes: [
        [*hotspot_top_right, :reply_to_anka]
      ]
    }
  end

  def reply_to_anka args
    decision_graph anka_current_reply(args),
                   "Matthew's-- wife is doing-- well. What's-- even-- better-- is that he's-- a dad, and he didn't-- even-- know it. Should- I- leave- out the part about-- the crew- being-- in hibernation-- for 20-- years? They- should- enter-- statis-- on a high- note... Right?",
                   [:replied_with_whole_truth, "Whole-- Truth--", anka_reply_whole_truth],
                   [:replied_with_half_truth, "Half-- Truth--", anka_reply_half_truth]
  end

  def anka_last_reply args
    if args.state.scene_history.include? :replied_to_serenity_alive_firmly
      return "Buffer--: #{serenity_alive_firm_reply.quote}"
    else
      return "Buffer--: #{serenity_alive_sugarcoated_reply.quote}"
    end
  end

  def anka_reply_whole_truth
    "Matthew's wife is doing-- very-- well. In fact, she was pregnant. Matthew-- is a dad. He has a son. But, I need- all-- of-- you-- to brace-- yourselves. You've-- been in statis-- for 20 years. A lot has changed. Most of Earth's-- population--- didn't-- survive. Tell- Matthew-- that I'm-- sorry he didn't-- get to see- his- son grow- up."
  end

  def anka_reply_half_truth
    "Matthew's--- wife- is doing-- very-- well. In fact, she was pregnant. Matthew is a dad! It's a boy! Tell- Matthew-- congrats-- for me. Hope-- to see- all of you- soon."
  end

  def replied_with_whole_truth args
    {
      background: 'sprites/inside-observatory.png',
      fade: 60,
      player: [32, 21],
      scenes: [[60, 0, 4, 32, :replied_to_anka_back_home]],
      storylines: [
        [30, 18, 5, 12, "Buffer-- has been set to: #{anka_reply_whole_truth.quote}"],
        [30, 10, 5, 4, "I- hope- I- did the right- thing- by laying-- it all- out- there."],
      ]
    }
  end

  def replied_with_half_truth args
    {
      background: 'sprites/inside-observatory.png',
      fade: 60,
      player: [32, 21],
      scenes: [[60, 0, 4, 32, :replied_to_anka_back_home]],
      storylines: [
        [30, 18, 5, 12, "Buffer-- has been set to: #{anka_reply_half_truth.quote}"],
        [30, 10, 5, 4, "I- hope- I- did the right- thing- by not giving-- them- the whole- truth."],
      ]
    }
  end

  def anka_current_reply args
    if args.state.scene_history.include? :replied_to_serenity_alive_firmly
      return "Hello. This is, Aanka. Sasha-- is still- trying-- to gather-- her wits about-- her, given- the gravity--- of your- last- reply. Thank- you- for being-- honest, and thank- you- for the help- with the ship- diagnostics. I was able-- to retrieve-- all of the navigation--- information---- after-- the battery--- swap. We- are ready-- to head back to Earth. Before-- we go- back- into-- statis, Matthew--- wanted-- to know- how his- wife- is doing. Please- reply-- as soon- as you can. He's-- not going-- to get- into-- the statis-- chamber-- until-- he knows- his wife is okay."
    else
      return "Hello. This is, Aanka. Thank- you for the help- with the ship's-- diagnostics. I was able-- to retrieve-- all of the navigation--- information--- after-- the battery-- swap. I- know-- that- you didn't-- tell- the whole truth- about-- how far we are from- Earth. Don't-- worry. I understand-- why you did it. We- are ready-- to head back to Earth. Before-- we go- back- into-- statis, Matthew--- wanted-- to know- how his- wife- is doing. Please- reply-- as soon- as you can. He's-- not going-- to get- into-- the statis-- chamber-- until-- he knows- his wife is okay."
    end
  end

  def replied_to_anka_back_home args
    if args.state.scene_history.include? :replied_with_whole_truth
      return {
        fade: 60,
        background: 'sprites/inside-home.png',
        player: [34, 4],
        storylines: [
          [34, 4, 4, 4, "I- hope-- this pit in my stomach-- is gone-- by tomorrow---."],
        ],
        scenes: [
          [30, 38, 12, 13, :final_message_sad],
        ]
      }
    else
      return {
        fade: 60,
        background: 'sprites/inside-home.png',
        player: [34, 4],
        storylines: [
          [34, 4, 4, 4, "I- get the feeling-- I'm going-- to sleep real well tonight--."],
        ],
        scenes: [
          [30, 38, 12, 13, :final_message_happy],
        ]
      }
    end
  end

```

### Return Of Serenity - storyline_blinking_light.rb
```ruby
  # ./samples/99_genre_rpg_narrative/return_of_serenity/app/storyline_blinking_light.rb
  def the_blinking_light args
    {
      fade: 60,
      background: 'sprites/side-of-home.png',
      player: [16, 13],
      scenes: [
        [52, 24, 11, 5, :blinking_light_mountain_pass],
      ],
      render_override: :blinking_light_side_of_home_render
    }
  end

  def blinking_light_mountain_pass args
    {
      background: 'sprites/mountain-pass-zoomed-out.png',
      player: [4, 4],
      scenes: [
        [18, 47, 5, 5, :blinking_light_path_to_observatory]
      ],
      render_override: :blinking_light_mountain_pass_render
    }
  end

  def blinking_light_path_to_observatory args
    {
      background: 'sprites/path-to-observatory.png',
      player: [60, 4],
      scenes: [
        [0, 26, 5, 5, :blinking_light_observatory]
      ],
      render_override: :blinking_light_path_to_observatory_render
    }
  end

  def blinking_light_observatory args
    {
      background: 'sprites/observatory.png',
      player: [60, 2],
      scenes: [
        [28, 39, 4, 10, :blinking_light_inside_observatory]
      ],
      render_override: :blinking_light_observatory_render
    }
  end

  def blinking_light_inside_observatory args
    {
      background: 'sprites/inside-observatory.png',
      player: [60, 2],
      storylines: [
        [50, 2, 4, 8,   "That's weird. I thought- this- mainframe-- was broken--."]
      ],
      scenes: [
        [30, 18, 5, 12, :blinking_light_inside_mainframe]
      ],
      render_override: :blinking_light_inside_observatory_render
    }
  end

  def blinking_light_inside_mainframe args
    {
      background: 'sprites/mainframe.png',
      fade: 60,
      player: [30, 4],
      scenes: [
        [62, 32, 4, 32, :reply_to_introduction]
      ],
      storylines: [
        [43, 43,  8, 8, "\"Mission-- control--, your- main- comm-- channels-- seem-- to be down. My apologies-- for- using-- this low- level-- exploit--. What's-- going-- on down there? We are ready-- for reentry--.\" Message--- Timestamp---: 4- hours-- 23--- minutes-- ago--."],
        [30, 30,  4, 4, "There's-- a low- level-- message-- here... NANI.T.F?"],
        [14, 10, 24, 4, "Oh interesting---. This transistor--- needed-- to be activated--- for the- mainframe-- to work."],
        [14, 20, 24, 4, "What the heck activated--- this thing- though?"]
      ]
    }
  end

```

### Return Of Serenity - storyline_day_one.rb
```ruby
  # ./samples/99_genre_rpg_narrative/return_of_serenity/app/storyline_day_one.rb
  def day_one_beginning args
    {
      background: 'sprites/side-of-home.png',
      player: [16, 13],
      scenes: [
        [0, 0, 64, 2, :day_one_infront_of_home],
      ],
      storylines: [
        [35, 10, 6, 6,  "Man. Hard to believe- that today- is the 20th--- anniversary-- of The Impact."]
      ]
    }
  end

  def day_one_infront_of_home args
    {
      background: 'sprites/front-of-home.png',
      player: [56, 23],
      scenes: [
        [43, 34, 10, 16, :day_one_home],
        [62, 0,  3, 40, :day_one_beginning],
        [0, 4, 3, 20, :day_one_ceremony]
      ],
      storylines: [
        [40, 20, 4, 4, "It looks like everyone- is already- at the rememberance-- ceremony."],
      ]
    }
  end

  def day_one_home args
    {
      background: 'sprites/inside-home.png',
      player: [34, 3],
      scenes: [
        [28, 0, 12, 2, :day_one_infront_of_home]
      ],
      storylines: [
        [
          38, 4, 4, 4, "My mansion- in all its glory! Okay yea, it's just a shipping- container-. Apparently-, it's nothing- like the luxuries- of the 2040's. But it's- all we have- in- this day and age. And it'll suffice."
        ],
        [
          28, 7, 4, 7,
          "Ahhh. My reading- couch. It's so comfortable--."
        ],
        [
          38, 21, 4, 4,
          "I'm- lucky- to have a computer--. I'm- one of the few people- with- the skills to put this- thing to good use."
        ],
        [
          45, 37, 4, 8,
          "This corner- of my home- is always- warmer-. It's cause of the ref~lected-- light- from the solar-- panels--, just on the other- side- of this wall. It's hard- to believe- there was o~nce-- an unlimited- amount- of electricity--."
        ],
        [
          32, 40, 8, 10,
          "This isn't- a good time- to sleep. I- should probably- head to the ceremony-."
        ],
        [
          25, 21, 5, 12,
          "Fifteen-- years- of computer-- science-- notes, neatly-- organized. Compiler--- Theory--, Linear--- Algebra---, Game-- Development---... Every-- subject-- imaginable--."
        ]
      ]
    }
  end

  def day_one_ceremony args
    {
      background: 'sprites/tribute.png',
      player: [57, 21],
      scenes: [
        [62, 0, 2, 40, :day_one_infront_of_home],
        [0, 24, 2, 40, :day_one_infront_of_library]
      ],
      storylines: [
        [53, 12, 3,  8,  "It's- been twenty- years since The Impact. Twenty- years, since Halley's-- Comet-- set Earth's- blue- sky on fire."],
        [45, 12, 3,  8,  "The space mission- sent to prevent- Earth's- total- destruction--, was a success. Only- 99.9%------ of the world's- population-- died-- that day. Hey, it's- better-- than 100%---- of humanity-- dying."],
        [20, 12, 23, 4, "The monument--- reads:---- Here- stands- the tribute-- to Space- Mission-- Serenity--- and- its- crew. You- have- given-- humanity--- a second-- chance."],
        [15, 12, 3,  8, "Rest- in- peace--- Matthew----, Sasha----, Aanka----"],
      ]
    }
  end

  def day_one_infront_of_library args
    {
      background: 'sprites/outside-library.png',
      player: [57, 21],
      scenes: [
        [62, 0, 2, 40, :day_one_ceremony],
        [49, 39, 6, 9, :day_one_library]
      ],
      storylines: [
        [50, 20, 4, 8,  "Shipping- containers-- as far- as the eye- can see. It's- rather- beautiful-- if you ask me. Even- though-- this- view- represents-- all- that's-- left- of humanity-."]
      ]
    }
  end

  def day_one_library args
    {
      background: 'sprites/library.png',
      player: [27, 4],
      scenes: [
        [0, 0, 64, 2, :end_day_one_infront_of_library]
      ],
      storylines: [
        [28, 22, 8, 4,  "I grew- up- in this library. I've- read every- book- here. My favorites-- were- of course-- anything- computer-- related."],
        [6, 32, 10, 6, "My favorite-- area--- of the library. The Science-- Section."]
      ]
    }
  end

  def end_day_one_infront_of_library args
    {
      background: 'sprites/outside-library.png',
      player: [51, 33],
      scenes: [
        [49, 39, 6, 9, :day_one_library],
        [62, 0, 2, 40, :end_day_one_monument],
      ],
      storylines: [
        [50, 27, 4, 4, "It's getting late. Better get some sleep."]
      ]
    }
  end

  def end_day_one_monument args
    {
      background: 'sprites/tribute.png',
      player: [2, 36],
      scenes: [
        [62, 0, 2, 40, :end_day_one_infront_of_home],
      ],
      storylines: [
        [50, 27, 4, 4, "It's getting late. Better get some sleep."],
      ]
    }
  end

  def end_day_one_infront_of_home args
    {
      background: 'sprites/front-of-home.png',
      player: [1, 17],
      scenes: [
        [43, 34, 10, 16, :end_day_one_home],
      ],
      storylines: [
        [20, 10, 4, 4, "It's getting late. Better get some sleep."],
      ]
    }
  end

  def end_day_one_home args
    {
      background: 'sprites/inside-home.png',
      player: [34, 3],
      scenes: [
        [32, 40, 8, 10, :end_day_one_dream],
      ],
      storylines: [
        [38, 4, 4, 4, "It's getting late. Better get some sleep."],
      ]
    }
  end

  def end_day_one_dream args
    {
      background: 'sprites/dream.png',
      fade: 60,
      player: [4, 4],
      scenes: [
        [62, 0, 2, 64, :explaining_the_special_power]
      ],
      storylines: [
        [10, 10, 4, 4, "Why- does this- moment-- always- haunt- my dreams?"],
        [20, 10, 4, 4, "This kid- reads these computer--- science--- books- nonstop-. What's- wrong with him?"],
        [30, 10, 4, 4, "There- is nothing-- wrong- with him. This behavior-- should be encouraged---! In fact-, I think- he's- special---. Have- you seen- him use- a computer---? It's-- almost-- as if he can- speak-- to it."]
      ]
    }
  end

  def explaining_the_special_power args
    {
      fade: 60,
      background: 'sprites/inside-home.png',
      player: [32, 30],
      scenes: [
        [
          38, 21, 4, 4, :explaining_the_special_power_inside_computer
        ],
      ]
    }
  end

  def explaining_the_special_power_inside_computer args
    {
      background: 'sprites/pc.png',
      fade: 60,
      player: [34, 4],
      scenes: [
        [0, 62, 64, 3, :the_blinking_light]
      ],
      storylines: [
        [14, 20, 24, 4, "So... I have a special-- power--. I don't-- need a mouse-, keyboard--, or even-- a monitor--- to control-- a computer--."],
        [14, 25, 24, 4, "I only-- pretend-- to use peripherals---, so as not- to freak- anyone--- out."],
        [14, 30, 24, 4, "Inside-- this silicon--- Universe---, is the only-- place I- feel- at peace."],
        [14, 35, 24, 4, "It's-- the only-- place where I don't-- feel alone."]
      ]
    }
  end

```

### Return Of Serenity - storyline_final_decision.rb
```ruby
  # ./samples/99_genre_rpg_narrative/return_of_serenity/app/storyline_final_decision.rb
  def final_decision_side_of_home args
    {
      fade: 120,
      background: 'sprites/side-of-home.png',
      player: [16, 13],
      scenes: [
        [52, 24, 11, 5, :final_decision_mountain_pass],
      ],
      render_override: :blinking_light_side_of_home_render,
      storylines: [
        [28, 13, 8, 4,  "Man. Hard to believe- that today- is the 21st--- anniversary-- of The Impact. Serenity--- will- be- home- soon."]
      ]
    }
  end

  def final_decision_mountain_pass args
    {
      background: 'sprites/mountain-pass-zoomed-out.png',
      player: [4, 4],
      scenes: [
        [18, 47, 5, 5, :final_decision_path_to_observatory]
      ],
      render_override: :blinking_light_mountain_pass_render
    }
  end

  def final_decision_path_to_observatory args
    {
      background: 'sprites/path-to-observatory.png',
      player: [60, 4],
      scenes: [
        [0, 26, 5, 5, :final_decision_observatory]
      ],
      render_override: :blinking_light_path_to_observatory_render
    }
  end

  def final_decision_observatory args
    {
      background: 'sprites/observatory.png',
      player: [60, 2],
      scenes: [
        [28, 39, 4, 10, :final_decision_inside_observatory]
      ],
      render_override: :blinking_light_observatory_render
    }
  end

  def final_decision_inside_observatory args
    {
      background: 'sprites/inside-observatory.png',
      player: [60, 2],
      storylines: [],
      scenes: [
        [30, 18, 5, 12, :final_decision_inside_mainframe]
      ],
      render_override: :blinking_light_inside_observatory_render
    }
  end

  def final_decision_inside_mainframe args
    {
      player: [32, 4],
      background: 'sprites/mainframe.png',
      storylines: [],
      scenes: [
        [*hotspot_top, :final_decision_ship_status],
      ]
    }
  end

  def final_decision_ship_status args
    {
      background: 'sprites/serenity.png',
      fade: 60,
      player: [30, 10],
      scenes: [
        [*hotspot_top_right, :final_decision]
      ],
      storylines: [
        [30,  8, 4, 4, "????"],
        *final_decision_ship_status_shared(args)
      ]
    }
  end

  def final_decision args
    decision_graph  "Stasis-- Chambers--: UNDERPOWERED, Life- forms-- will be terminated---- unless-- equilibrium----- is reached.",
                    "I CAN'T DO THIS... But... If-- I-- don't--- bring-- the- chambers--- to- equilibrium-----, they all die...",
                    [:final_decision_game_over_noone, "Kill--- Everyone---", "DO--- NOTHING?"],
                    [:final_decision_game_over_matthew, "Kill--- Sasha---", "KILL--- SASHA?"],
                    [:final_decision_game_over_anka, "Kill--- Aanka---", "KILL--- AANKA?"],
                    [:final_decision_game_over_sasha, "Kill--- Matthew---", "KILL--- MATTHEW?"]
  end

  def final_decision_game_over_noone args
    {
      background: 'sprites/tribute-game-over.png',
      player: [53, 14],
      fade: 600
    }
  end

  def final_decision_game_over_matthew args
    {
      background: 'sprites/tribute-game-over.png',
      player: [53, 14],
      fade: 600
    }
  end

  def final_decision_game_over_anka args
    {
      background: 'sprites/tribute-game-over.png',
      player: [53, 14],
      fade: 600
    }
  end

  def final_decision_game_over_sasha args
    {
      background: 'sprites/tribute-game-over.png',
      player: [53, 14],
      fade: 600
    }
  end

  def final_decision_ship_status_shared args
    [
      *ship_control_hotspot(24, 22,
                             "Stasis-- Chambers--: UNDERPOWERED, Life- forms-- will be terminated---- unless-- equilibrium----- is reached. WHAT?! NO!",
                             "Matthew's--- Chamber--: UNDER-- THREAT-- OF-- TERMINATION. WHAT?! NO!",
                             "Aanka's--- Chamber--: UNDER-- THREAT-- OF-- TERMINATION.  WHAT?! NO!",
                             "Sasha's--- Chamber--: UNDER-- THREAT-- OF-- TERMINATION. WHAT?! NO!"),
    ]
  end

```

### Return Of Serenity - storyline_final_message.rb
```ruby
  # ./samples/99_genre_rpg_narrative/return_of_serenity/app/storyline_final_message.rb
  def final_message_sad args
    {
      fade: 60,
      background: 'sprites/inside-home.png',
      player: [34, 35],
      storylines: [
        [34, 34, 4, 4, "Another-- sleepless-- night..."],
      ],
      scenes: [
        [32, -1, 8, 3, :final_message_observatory]
      ]
    }
  end

  def final_message_happy args
    {
      fade: 60,
      background: 'sprites/inside-home.png',
      player: [34, 35],
      storylines: [
        [34, 34, 4, 4, "Oh man, I slept like rock!"],
      ],
      scenes: [
        [32, -1, 8, 3, :final_message_observatory]
      ]
    }
  end

  def final_message_side_of_home args
    {
      fade: 60,
      background: 'sprites/side-of-home.png',
      player: [16, 13],
      scenes: [
        [52, 24, 11, 5, :final_message_mountain_pass],
      ],
      render_override: :blinking_light_side_of_home_render
    }
  end

  def final_message_mountain_pass args
    {
      background: 'sprites/mountain-pass-zoomed-out.png',
      player: [4, 4],
      scenes: [
        [18, 47, 5, 5, :final_message_path_to_observatory],
      ],
      storylines: [
        [18, 13, 5, 5, "Hnnnnnnnggg. My legs-- are still sore- from yesterday."]
      ],
      render_override: :blinking_light_mountain_pass_render
    }
  end

  def final_message_path_to_observatory args
    {
      background: 'sprites/path-to-observatory.png',
      player: [60, 4],
      scenes: [
        [0, 26, 5, 5, :final_message_observatory]
      ],
      storylines: [
        [22, 20, 10, 10, "This spot--, on the mountain, right here, it's-- perfect. This- is where- I'll-- yeet-- the person-- who is playing-- this- prank- on me."]
      ],
      render_override: :blinking_light_path_to_observatory_render
    }
  end

  def final_message_observatory args
    if args.state.scene_history.include? :replied_with_whole_truth
      return {
        background: 'sprites/inside-observatory.png',
        fade: 60,
        player: [51, 12],
        storylines: [
          [50, 10, 4, 4, "Here-- we- go..."]
        ],
        scenes: [
          [30, 18, 5, 12, :final_message_inside_mainframe]
        ],
        render_override: :blinking_light_inside_observatory_render
      }
    else
      return {
        background: 'sprites/inside-observatory.png',
        fade: 60,
        player: [51, 12],
        storylines: [
          [50, 10, 4, 4, "I feel like I'm-- walking-- on sunshine!"]
        ],
        scenes: [
          [30, 18, 5, 12, :final_message_inside_mainframe]
        ],
        render_override: :blinking_light_inside_observatory_render
      }
    end
  end

  def final_message_inside_mainframe args
    {
      player: [32, 4],
      background: 'sprites/mainframe.png',
      fade: 60,
      scenes: [[45, 45,  4, 4, :final_message_check_ship_status]]
    }
  end

  def final_message_check_ship_status args
    {
      background: 'sprites/mainframe.png',
      storylines: [
        [45, 45, 4, 4, (final_message_current args)],
      ],
      scenes: [
        [*hotspot_top, :final_message_ship_status],
      ]
    }
  end

  def final_message_ship_status args
    {
      background: 'sprites/serenity.png',
      fade: 60,
      player: [30, 10],
      scenes: [
        [30, 50, 4, 4, :final_message_ship_status_reviewed]
      ],
      storylines: [
        [30,  8, 4, 4, "Let me make- sure- everything--- looks good. It'll-- give me peace- of mind."],
        *final_message_ship_status_shared(args)
      ]
    }
  end

  def final_message_ship_status_reviewed args
    {
      background: 'sprites/serenity.png',
      fade: 60,
      scenes: [
        [*hotspot_bottom, :final_message_summary]
      ],
      storylines: [
        [0, 62, 62, 3, "Whew. Everyone-- is in their- chambers. The engines-- are roaring-- and Serenity-- is coming-- home."],
      ]
    }
  end

  def final_message_ship_status_shared args
    [
      *ship_control_hotspot( 0, 50,
                             "Stasis-- Chambers--: Online, All chambers-- are powered. Battery--- Allocation---: 3--- of-- 3--.",
                             "Matthew's--- Chamber--: OCCUPIED----",
                             "Aanka's--- Chamber--: OCCUPIED----",
                             "Sasha's--- Chamber--: OCCUPIED----"),
      *ship_control_hotspot(12, 35,
                            "Life- Support--: Not-- Needed---",
                            "O2--- Production---: OFF---",
                            "CO2--- Scrubbers---: OFF---",
                            "H2O--- Production---: OFF---"),
      *ship_control_hotspot(24, 20,
                            "Navigation: Offline---",
                            "Sensor: OFF---",
                            "Heads- Up- Display: DAMAGED---",
                            "Arithmetic--- Unit: DAMAGED----"),
      *ship_control_hotspot(36, 35,
                            "COMM: Underpowered----",
                            "Text: ON---",
                            "Audio: SEGFAULT---",
                            "Video: DAMAGED---"),
      *ship_control_hotspot(48, 50,
                            "Engine: Online, Coordinates--- Set- for Earth. Battery--- Allocation---: 3--- of-- 3---",
                            "Engine I: ON---",
                            "Engine II: ON---",
                            "Engine III: ON---")
    ]
  end

  def final_message_last_reply args
    if args.state.scene_history.include? :replied_with_whole_truth
      return "Buffer--: #{anka_reply_whole_truth.quote}"
    else
      return "Buffer--: #{anka_reply_half_truth.quote}"
    end
  end

  def final_message_current args
    if args.state.scene_history.include? :replied_with_whole_truth
      return "Hey... It's-- me Sasha. Aanka-- is trying-- her best to comfort-- Matthew. This- is the first- time- I've-- ever-- seen-- Matthew-- cry. We'll-- probably-- be in stasis-- by the time you get this message--. Thank- you- again-- for all your help. I look forward-- to meeting-- you in person."
    else
      return "Hey! It's-- me Sasha! LOL! Aanka-- and Matthew-- are dancing-- around-- like- goofballs--! They- are both- so adorable! Only-- this- tiny-- little-- genius-- can make-- a battle-- hardened-- general--- put- on a tiara-- and dance- around-- like a fairy-- princess-- XD------ Anyways, we are heading-- back into-- the chambers--. I hope our welcome-- home- parade-- has fireworks!"
    end
  end

  def final_message_summary args
    if args.state.scene_history.include? :replied_with_whole_truth
      return {
        background: 'sprites/inside-observatory.png',
        fade: 60,
        player: [31, 11],
        scenes: [[60, 0, 4, 32, :final_decision_side_of_home]],
        storylines: [
          [30, 10, 5, 4, "I can't-- imagine-- what they are feeling-- right now. But at least- they- know everything---, and we can- concentrate-- on rebuilding--- this world-- right- off the bat. I can't-- wait to see the future-- they'll-- help- build."],
        ]
      }
    else
      return {
        background: 'sprites/inside-observatory.png',
        fade: 60,
        player: [31, 11],
        scenes: [[60, 0, 4, 32, :final_decision_side_of_home]],
        storylines: [
          [30, 10, 5, 4, "They all sounded-- so happy. I know- they'll-- be in for a tough- dose- of reality--- when they- arrive. But- at least- they'll-- be around-- all- of us. We'll-- help them- cope."],
        ]
      }
    end
  end

```

### Return Of Serenity - storyline_serenity_alive.rb
```ruby
  # ./samples/99_genre_rpg_narrative/return_of_serenity/app/storyline_serenity_alive.rb
  def serenity_alive_side_of_home args
    {
      fade: 60,
      background: 'sprites/side-of-home.png',
      player: [16, 13],
      scenes: [
        [52, 24, 11, 5, :serenity_alive_mountain_pass],
      ],
      render_override: :blinking_light_side_of_home_render
    }
  end

  def serenity_alive_mountain_pass args
    {
      background: 'sprites/mountain-pass-zoomed-out.png',
      player: [4, 4],
      scenes: [
        [18, 47, 5, 5, :serenity_alive_path_to_observatory],
      ],
      storylines: [
        [18, 13, 5, 5, "Hnnnnnnnggg. My legs-- are still sore- from yesterday."]
      ],
      render_override: :blinking_light_mountain_pass_render
    }
  end

  def serenity_alive_path_to_observatory args
    {
      background: 'sprites/path-to-observatory.png',
      player: [60, 4],
      scenes: [
        [0, 26, 5, 5, :serenity_alive_observatory]
      ],
      storylines: [
        [22, 20, 10, 10, "This spot--, on the mountain, right here, it's-- perfect. This- is where- I'll-- yeet-- the person-- who is playing-- this- prank- on me."]
      ],
      render_override: :blinking_light_path_to_observatory_render
    }
  end

  def serenity_alive_observatory args
    {
      background: 'sprites/observatory.png',
      player: [60, 2],
      scenes: [
        [28, 39, 4, 10, :serenity_alive_inside_observatory]
      ],
      render_override: :blinking_light_observatory_render
    }
  end

  def serenity_alive_inside_observatory args
    {
      background: 'sprites/inside-observatory.png',
      player: [60, 2],
      storylines: [],
      scenes: [
        [30, 18, 5, 12, :serenity_alive_inside_mainframe]
      ],
      render_override: :blinking_light_inside_observatory_render
    }
  end

  def serenity_alive_inside_mainframe args
    {
      background: 'sprites/mainframe.png',
      fade: 60,
      player: [30, 4],
      scenes: [
        [*hotspot_top, :serenity_alive_ship_status],
      ],
      storylines: [
        [22, 45, 17, 4, (serenity_alive_last_reply args)],
        [45, 45,  4, 4, (serenity_alive_current_message args)],
      ]
    }
  end

  def serenity_alive_ship_status args
    {
      background: 'sprites/serenity.png',
      fade: 60,
      player: [30, 10],
      scenes: [
        [30, 50, 4, 4, :serenity_alive_ship_status_reviewed]
      ],
      storylines: [
        [30,  8, 4, 4, "Serenity? THE--- Mission-- Serenity?! How is that possible? They- are supposed-- to be dead."],
        [30, 10, 4, 4, "I... can't-- believe-- it. I- can access-- Serenity's-- computer? I- guess my \"superpower----\" isn't limited-- by proximity-- to- a machine--."],
        *serenity_alive_shared_ship_status(args)
      ]
    }
  end

  def serenity_alive_ship_status_reviewed args
    {
      background: 'sprites/serenity.png',
      fade: 60,
      scenes: [
        [*hotspot_bottom, :serenity_alive_time_to_reply]
      ],
      storylines: [
        [0, 62, 62, 3, "Okay. Reviewing-- everything--, it looks- like- I- can- take- the batteries--- from the Stasis--- Chambers--- and- Engine--- to keep- the crew-- alive-- and-- their-- location--- pinpointed---."],
      ]
    }
  end

  def serenity_alive_time_to_reply args
    decision_graph serenity_alive_current_message(args),
                    "Okay... time to deliver the bad news...",
                    [:replied_to_serenity_alive_firmly, "Firm-- Reply", serenity_alive_firm_reply],
                    [:replied_to_serenity_alive_kindly, "Sugar-- Coated---- Reply", serenity_alive_sugarcoated_reply]
  end

  def serenity_alive_shared_ship_status args
    [
      *ship_control_hotspot( 0, 50,
                             "Stasis-- Chambers--: Online, All chambers-- are powered. Battery--- Allocation---: 3--- of-- 3--, Hmmm. They don't-- need this to be powered-- right- now. Everyone-- is awake.",
                             nil,
                             nil,
                             nil),
      *ship_control_hotspot(12, 35,
                            "Life- Support--: Offline, Unable--- to- Sustain-- Life. Battery--- Allocation---: 0--- of-- 3---, Okay. That is definitely---- not a good thing.",
                            nil,
                            nil,
                            nil),
      *ship_control_hotspot(24, 20,
                            "Navigation: Offline, Unable--- to- Calculate--- Location. Battery--- Allocation---: 0--- of-- 3---, Whelp. No wonder-- Sasha-- can't-- get- any-- readings. Their- Navigation--- is completely--- offline.",
                            nil,
                            nil,
                            nil),
      *ship_control_hotspot(36, 35,
                            "COMM: Underpowered----, Limited--- to- Text-- Based-- COMM. Battery--- Allocation---: 1--- of-- 3---, It's-- lucky- that- their- COMM---- system was able to survive-- twenty-- years--. Just- barely-- it seems.",
                            nil,
                            nil,
                            nil),
      *ship_control_hotspot(48, 50,
                            "Engine: Online, Full- Control-- Available. Battery--- Allocation---: 3--- of-- 3---, Hmmm. No point of having an engine-- online--, if you don't- know- where you're-- going.",
                            nil,
                            nil,
                            nil)
    ]
  end

  def serenity_alive_firm_reply
    "Serenity, you are at a distance-- farther-- than- Neptune. All- of the ship's-- systems-- are failing. Please- move the batteries---- from- the Stasis-- Chambers-- over- to- Life-- Support--. I also-- need- you to move-- the batteries---- from- the Engines--- to your Navigation---- System."
  end

  def serenity_alive_sugarcoated_reply
    "So... you- are- a teeny--- tiny--- bit--- farther-- from Earth- than you think. And you have a teeny--- tiny--- problem-- with your ship. Please-- move the batteries--- from the Stasis--- Chambers--- over to Life--- Support---. I also need you to move the batteries--- from the Engines--- to your- Navigation--- System. Don't-- worry-- Sasha. I'll-- get y'all-- home."
  end

  def replied_to_serenity_alive_firmly args
    {
      background: 'sprites/inside-observatory.png',
      fade: 60,
      player: [32, 21],
      scenes: [
        [*hotspot_bottom_right, :serenity_alive_path_from_observatory]
      ],
      storylines: [
        [30, 18, 5, 12, "Buffer-- has been set to: #{serenity_alive_firm_reply.quote}"],
        *serenity_alive_reply_completed_shared_hotspots(args),
      ]
    }
  end

  def replied_to_serenity_alive_kindly args
    {
      background: 'sprites/inside-observatory.png',
      fade: 60,
      player: [32, 21],
      scenes: [
        [*hotspot_bottom_right, :serenity_alive_path_from_observatory]
      ],
      storylines: [
        [30, 18, 5, 12, "Buffer-- has been set to: #{serenity_alive_sugarcoated_reply.quote}"],
        *serenity_alive_reply_completed_shared_hotspots(args),
      ]
    }
  end

  def serenity_alive_path_from_observatory args
    {
      fade: 60,
      background: 'sprites/path-to-observatory.png',
      player: [4, 21],
      scenes: [
        [*hotspot_bottom_right, :serenity_bio_infront_of_home]
      ],
      storylines: [
        [22, 20, 10, 10, "I'm not sure what's-- worse. Waiting-- for Sasha's-- reply. Or jumping-- off- from- right- here."]
      ]
    }
  end

  def serenity_alive_reply_completed_shared_hotspots args
    [
      [30, 10, 5, 4, "I guess it wasn't-- a joke- after-- all."],
      [40, 10, 5, 4, "I barely-- remember--- the- history----- of the crew."],
      [50, 10, 5, 4, "It probably--- wouldn't-- hurt- to- refresh-- my memory--."]
    ]
  end

  def serenity_alive_last_reply args
    if args.state.scene_history.include? :replied_to_introduction_seriously
      return "Buffer--: \"Hello, Who- is sending-- this message--?\""
    else
      return "Buffer--: \"New- phone. Who dis?\""
    end
  end

  def serenity_alive_current_message args
    if args.state.scene_history.include? :replied_to_introduction_seriously
      "This- is Sasha. The Serenity--- crew-- is out of hibernation---- and ready-- for Earth reentry--. But, it seems like we are having-- trouble-- with our Navigation---- systems. Please advise.".quote
    else
      "LOL! Thanks for the laugh. I needed that. This- is Sasha. The Serenity--- crew-- is out of hibernation---- and ready-- for Earth reentry--. But, it seems like we are having-- trouble-- with our Navigation---- systems. Can you help me out- babe?".quote
    end
  end

```

### Return Of Serenity - storyline_serenity_bio.rb
```ruby
  # ./samples/99_genre_rpg_narrative/return_of_serenity/app/storyline_serenity_bio.rb
  def serenity_bio_infront_of_home args
    {
      fade: 60,
      background: 'sprites/front-of-home.png',
      player: [54, 23],
      scenes: [
        [44, 34, 8, 14, :serenity_bio_inside_home],
        [0, 3, 3, 22, :serenity_bio_library]
      ]
    }
  end

  def serenity_bio_inside_home args
    {
      background: 'sprites/inside-home.png',
      player: [34, 4],
      storylines: [
        [34, 4, 4, 4, "I'm--- completely--- exhausted."],
      ],
      scenes: [
        [30, 38, 12, 13, :serenity_bio_restless_sleep],
        [32, 0, 8, 3, :serenity_bio_infront_of_home],
      ]
    }
  end

  def serenity_bio_restless_sleep args
    {
      fade: 60,
      background: 'sprites/inside-home.png',
      storylines: [
        [32, 38, 10, 13, "I can't-- seem to sleep. I know nothing-- about the- crew-. Maybe- I- should- go read- up- on- them."],
      ],
      scenes: [
        [32, 0, 8, 3, :serenity_bio_infront_of_home],
      ]
    }
  end

  def serenity_bio_library args
    {
      background: 'sprites/library.png',
      fade: 60,
      player: [30, 7],
      scenes: [
        [21, 35, 3, 18, :serenity_bio_book]
      ]
    }
  end

  def serenity_bio_book args
    {
      background: 'sprites/book.png',
      fade: 60,
      player: [6, 52],
      storylines: [
        [ 4, 50, 56, 4, "The Title-- Reads: Never-- Forget-- Mission-- Serenity---"],

        [ 4, 38,  8, 8, "Name: Matthew--- R. Sex: Male--- Age-- at-- Departure: 36-----"],
        [14, 38, 46, 8, "Tribute-- Text: Matthew graduated-- Magna-- Cum-- Laude-- from MIT--- with-- a- PHD---- in Aero-- Nautical--- Engineering. He was immensely--- competitive, and had an insatiable---- thirst- for aerial-- battle. From the age of twenty, he remained-- undefeated--- in the Israeli-- Air- Force- \"Blue Flag\" combat-- exercises. By the age of 29--- he had already-- risen through- the ranks, and became-- the Lieutenant--- General--- of Lufwaffe. Matthew-- volenteered-- to- pilot-- Mission-- Serenity. To- this day, his wife- and son- are pillars-- of strength- for us. Rest- in Peace- Matthew, we are sorry-- that- news of the pregancy-- never-- reached- you. Please forgive us."],

        [4,  26,  8, 8, "Name: Aanka--- P. Sex: Female--- Age-- at-- Departure: 9-----"],
        [14, 26, 46, 8, "Tribute-- Text: Aanka--- gratuated--- Magna-- Cum- Laude-- from MIT, at- the- age- of eight, with a- PHD---- in Astro-- Physics. Her-- IQ--- was over 390, the highest-- ever- recorded--- IQ-- in- human-- history. She changed- the landscape-- of Physics-- with her efforts- in- unravelling--- the mysteries--- of- Dark- Matter--. Anka discovered-- the threat- of Halley's-- Comet-- collision--- with Earth. She spear headed-- the global-- effort-- for Misson-- Serenity. Her- multilingual--- address-- to- the world-- brought- us all hope."],

        [4,  14,  8, 8, "Name: Sasha--- N. Sex: Female--- Age-- at-- Departure: 29-----"],
        [14, 14, 46, 8, "Tribute-- Text: Sasha gratuated-- Magna-- Cum- Laude-- from MIT--- with-- a- PHD---- in Computer---- Science----. She-- was-- brilliant--, strong- willed--, and-- a-- stunningly--- beautiful--- woman---. Sasha---- is- the- creator--- of the world's--- first- Ruby--- Quantum-- Machine---. After-- much- critical--- acclaim--, the Quantum-- Computer-- was placed in MIT's---- Museam-- next- to- Richard--- G. and Thomas--- K.'s---- Lisp-- Machine---. Her- engineering--- skills-- were-- paramount--- for Mission--- Serenity's--- success. Humanity-- misses-- you-- dearly,-- Sasha--. Life-- shines-- a dimmer-- light-- now- that- your- angelic- voice-- can never- be heard- again."],
      ],
      scenes: [
        [*hotspot_bottom, :serenity_bio_finally_to_bed]
      ]
    }
  end

  def serenity_bio_finally_to_bed args
    {
      fade: 60,
      background: 'sprites/inside-home.png',
      player: [35, 3],
      storylines: [
        [34, 4, 4, 4, "Maybe-- I'll-- be able-- to sleep- now..."],
      ],
      scenes: [
        [32, 38, 10, 13, :bad_dream],
      ]
    }
  end

  def bad_dream args
    {
      fade: 120,
      background: 'sprites/inside-home.png',
      player: [34, 35],
      storylines: [
        [34, 34, 4, 4, "Man. I did not- sleep- well- at all..."],
      ],
      scenes: [
        [32, -1, 8, 3, :bad_dream_observatory]
      ]
    }
  end

  def bad_dream_observatory args
    {
      background: 'sprites/inside-observatory.png',
      fade: 120,
      player: [51, 12],
      storylines: [
        [50, 10, 4, 4,   "Breathe, Hiro. Just see what's there... everything--- will- be okay."]
      ],
      scenes: [
        [30, 18, 5, 12, :bad_dream_inside_mainframe]
      ],
      render_override: :blinking_light_inside_observatory_render
    }
  end

  def bad_dream_inside_mainframe args
    {
      player: [32, 4],
      background: 'sprites/mainframe.png',
      fade: 120,
      storylines: [
        [22, 45, 17, 4, (bad_dream_last_reply args)],
      ],
      scenes: [
        [45, 45,  4, 4, :bad_dream_everyone_dead],
      ]
    }
  end

  def bad_dream_everyone_dead args
    {
      background: 'sprites/mainframe.png',
      storylines: [
        [22, 45, 17, 4, (bad_dream_last_reply args)],
        [45, 45,  4, 4, "Hi-- Hiro. This is Sasha. By the time- you get this- message, chances-- are we will- already-- be- dead. The batteries--- got- damaged-- during-- removal. And- we don't-- have enough-- power-- for Life-- Support. The air-- is- already--- starting-- to taste- bad. It... would- have been- nice... to go- on a date--- with- you-- when-- I- got- back- to Earth. Anyways, good-- bye-- Hiro-- XOXOXO----"],
        [22,  5, 17, 4, "Meh. Whatever, I didn't-- want to save them anyways. What- a pain- in my ass."],
      ],
      scenes: [
        [*hotspot_bottom, :anka_inside_room]
      ]
    }
  end

  def bad_dream_last_reply args
    if args.state.scene_history.include? :replied_to_serenity_alive_firmly
      return "Buffer--: #{serenity_alive_firm_reply.quote}"
    else
      return "Buffer--: #{serenity_alive_sugarcoated_reply.quote}"
    end
  end

```

### Return Of Serenity - storyline_serenity_introduction.rb
```ruby
  # ./samples/99_genre_rpg_narrative/return_of_serenity/app/storyline_serenity_introduction.rb
  # decision_graph "Message from Sasha",
  #                "I should reply.",
  #                [:replied_to_introduction_seriously,  "Reply Seriously", "Who is this?"],
  # [:replied_to_introduction_humorously, "Reply Humorously", "New phone who dis?"]
  def reply_to_introduction args
    decision_graph  "\"Mission-- control--, your- main- comm-- channels-- seem-- to be down. My apologies-- for- using-- this low- level-- exploit--. What's-- going-- on down there? We are ready-- for reentry--.\" Message--- Timestamp---: 4- hours-- 23--- minutes-- ago--.",
                    "Whoever-- pulled- off this exploit-- knows their stuff. I should reply--.",
                    [:replied_to_introduction_seriously,  "Serious Reply",  "Hello, Who- is sending-- this message--?"],
                    [:replied_to_introduction_humorously, "Humorous Reply", "New phone, who dis?"]
  end

  def replied_to_introduction_seriously args
    {
      background: 'sprites/inside-observatory.png',
      fade: 60,
      player: [32, 21],
      scenes: [
        *replied_to_introduction_shared_scenes(args)
      ],
      storylines: [
        [30, 18, 5, 12, "Buffer-- has been set to: \"Hello, Who- is sending-- this message--?\""],
        *replied_to_introduction_shared_storylines(args)
      ]
    }
  end

  def replied_to_introduction_humorously args
    {
      background: 'sprites/inside-observatory.png',
      fade: 60,
      player: [32, 21],
      scenes: [
        *replied_to_introduction_shared_scenes(args)
      ],
      storylines: [
        [30, 18, 5, 12, "Buffer-- has been set to: \"New- phone. Who dis?\""],
        *replied_to_introduction_shared_storylines(args)
      ]
    }
  end

  def replied_to_introduction_shared_storylines args
    [
      [30, 10, 5, 4, "It's-- going-- to take a while-- for this reply-- to make it's-- way back."],
      [40, 10, 5, 4, "4- hours-- to send a message-- at light speed?! How far away-- is the sender--?"],
      [50, 10, 5, 4, "I know- I've-- read about-- light- speed- travel-- before--. Maybe-- the library--- still has that- poster."]
    ]
  end

  def replied_to_introduction_shared_scenes args
    [[60, 0, 4, 32, :replied_to_introduction_observatory]]
  end

  def replied_to_introduction_observatory args
    {
      background: 'sprites/observatory.png',
      player: [28, 39],
      scenes: [
        [60, 0, 4, 32, :replied_to_introduction_path_to_observatory]
      ]
    }
  end

  def replied_to_introduction_path_to_observatory args
    {
      background: 'sprites/path-to-observatory.png',
      player: [0, 26],
      scenes: [
        [60, 0, 4, 20, :replied_to_introduction_mountain_pass]
      ],
    }
  end

  def replied_to_introduction_mountain_pass args
    {
      background: 'sprites/mountain-pass-zoomed-out.png',
      player: [21, 48],
      scenes: [
        [0, 0, 15, 4, :replied_to_introduction_side_of_home]
      ],
      storylines: [
        [15, 28, 5, 3, "At least I'm-- getting-- my- exercise-- in- for- today--."]
      ]
    }
  end

  def replied_to_introduction_side_of_home args
    {
      background: 'sprites/side-of-home.png',
      player: [58, 29],
      scenes: [
        [2, 0, 61, 2, :speed_of_light_front_of_home]
      ],
    }
  end

```

### Return Of Serenity - storyline_speed_of_light.rb
```ruby
  # ./samples/99_genre_rpg_narrative/return_of_serenity/app/storyline_speed_of_light.rb
  def speed_of_light_front_of_home args
    {
      background: 'sprites/front-of-home.png',
      player: [54, 23],
      scenes: [
        [44, 34, 8, 14, :speed_of_light_inside_home],
        [0, 3, 3, 22, :speed_of_light_outside_library]
      ]
    }
  end

  def speed_of_light_inside_home args
    {
      background: 'sprites/inside-home.png',
      player: [35, 4],
      storylines: [
        [30, 38, 12, 13, "Can't- sleep right now. I have to- find- out- why- it took- over-- 4- hours-- to receive-- that message."]
      ],
      scenes: [
        [32, 0, 8, 3, :speed_of_light_front_of_home],
      ]
    }
  end

  def speed_of_light_outside_library args
    {
      background: 'sprites/outside-library.png',
      player: [55, 19],
      scenes: [
        [49, 39, 6, 10, :speed_of_light_library],
        [61, 11, 3, 20, :speed_of_light_front_of_home]
      ]
    }
  end

  def speed_of_light_library args
    {
      background: 'sprites/library.png',
      player: [30, 7],
      scenes: [
        [3, 50, 10, 3, :speed_of_light_celestial_bodies_diagram]
      ]
    }
  end

  def speed_of_light_celestial_bodies_diagram args
    {
      background: 'sprites/planets.png',
      fade: 60,
      player: [30, 3],
      scenes: [
        [56 - 2, 10, 5, 5, :speed_of_light_distance_discovered]
      ],
      storylines: [
        [30, 2, 4, 4, "Here- it is! This is a diagram--- of the solar-- system--. It was printed-- over-- fifty-- years- ago. Geez-- that's-- old."],

        [ 0 - 2, 10, 5, 5, "The label- reads: Sun. The length- of the Astronomical-------- Unit-- (AU), is the distance-- from the Sun- to the Earth. Which is about 150--- million--- kilometers----."],
        [ 7 - 2, 10, 5, 5, "The label- reads: Mercury. Distance from Sun: 0.39AU------------ or- 3----- light-- minutes--."],
        [14 - 2, 10, 5, 5, "The label- reads: Venus. Distance from Sun: 0.72AU------------ or- 6----- light-- minutes--."],
        [21 - 2, 10, 5, 5, "The label- reads: Earth. Distance from Sun: 1.00AU------------ or- 8----- light-- minutes--."],
        [28 - 2, 10, 5, 5, "The label- reads: Mars. Distance from Sun: 1.52AU------------ or- 12----- light-- minutes--."],
        [35 - 2, 10, 5, 5, "The label- reads: Jupiter. Distance from Sun: 5.20AU------------ or- 45----- light-- minutes--."],
        [42 - 2, 10, 5, 5, "The label- reads: Saturn. Distance from Sun: 9.53AU------------ or- 79----- light-- minutes--."],
        [49 - 2, 10, 5, 5, "The label- reads: Uranus. Distance from Sun: 19.81AU------------ or- 159----- light-- minutes--."],
        # [56 - 2, 15, 4, 4, "The label- reads: Neptune. Distance from Sun: 30.05AU------------ or- 4.1----- light-- hours--."],
        [63 - 2, 10, 5, 5, "The label- reads: Pluto. Wait. WTF? Pluto-- isn't-- a planet."],
      ]
    }
  end

  def speed_of_light_distance_discovered args
    {
      background: 'sprites/planets.png',
      scenes: [
        [13, 0, 44, 3, :speed_of_light_end_of_day]
      ],
      storylines: [
        [ 0 - 2, 10, 5, 5, "The label- reads: Sun. The length- of the Astronomical-------- Unit-- (AU), is the distance-- from the Sun- to the Earth. Which is about 150--- million--- kilometers----."],
        [ 7 - 2, 10, 5, 5, "The label- reads: Mercury. Distance from Sun: 0.39AU------------ or- 3----- light-- minutes--."],
        [14 - 2, 10, 5, 5, "The label- reads: Venus. Distance from Sun: 0.72AU------------ or- 6----- light-- minutes--."],
        [21 - 2, 10, 5, 5, "The label- reads: Earth. Distance from Sun: 1.00AU------------ or- 8----- light-- minutes--."],
        [28 - 2, 10, 5, 5, "The label- reads: Mars. Distance from Sun: 1.52AU------------ or- 12----- light-- minutes--."],
        [35 - 2, 10, 5, 5, "The label- reads: Jupiter. Distance from Sun: 5.20AU------------ or- 45----- light-- minutes--."],
        [42 - 2, 10, 5, 5, "The label- reads: Saturn. Distance from Sun: 9.53AU------------ or- 79----- light-- minutes--."],
        [49 - 2, 10, 5, 5, "The label- reads: Uranus. Distance from Sun: 19.81AU------------ or- 159----- light-- minutes--."],
        [56 - 2, 10, 5, 5, "The label- reads: Neptune. Distance from Sun: 30.05AU------------ or- 4.1----- light-- hours--. What?! The message--- I received-- was from a source-- farther-- than-- Neptune?!"],
        [63 - 2, 10, 5, 5, "The label- reads: Pluto. Dista- Wait... Pluto-- isn't-- a planet. People-- thought- Pluto-- was a planet-- back- then?--"],
      ]
    }
  end

  def speed_of_light_end_of_day args
    {
      fade: 60,
      background: 'sprites/inside-home.png',
      player: [35, 0],
      storylines: [
        [35, 10, 4, 4, "Wonder-- what the reply-- will be. Who- the hell is contacting--- me from beyond-- Neptune? This- has to be some- kind- of- joke."]
      ],
      scenes: [
        [31, 38, 10, 12, :serenity_alive_side_of_home]
      ]
    }
  end

```
