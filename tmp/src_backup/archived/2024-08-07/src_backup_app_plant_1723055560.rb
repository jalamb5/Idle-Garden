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
  GROWING = 200
  FULL_GROWN = 400
  READY_TO_HARVEST = 600
  WITHER = 8000
  WITHER_RATE = 0.2
  DEATH = 10_000
  SPRITES = { SEED: 'sprites/stages/0seed.png', GROWING: 'sprites/stages/1growing.png', FULL_GROWN: 'sprites/stages/2full_grown.png',
              READY_TO_HARVEST: 'sprites/stages/3ready_to_harvest.png', WITHERED: 'sprites/stages/4withered.png' }.freeze
  # STAGES = %w[seed growing full_grown ready_to_harvest withered].freeze
  STAGES = { SEED: (0..10), GROWING: (11..20), FULL_GROWN: (21..35), READY_TO_HARVEST: (31..40),
             WITHERED: (41..55) }.freeze

  def initialize(args, spritesheet, x_coord = args.inputs.mouse.x, y_coord = args.inputs.mouse.y)
    @x = x_coord - 15
    @y = y_coord - 15
    @w = 20
    @h = 20
    @age = 0
    @invalid = occupied(args, [@x, @y, @w, @h])
    # @path = SPRITES[:SEED]
    @stage = :SEED
    @a = 255
    @frame = 0

    @spritesheet = spritesheet
    @sprite = update_sprite
  end

  def update_sprite
    @sprite = @spritesheet.get(@frame, @x, @y, 200, 200)
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
      # @path = SPRITES[:GROWING]
      @stage = :GROWING
    elsif @age >= FULL_GROWN && @age < READY_TO_HARVEST
      # @path = SPRITES[:FULL_GROWN]
      @stage = :FULL_GROWN
    elsif @age >= READY_TO_HARVEST && @age < WITHER
      # @path = SPRITES[:READY_TO_HARVEST]
      @stage = :READY_TO_HARVEST
    elsif @age >= WITHER && @age < DEATH
      # @path = SPRITES[:WITHERED]
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
