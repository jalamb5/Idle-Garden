# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/spritesheet.rb'
require 'app/consumable.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Create new plants in garden
class Plant
  attr_accessor :x, :y, :w, :h, :age, :invalid, :stage, :a, :frame, :sheet, :sprite, :soil_plot

  attr_sprite

  # Growth Stages & Rates
  GROWING = 2000
  FULL_GROWN = 4000
  READY_TO_HARVEST = 6000
  WITHER = 8000
  WITHER_RATE = 0.2
  DEATH = 10_000
  STAGES = { SEED: (0..13), GROWING: (14..25), FULL_GROWN: (26..27), READY_TO_HARVEST: (28..30),
             WITHERED: (31..55) }.freeze

  def initialize(args, sheet, x_coord = args.inputs.mouse.x, y_coord = args.inputs.mouse.y)
    @x = (x_coord - 32).to_i # Offset to center
    @y = y_coord.to_i
    @w = 64
    @h = 64
    @age = 0
    @invalid = occupied(args, [@x, @y, @w, @h])
    @stage = :READY_TO_HARVEST
    @a = 255
    @frame = 0
    @sheet = sheet

    @sprite = update_sprite(args)
    @soil_plot = args.state.game_state.soil_manager.find_plot(args, @x + 32, @y) # Remove offset on x
  end

  def update_sprite(args)
    @sprite = args.state.game_state.plant_manager.spritesheets[@sheet].get(@frame, @x, @y, @w, @h)
  end

  def grow(args)
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
      update_sprite(args)
    end
    @invalid = true && @soil_plot.improve if @age >= DEATH
  end

  # Harvest plant if correct stage
  def harvest(args, plant)
    return unless plant.stage == :READY_TO_HARVEST || plant.stage == :WITHERED

    case plant.stage
    when :READY_TO_HARVEST
      harvest_action(args, plant)
    when :WITHERED
      wither_action(args, plant)
    end
    plant.soil_plot.degrade
    plant.invalid = true
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

  # Perform actions for plants that are ready to be harvested
  def harvest_action(args, plant)
    type = "#{plant.sheet.to_s.split('_seed').first}_harvested".to_sym

    unless args.state.game_state.shed.inventory.include?(type)
      args.state.game_state.shed.inventory[type] = Consumable.new(plant.sheet, 0)
    end

    args.state.game_state.shed.inventory[type].quantity += 1
    args.state.game_state.shed.inventory[type].bonus += plant.soil_plot.tile
    args.state.boot.sound_manager.play_effect(:harvest_plant, args)
    args.state.game_state.score += 2
  end

  # Perform actions for plants that are withered
  def wither_action(args, plant)
    type = "#{plant.sheet}_seed".to_sym
    args.state.game_state.shed.inventory[type] += rand(5 * plant.soil_plot.tile)
    args.state.boot.sound_manager.play_effect(:harvest_withered, args)
    args.state.game_state.score += 1
  end

  # sets @invalid to false if not occupied, attemps to harvest plant at location if occupied
  def occupied(args, new_plant)
    return true if args.state.game_state.plant_manager.block_plant

    args.state.game_state.plant_manager.plants.each do |plant|
      next unless args.geometry.intersect_rect?(plant, new_plant)

      harvest(args, plant)
      return true
    end
    false
  end

  # DragonRuby required methods
  def serialize
    { w: @w, h: @h, x: @x, y: @y, age: @age, invalid: @invalid, stage: @stage, a: @a, frame: @frame,
      sheet: @sheet, sprite: @sprite }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
