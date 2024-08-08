# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/spritesheet.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Create new plants in garden
class Plant
  attr_accessor :x, :y, :w, :h, :age, :invalid, :stage, :a, :frame, :spritesheet, :sprite

  attr_sprite

  # Growth Stages & Rates
  GROWTH_RATE = 0.1
  GROWING = 2000
  FULL_GROWN = 4000
  READY_TO_HARVEST = 6000
  WITHER = 8000
  WITHER_RATE = 0.2
  DEATH = 10_000
  STAGES = { SEED: (0..13), GROWING: (14..25), FULL_GROWN: (26..29), READY_TO_HARVEST: (30..33),
             WITHERED: (34..55) }.freeze

  def initialize(args, spritesheet, x_coord = args.inputs.mouse.x, y_coord = args.inputs.mouse.y)
    @x = x_coord - 25
    @y = y_coord - 10
    @w = 64
    @h = 64
    @age = 0
    @invalid = occupied(args, [@x, @y, @w, @h])
    @stage = :SEED
    @a = 255
    @frame = 0

    @spritesheet = spritesheet
    @sprite = update_sprite
  end

  def update_sprite
    @sprite = @spritesheet.get(@frame, @x, @y, @w, @h)
  end

  def grow
    @age += 1
    set_growth_stage
    if (@age % 100).zero?
      case @stage
      when :SEED
        @frame += 1 unless @frame >= STAGES[:SEED].max
      when :GROWING
        @frame += 1 unless @frame >= STAGES[:GROWING].max
      when :FULL_GROWN
        @frame += 1 unless @frame >= STAGES[:FULL_GROWN].max
      when :READY_TO_HARVEST
        @frame += 1 unless @frame >= STAGES[:READY_TO_HARVEST].max
      when :WITHERED
        @frame += 1 unless @frame >= STAGES[:WITHERED].max
        @sprite.a -= WITHER_RATE unless @sprite.a <= 80
      end
      update_sprite
    end
    @invalid = true if @age >= DEATH
  end

  # Harvest plant if correct stage
  def harvest(args, plant)
    if plant.stage == :READY_TO_HARVEST
      args.state.game_state.harvested_plants += 1
      plant.invalid = true
      args.outputs.sounds << 'sounds/harvest_plant.wav'
      args.state.game_state.score += 2
    elsif plant.stage == :WITHERED
      args.state.game_state.seeds += rand(10)
      plant.invalid = true
      args.outputs.sounds << 'sounds/harvest_withered.wav'
      args.state.game_state.score += 1
    end
  end

  private

  def set_growth_stage
    if @age >= GROWING && @age < FULL_GROWN
      @stage = :GROWING
    elsif @age >= FULL_GROWN && @age < READY_TO_HARVEST
      @stage = :FULL_GROWN
    elsif @age >= READY_TO_HARVEST && @age < WITHER
      @stage = :READY_TO_HARVEST
    elsif @age >= WITHER && @age < DEATH
      @stage = :WITHERED
    end
  end

  # sets @invalid to false if not occupied, attemps to harvest plant at location if occupied
  def occupied(args, new_plant)
    args.state.game_state.plants.each do |plant|
      next unless args.geometry.intersect_rect?(plant, new_plant)

      harvest(args, plant)
      return true
    end
    false
  end

  # DragonRuby required methods
  def serialize
    { w: @w, h: @h, x: @x, y: @y, age: @age, invalid: @invalid, stage: @stage, a: @a, frame: @frame,
      spritesheet: @spritesheet, sprite: @sprite }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
