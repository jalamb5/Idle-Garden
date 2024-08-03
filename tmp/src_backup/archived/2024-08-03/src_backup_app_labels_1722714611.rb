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
    case key
    when :seed
      @value = args.state.game_state.seeds
    when :growing
      @value = args.state.game_state.plants.length
    when :harvested
      @value = args.state.game_state.harvested_plants
    when :cash
      prev = @value
      @value = args.state.game_state.cash
      flash(args, prev, @value)
    when :auto_harvesters
      @value = args.state.game_state.auto_harvesters.length
    when :auto_planters
      @value = args.state.game_state.auto_planters.length
    when :auto_sellers
      @value = args.state.game_state.auto_sellers.length
    when :score
      @value = args.state.game_state.score
    when :level
      @value = args.state.game_state.level.current_level
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
