# frozen_string_literal: true

# Create new plants in garden
class Plant
  attr_accessor :x, :y, :w, :h, :age, :invalid, :path, :stage, :a

  attr_sprite

  # Growth Stages & Rates
  GROWTH_RATE = 0.1
  GROWING = 200
  FULL_GROWN = 400
  READY_TO_HARVEST = 600
  WITHER = 1000
  WITHER_RATE = 0.4
  DEATH = 2200
  SPRITES = { SEED: 'sprites/stages/0seed.png', GROWING: 'sprites/stages/1growing.png', FULL_GROWN: 'sprites/stages/2full_grown.png',
              READY_TO_HARVEST: 'sprites/stages/3ready_to_harvest.png', WITHERED: 'sprites/stages/4withered.png' }.freeze
  STAGES = %w[seed growing full_grown ready_to_harvest withered].freeze

  def initialize(args, x_coord=args.inputs.mouse.x, y_coord=args.inputs.mouse.y)
    @x = x_coord - 15
    @y = y_coord - 15
    @w = 20
    @h = 20
    @age = 0
    @invalid = occupied(args, [@x, @y, @w, @h])
    @path = SPRITES[:SEED]
    @stage = STAGES[0]
    @a = 255 # TODO: Set a lower limit, plant is still harvestable when it is functionally invisible to the player
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

  # Harvest plant if correct stage
  def harvest(args, plant)
    if plant.stage == 'ready_to_harvest'
      args.state.harvested_plants += 1
      plant.invalid = true
    elsif plant.stage == 'withered'
      args.state.seeds += rand(10)
      plant.invalid = true
    end
  end

  private

  def set_growth_stage
    if @age >= GROWING && @age < FULL_GROWN
      @path = SPRITES[:GROWING]
      @stage = STAGES[1]
    elsif @age >= FULL_GROWN && @age < READY_TO_HARVEST
      @path = SPRITES[:FULL_GROWN]
      @stage = STAGES[2]
    elsif @age >= READY_TO_HARVEST && @age < WITHER
      @path = SPRITES[:READY_TO_HARVEST]
      @stage = STAGES[3]
    elsif @age >= WITHER && @age < DEATH
      @path = SPRITES[:WITHERED]
      @stage = STAGES[4]
    end
  end

  # sets @invalid to false if not occupied, attemps to harvest plant at location if occupied
  def occupied(args, new_plant)
    args.state.plants.each do |plant|
      next unless args.geometry.intersect_rect?(plant, new_plant)

      harvest(args, plant)
      return true
    end
    false
  end

  # DragonRuby required methods
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
