### Checkboxes - main.rb
```ruby
  # ./samples/09_ui_controls/01_checkboxes/app/main.rb
  def tick args
    # use layout apis to position check boxes
    args.state.checkboxes ||= [
      args.layout.rect(row: 0, col: 0, w: 1, h: 1).merge(id: :option1, text: "Option 1", checked: false, changed_at: -120),
      args.layout.rect(row: 1, col: 0, w: 1, h: 1).merge(id: :option1, text: "Option 2", checked: false, changed_at: -120),
      args.layout.rect(row: 2, col: 0, w: 1, h: 1).merge(id: :option1, text: "Option 3", checked: false, changed_at: -120),
      args.layout.rect(row: 3, col: 0, w: 1, h: 1).merge(id: :option1, text: "Option 4", checked: false, changed_at: -120),
    ]

    # check for click of checkboxes
    if args.inputs.mouse.click
      args.state.checkboxes.find_all do |checkbox|
        args.inputs.mouse.inside_rect? checkbox
      end.each do |checkbox|
        # mark checkbox value
        checkbox.checked = !checkbox.checked
        # set the time the checkbox was changed
        checkbox.changed_at = Kernel.tick_count
      end
    end

    # render checkboxes
    args.outputs.primitives << args.state.checkboxes.map do |checkbox|
      # baseline prefab for checkbox
      prefab = {
        x: checkbox.x,
        y: checkbox.y,
        w: checkbox.w,
        h: checkbox.h
      }

      # label for checkbox centered vertically
      label = {
        x: checkbox.x + checkbox.w + 10,
        y: checkbox.y + checkbox.h / 2,
        text: checkbox.text,
        alignment_enum: 0,
        vertical_alignment_enum: 1
      }

      # rendering if checked or not
      if checkbox.checked
        # fade in
        a = 255 * args.easing.ease(checkbox.changed_at, Kernel.tick_count, 30, :smooth_stop_quint)

        [
          label,
          prefab.merge(primitive_marker: :solid, a: a),
          prefab.merge(primitive_marker: :border)
        ]
      else
        # fade out
        a = 255 * args.easing.ease(checkbox.changed_at, Kernel.tick_count, 30, :smooth_stop_quint, :flip)

        [
          label,
          prefab.merge(primitive_marker: :solid, a: a),
          prefab.merge(primitive_marker: :border)
        ]
      end
    end
  end

```

