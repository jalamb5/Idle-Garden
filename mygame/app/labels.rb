# frozen_string_literal: true

# Create labels to display information
class Labels
  attr_accessor :x, :y, :text, :value, :size_px, :r, :g, :b, :a

  def initialize(x_coord, y_coord, text, value, size_px = 22, rgba = [0, 0, 0, 255])
    @x = x_coord
    @y = y_coord
    @text = text
    @value = value
    @size_px = size_px
    @r, @g, @b, @a = rgba
    @cooldown = 0
  end

  def display(args)
    args.outputs.labels << { x: @x, y: @y, text: "#{@text} #{@value}", size_px: @size_px, r: @r, g: @g, b: @b, a: @a }
  end

  def update(key, args)
    prev = @value
    case key
    when :seed
      @value = args.state.game_state.seeds
      flash(args, prev, @value)
    when :growing
      @value = args.state.game_state.plants.length
      flash(args, prev, @value)
    when :harvested
      @value = args.state.game_state.harvested_plants
      flash(args, prev, @value)
    when :cash
      @value = args.state.game_state.cash
      flash(args, prev, @value)
    when :auto_harvesters
      @value = args.state.game_state.auto_harvesters.length
      flash(args, prev, @value)
    when :auto_planters
      @value = args.state.game_state.auto_planters.length
      flash(args, prev, @value)
    when :auto_sellers
      @value = args.state.game_state.auto_sellers.length
      flash(args, prev, @value)
    when :score
      @value = args.state.game_state.score
      flash(args, prev, @value)
    when :level
      @value = args.state.game_state.level.current_level
      flash(args, prev, @value)
    end
  end

  private

  def flash(args, prev, value)
    @cooldown = 50 if prev != value

    return if @cooldown.zero?

    args.outputs.solids << { x: @x, y: @y - 25, w: 180, h: 20, r: 255, g: 255, b: 51, a: @cooldown }
    @cooldown -= 1
  end

  # DragonRuby required methods
  def serialize
    { x: @x, y: @y, text: @text, value: @value, size_px: @size_px }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
