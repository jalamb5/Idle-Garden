# frozen_string_literal: true

# Create new plants in garden
class Plant
  attr_accessor :x, :y, :w, :h, :age, :invalid, :path, :stage, :a

  attr_sprite

  # Growth Stages & Rates
  GROWTH_RATE = 0.1
  GROWING = 120
  FULL_GROWN = 200
  WITHER = 280 * 1.2
  WITHER_RATE = 0.4
  DEATH = 280 * 8
  SPRITES = { SEED: 'sprites/stages/0seed.png', GROWING: 'sprites/stages/1growing.png',
              FULL_GROWN: 'sprites/stages/2full_grown.png', WITHERED: 'sprites/stages/3withered.png' }.freeze
  STAGES = %w[seed growing full_grown withered].freeze

  def initialize(args)
    @x = args.inputs.mouse.x - 15
    @y = args.inputs.mouse.y - 15
    @w = 20
    @h = 20
    @age = 0
    @invalid = occupied(args, [@x, @y, @w, @h])
    @path = SPRITES[:SEED]
    @stage = STAGES[0]
    @a = 255
  end

  def grow
    @age += 1
    set_growth_stage
    if @age <= FULL_GROWN
      @w += GROWTH_RATE
      @h += GROWTH_RATE
    elsif @age >= WITHER && @age < DEATH
      @a -= WITHER_RATE
    elsif @age >= DEATH
      @invalid = true
    end
  end

  private

  def set_growth_stage
    if @age >= GROWING && @age < FULL_GROWN
      @path = SPRITES[:GROWING]
      @stage = STAGES[1]
    elsif @age >= FULL_GROWN && @age < WITHER
      @path = SPRITES[:FULL_GROWN]
      @stage = STAGES[2]
    elsif @age >= WITHER && @age < DEATH
      @path = SPRITES[:WITHERED]
      @stage = STAGES[3]
    end
  end

  # sets @invalid to false if not occupied, returns plant at location if occupied
  def occupied(args, new_plant)
    args.state.plants.each do |plant|
      next unless args.geometry.intersect_rect?(plant, new_plant)

      return plant
    end
    false
  end

  def serialize
    { w: @w, h: @h, x: @x, y: @y, age: @age, invalid: @invalid, path: @path, stage: @stage, a: @a }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