### Menu Navigation - main.rb
```ruby
  # ./samples/09_ui_controls/02_menu_navigation/app/main.rb
  class Game
    attr_gtk

    def tick
      defaults
      calc
      render
    end

    def render
      outputs.primitives << state.selection_point.merge(w: state.menu.button_w + 8,
                                                        h: state.menu.button_h + 8,
                                                        a: 128,
                                                        r: 0,
                                                        g: 200,
                                                        b: 100,
                                                        path: :solid,
                                                        anchor_x: 0.5,
                                                        anchor_y: 0.5)

      outputs.primitives << state.menu.buttons.map(&:primitives)
    end

    def calc_directional_input
      return if state.input_debounce.elapsed_time < 10
      return if !inputs.directional_vector
      state.input_debounce = Kernel.tick_count

      state.selected_button = Geometry::rect_navigate(
        rect: state.selected_button,
        rects: state.menu.buttons,
        left_right: inputs.left_right,
        up_down: inputs.up_down,
        wrap_x: true,
        wrap_y: true,
        using: lambda { |e| e.rect }
      )
    end

    def calc_mouse_input
      return if !inputs.mouse.moved
      hovered_button = state.menu.buttons.find { |b| Geometry::intersect_rect? inputs.mouse, b.rect }
      if hovered_button
        state.selected_button = hovered_button
      end
    end

    def calc
      target_point = state.selected_button.rect.center
      state.selection_point.x = state.selection_point.x.lerp(target_point.x, 0.25)
      state.selection_point.y = state.selection_point.y.lerp(target_point.y, 0.25)
      calc_directional_input
      calc_mouse_input
    end

    def defaults
      if !state.menu
        state.menu = {
          button_cell_w: 2,
          button_cell_h: 1,
        }
        state.menu.button_w = Layout::rect(w: 2).w
        state.menu.button_h = Layout::rect(h: 1).h
        state.menu.buttons = [
          menu_prefab(id: :item_1, text: "Item 1", row: 0, col: 0, w: state.menu.button_cell_w, h: state.menu.button_cell_h),
          menu_prefab(id: :item_2, text: "Item 2", row: 0, col: 2, w: state.menu.button_cell_w, h: state.menu.button_cell_h),
          menu_prefab(id: :item_3, text: "Item 3", row: 0, col: 4, w: state.menu.button_cell_w, h: state.menu.button_cell_h),
          menu_prefab(id: :item_4, text: "Item 4", row: 1, col: 0, w: state.menu.button_cell_w, h: state.menu.button_cell_h),
          menu_prefab(id: :item_5, text: "Item 5", row: 1, col: 2, w: state.menu.button_cell_w, h: state.menu.button_cell_h),
          menu_prefab(id: :item_6, text: "Item 6", row: 1, col: 4, w: state.menu.button_cell_w, h: state.menu.button_cell_h),
          menu_prefab(id: :item_7, text: "Item 7", row: 2, col: 0, w: state.menu.button_cell_w, h: state.menu.button_cell_h),
          menu_prefab(id: :item_8, text: "Item 8", row: 2, col: 2, w: state.menu.button_cell_w, h: state.menu.button_cell_h),
          menu_prefab(id: :item_9, text: "Item 9", row: 2, col: 4, w: state.menu.button_cell_w, h: state.menu.button_cell_h),
        ]
      end

      state.selected_button ||= state.menu.buttons.first
      state.selection_point ||= { x: state.selected_button.rect.center.x,
                                  y: state.selected_button.rect.center.y }
      state.input_debounce  ||= 0
    end

    def menu_prefab id:, text:, row:, col:, w:, h:;
      rect = Layout::rect(row: row, col: col, w: w, h: h)
      {
        id: id,
        row: row,
        col: col,
        text: text,
        rect: rect,
        primitives: [
          rect.merge(primitive_marker: :border),
          rect.center.merge(text: text, anchor_x: 0.5, anchor_y: 0.5)
        ]
      }
    end
  end

  def tick args
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

  def reset args
    $game = nil
  end

  $gtk.reset

```

### Radial Menu - main.rb
```ruby
  # ./samples/09_ui_controls/03_radial_menu/app/main.rb
  class Game
    attr_gtk

    def tick
      defaults
      calc
      render
    end

    def defaults
      state.menu_items = [
        { id: :item_1, text: "Item 1" },
        { id: :item_2, text: "Item 2" },
        { id: :item_3, text: "Item 3" },
        { id: :item_4, text: "Item 4" },
        { id: :item_5, text: "Item 5" },
        { id: :item_6, text: "Item 6" },
        { id: :item_7, text: "Item 7" },
        { id: :item_8, text: "Item 8" },
        { id: :item_9, text: "Item 9" },
      ]

      state.menu_status     ||= :hidden
      state.menu_radius     ||= 200
      state.menu_status_at  ||= -1000
    end

    def calc
      state.menu_items.each_with_index do |item, i|
        item.menu_angle = 90 + (360 / state.menu_items.length) * i
        item.menu_angle_range = 360 / state.menu_items.length - 10
      end

      state.menu_items.each do |item|
        item.rect = Geometry.rect_props x: 640 + item.menu_angle.vector_x * state.menu_radius - 50,
                                        y: 360 + item.menu_angle.vector_y * state.menu_radius - 25,
                                        w: 100,
                                        h: 50

        item.circle = { x: item.rect.x + item.rect.w / 2, y: item.rect.y + item.rect.h / 2, radius: item.rect.w / 2 }
      end

      show_menu_requested = false
      if state.menu_status == :hidden
        show_menu_requested = true if inputs.controller_one.key_down.a
        show_menu_requested = true if inputs.mouse.click
      end

      hide_menu_requested = false
      if state.menu_status == :shown
        hide_menu_requested = true if inputs.controller_one.key_down.b
        hide_menu_requested = true if inputs.mouse.click && !state.hovered_menu_item
      end

      if state.menu_status == :shown && state.hovered_menu_item && (inputs.mouse.click || inputs.controller_one.key_down.a)
        GTK.notify! "You selected #{state.hovered_menu_item[:text]}"
      elsif show_menu_requested
        state.menu_status = :shown
        state.menu_status_at = Kernel.tick_count
      elsif hide_menu_requested
        state.menu_status = :hidden
        state.menu_status_at = Kernel.tick_count
      end

      state.hovered_menu_item = state.menu_items.find { |item| Geometry.point_inside_circle? inputs.mouse, item.circle }

      if inputs.controller_one.active && inputs.controller_one.left_analog_active?(threshold_perc: 0.5)
        state.hovered_menu_item = state.menu_items.find do |item|
          Geometry.angle_within_range? inputs.controller_one.left_analog_angle, item.menu_angle, item.menu_angle_range
        end
      end
    end

    def menu_prefab item, perc
      dx = item.rect.center.x - 640
      x = 640 + dx * perc
      dy = item.rect.center.y - 360
      y = 360 + dy * perc
      Geometry.rect_props item.rect.merge x: x - item.rect.w / 2, y: y - item.rect.h / 2
    end

    def ring_prefab x_center, y_center, radius, precision:, color: nil
      color ||= { r: 0, g: 0, b: 0, a: 255 }
      pi = Math::PI
      lines = []

      precision.map do |i|
        theta = 2.0 * pi * i / precision
        next_theta = 2.0 * pi * (i + 1) / precision

        {
          x: x_center + radius * theta.cos_r,
          y: y_center + radius * theta.sin_r,
          x2: x_center + radius * next_theta.cos_r,
          y2: y_center + radius * next_theta.sin_r,
          **color
        }
      end
    end

    def circle_prefab x_center, y_center, radius, precision:, color: nil
      color ||= { r: 0, g: 0, b: 0, a: 255 }
      pi = Math::PI
      lines = []

      # Indie/Pro Only (uses triangles)
      precision.map do |i|
        theta = 2.0 * pi * i / precision
        next_theta = 2.0 * pi * (i + 1) / precision

        {
          x:  x_center + radius * theta.cos_r,
          y:  y_center + radius * theta.sin_r,
          x2: x_center + radius * next_theta.cos_r,
          y2: y_center + radius * next_theta.sin_r,
          y3: y_center,
          x3: x_center,
          source_x:  0,
          source_y:  0,
          source_x2: 0,
          source_y2: radius,
          source_x3: radius,
          source_y3: 0,
          path:      :solid,
          **color,
        }
      end
    end

    def render
      outputs.debug.watch "Controller"
      outputs.debug.watch pretty_format(inputs.controller_one.to_h)

      outputs.debug.watch "Mouse"
      outputs.debug.watch pretty_format(inputs.mouse.to_h)

      # outputs.debug.watch "Mouse"
      # outputs.debug.watch pretty_format(inputs.mouse)
      outputs.primitives << { x: 640, y: 360, w: 10, h: 10, path: :solid, r: 128, g: 0, b: 0, a: 128, anchor_x: 0.5, anchor_y: 0.5 }

      if state.menu_status == :shown
        perc = Easing.ease(state.menu_status_at, Kernel.tick_count, 30, :smooth_stop_quart)
      else
        perc = Easing.ease(state.menu_status_at, Kernel.tick_count, 30, :smooth_stop_quart, :flip)
      end

      outputs.primitives << state.menu_items.map do |item|
        a = 255 * perc
        color = { r: 128, g: 128, b: 128, a: a }
        if state.hovered_menu_item == item
          color = { r: 80, g: 128, b: 80, a: a }
        end

        menu = menu_prefab(item, perc)

        if state.menu_status == :shown
          ring = ring_prefab(menu.center.x, menu.center.y, item.circle.radius, precision: 30, color: color.merge(a: 128))
          circle = circle_prefab(menu.center.x, menu.center.y, item.circle.radius, precision: 30, color: color.merge(a: 128))
        end

        [
          ring,
          circle,
          menu.merge(path: :solid, **color),
          menu.center.merge(text: item.text, a: a, anchor_x: 0.5, anchor_y: 0.5)
        ]
      end
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

  GTK.reset

```

### Scroll View - main.rb
```ruby
  # ./samples/09_ui_controls/03_scroll_view/app/main.rb
  class ScrollView
    attr_gtk

    attr :y_offset, :rect, :clicked_items, :target_y_offset

    def initialize row:, col:, w:, h:;
      @items = []
      @clicked_items = []
      @y_offset = 0
      @scroll_view_dy = 0
      @rect = Layout.rect row: row,
                          col: col,
                          w: w,
                          h: h,
                          include_row_gutter: true,
                          include_col_gutter: true
      @primitives = []
    end

    def add_item prefab
      raise "prefab must be a Hash" unless prefab.is_a? Hash
      @items << prefab
    end

    def content_height
      lowest_item = @items.min_by { |primitive| primitive.y } || { x: 0, y: 0 }
      h = @rect.h

      if lowest_item
        h -= lowest_item.y - Layout.gutter
      end

      h
    end

    def y_offset_bottom_limit
      -80
    end

    def y_offset_top_limit
      content_height - @rect.h + @rect.y + 80
    end

    def tick_inputs
      @clicked_items = []

      if inputs.mouse.down
        @last_mouse_held_y = inputs.mouse.y
        @last_mouse_held_y_diff = 0
      elsif inputs.mouse.held
        @last_mouse_held_y ||= inputs.mouse.y
        @last_mouse_held_y_diff ||= 0
        @last_mouse_held_y_diff = inputs.mouse.y - @last_mouse_held_y
        @last_mouse_held_y = inputs.mouse.y
      end

      if inputs.mouse.down
        @mouse_down_at = Kernel.tick_count
        @mouse_down_y = inputs.mouse.y
        if @scroll_view_dy.abs < 7
          @maybe_click = true
        else
          @maybe_click = false
        end

        @scroll_view_dy = 0
      elsif inputs.mouse.held
        @target_y_offset = @y_offset + (inputs.mouse.y - @mouse_down_y) * 2
        @mouse_down_y = inputs.mouse.y
      elsif inputs.mouse.up
        @target_y_offset = nil
        @mouse_up_at = Kernel.tick_count
        @mouse_up_y = inputs.mouse.y

        if @maybe_click && (@last_mouse_held_y_diff).abs <= 1 && (@mouse_down_at - @mouse_up_at).abs < 12
          if inputs.mouse.y - 20 > @rect.y && inputs.mouse.y < (@rect.y + @rect.h - 20)
            @clicked_items = offset_items.reject { |primitive| !primitive.w || !primitive.h }
                                         .find_all { |primitive| inputs.mouse.inside_rect? primitive }
          end
        else
          @scroll_view_dy += @last_mouse_held_y_diff
        end
        @mouse_down_at = nil
        @mouse_up_at = nil
      end

      if inputs.keyboard.key_down.page_down
        if @scroll_view_dy >= 0
          @scroll_view_dy += 5
        else
          @scroll_view_dy = @scroll_view_dy.lerp(0, 1)
        end
      elsif inputs.keyboard.key_down.page_up
        if @scroll_view_dy <= 0
          @scroll_view_dy -= 5
        else
          @scroll_view_dy = @scroll_view_dy.lerp(0, 1)
        end
      end

      if inputs.mouse.wheel
        if inputs.mouse.wheel.inverted
          @scroll_view_dy -= inputs.mouse.wheel.y
        else
          @scroll_view_dy += inputs.mouse.wheel.y
        end
      end

    end

    def tick
      if @target_y_offset
        if @target_y_offset < y_offset_bottom_limit
          @y_offset = @y_offset.lerp @target_y_offset, 0.05
        elsif @target_y_offset > y_offset_top_limit
          @y_offset = @y_offset.lerp @target_y_offset, 0.05
        else
          @y_offset = @y_offset.lerp @target_y_offset, 0.5
        end
        @target_y_offset = nil if @y_offset.round == @target_y_offset.round
        @scroll_view_dy = 0
      end

      tick_inputs

      @y_offset += @scroll_view_dy

      if @y_offset < 0
        if inputs.mouse.held
          # if @y_offset < -80
          #   @y_offset = -80
          # end
        else
          @y_offset = @y_offset.lerp(0, 0.2)
        end
      end

      if content_height <= (@rect.h - @rect.y)
        @y_offset = 0
        @scroll_view_dy = 0
      elsif @y_offset > content_height - @rect.h + @rect.y
        if inputs.mouse.held
          # if @y_offset > (content_height - @rect.h + @rect.y) + 80
          #   @y_offset = (content_height - @rect.h + @rect.y) + 80
          # end
        else
          @y_offset = @y_offset.lerp(content_height - @rect.h + @rect.y, 0.2)
        end
      end
      @scroll_view_dy *= 0.95
      @scroll_view_dy = @scroll_view_dy.round(2)
    end

    def items
      @items
    end

    def offset_items
      @items.map { |primitive| primitive.merge(y: primitive.y + @y_offset) }
    end

    def prefab
      outputs[:scroll_view].w = Grid.w
      outputs[:scroll_view].h = Grid.h
      outputs[:scroll_view].background_color = [0, 0, 0, 0]
      outputs[:scroll_view].transient!

      outputs[:scroll_view_content].w = Grid.w
      outputs[:scroll_view_content].h = Grid.h
      outputs[:scroll_view_content].background_color = [0, 0, 0, 0]
      outputs[:scroll_view_content].transient!

      outputs[:scroll_view_content].primitives << offset_items

      outputs[:scroll_view].primitives << {
        x: @rect.x,
        y: @rect.y,
        w: @rect.w,
        h: @rect.h,
        source_x: @rect.x,
        source_y: @rect.y,
        source_w: @rect.w,
        source_h: @rect.h,
        path: :scroll_view_content
      }

      outputs[:scroll_view].primitives << [
        { x: @rect.x,
          y: @rect.y,
          w: @rect.w,
          h: @rect.h,
          primitive_marker: :border,
          r: 128,
          g: 128,
          b: 128 },
      ]

      { x: 0,
        y: 0,
        w: Grid.w,
        h: Grid.h,
        path: :scroll_view }
    end
  end

  class Game
    attr_gtk

    attr :scroll_view

    def initialize
      @scroll_view = ScrollView.new row: 2, col: 0, w: 12, h: 20
    end

    def defaults
      state.scroll_view_dy             ||= 0
      state.scroll_view_offset_y       ||= 0
    end

    def calc
      if Kernel.tick_count == 0
        80.times do |i|
          @scroll_view.add_item Layout.rect(row: 2 + i * 2, col: 0, w: 2, h: 2).merge(id: "item_#{i}_square_1".to_sym, path: :solid, r: 32 + i * 2, g: 32, b: 32)
          @scroll_view.add_item Layout.rect(row: 2 + i * 2, col: 0, w: 2, h: 2).center.merge(text: "item #{i}", anchor_x: 0.5, anchor_y: 0.5, r: 255, g: 255, b: 255)
          @scroll_view.add_item Layout.rect(row: 2 + i * 2, col: 2, w: 2, h: 2).merge(id: "item_#{i}_square_2".to_sym, path: :solid, r: 64 + i * 2, g: 64, b: 64)
        end
      end

      @scroll_view.args = args
      @scroll_view.tick

      if @scroll_view.clicked_items.length > 0
        puts @scroll_view.clicked_items
      end
    end

    def render
      outputs.primitives << @scroll_view.prefab
    end

    def tick
      defaults
      calc
      render
    end
  end

  def tick args
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

  def reset args
    $game = nil
  end

  GTK.reset

```

### Accessiblity For The Blind - main.rb
```ruby
  # ./samples/09_ui_controls/04_accessiblity_for_the_blind/app/main.rb
  def tick args
    # create three buttons
    args.state.button_1 ||= { x: 0, y: 640, w: 100, h: 50 }
    args.state.button_1_label ||= { x: 50,
                                    y: 665,
                                    text: "button 1",
                                    anchor_x: 0.5,
                                    anchor_y: 0.5 }

    args.state.button_2 ||= { x: 104, y: 640, w: 100, h: 50 }
    args.state.button_2_label ||= { x: 154,
                                    y: 665,
                                    text: "button 2",
                                    anchor_x: 0.5,
                                    anchor_y: 0.5 }

    args.state.button_3 ||= { x: 208, y: 640, w: 100, h: 50 }
    args.state.button_3_label ||= { x: 258,
                                    y: 665,
                                    text: "button 3",
                                    anchor_x: 0.5,
                                    anchor_y: 0.5 }

    # create a label
    args.state.label_hello_world ||= { x: 640,
                                       y: 360,
                                       text: "hello world",
                                       anchor_x: 0.5,
                                       anchor_y: 0.5 }

    args.outputs.borders << args.state.button_1
    args.outputs.labels  << args.state.button_1_label

    args.outputs.borders << args.state.button_2
    args.outputs.labels  << args.state.button_2_label

    args.outputs.borders << args.state.button_3
    args.outputs.labels  << args.state.button_3_label

    args.outputs.labels  << args.state.label_hello_world

    # args.outputs.a11y is cleared every tick, internally the key
    # of the dictionary value is used to reference the interactable element.
    # the key can be a symbol or a string (everything get's converted to strings
    # beind the scenes)

    # =======================================
    # from the Console run $gtk.a11y_enable!
    # ctrl+r will disable a11y (or you can run $gtk.a11y_disable! in the console)
    # =======================================

    # with the a11y emulation enabled, you can only use left arrow, right arrow, and enter
    # when you press enter, DR converts the location to a mouse click
    args.outputs.a11y[:button_1] = {
      a11y_text: "button 1",
      a11y_trait: :button,
      x: args.state.button_1.x,
      y: args.state.button_1.y,
      w: args.state.button_1.w,
      h: args.state.button_1.h
    }

    args.outputs.a11y[:button_2] = {
      a11y_text: "button 2",
      a11y_trait: :button,
      x: args.state.button_2.x,
      y: args.state.button_2.y,
      w: args.state.button_2.w,
      h: args.state.button_2.h
    }

    args.outputs.a11y[:button_3] = {
      a11y_text: "button 3",
      a11y_trait: :button,
      x: args.state.button_3.x,
      y: args.state.button_3.y,
      w: args.state.button_3.w,
      h: args.state.button_3.h
    }

    args.outputs.a11y[:label_hello] = {
      a11y_text: "hello world",
      a11y_trait: :label,
      x: args.state.label_hello_world.x,
      y: args.state.label_hello_world.y,
      anchor_x: 0.5,
      anchor_y: 0.5,
    }

    # flash a notification for each respective button
    if args.inputs.mouse.click && args.inputs.mouse.inside_rect?(args.state.button_1)
      GTK.notify_extended! message: "Button 1 clicked", a: 255
      # you can use a11y to speak information
      args.outputs.a11y["notify button clicked"] = {
        a11y_text: "button 1 clicked",
        a11y_trait: :notification
      }
    end

    if args.inputs.mouse.click && args.inputs.mouse.inside_rect?(args.state.button_2)
      GTK.notify_extended! message: "Button 2 clicked", a: 255
    end

    if args.inputs.mouse.click && args.inputs.mouse.inside_rect?(args.state.button_3)
      GTK.notify_extended! message: "Button 3 clicked", a: 255
      # you can also use a11y to redirect focus to another control
      args.outputs.a11y["notify button clicked"] = {
        a11y_trait: :notification,
        a11y_notification_target: :label_hello
      }
    end
  end

  $gtk.reset

```
