# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/plant.rb'
require 'app/alert.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Create new automations for garden
class Automation
  attr_accessor :type, :cooldown, :sprite, :name, :work_completed, :location, :target, :counter

  COOLDOWNS = { harvester: 300, planter: 200, seller: 500 }.freeze

  def initialize(type, args)
    @type = type
    @cooldown = COOLDOWNS[type]
    @location = [250, 50]
    @target = target_generator(args)
    @sprite = update_sprite(args)
    @frame = 0
    @counter = 0
    @name = name_generator(args)
    @work_completed = 0
    args.state.startup.sound_manager.play_effect(@type, args) unless args.state.load_state.loaded_from_save == true
  end

  def run(args)
    update_sprite(args)
    move_sprite if @cooldown <= 0 || @type == :seller
    update_frame(args) if @counter % 10 == 0
    @cooldown -= 1
    @counter += 1
    case @type
    when :harvester
      auto_harvester(args) if @cooldown <= 0 && args.state.game_state.plant_manager.plants.length.positive?
    when :planter
      auto_planter(args) if @cooldown <= 0 && args.state.game_state.plant_manager.seeds.positive?
    when :seller
      move_auto_seller(args)
      auto_seller(args.state.game_state) if args.state.game_state.harvested_plants.positive?
    end
  end

  def clicked?(args)
    return false unless args.inputs.mouse.click && args.inputs.mouse.point.inside_rect?(@sprite)

    args.state.startup.sound_manager.play_effect(@type, args)

    # Prevent clicking automator from planting or harvesting
    args.state.game_state.block_click = true
    messages = { harvester: ['has harvested', 'plants'],
                 planter: ['has planted', 'seeds'],
                 seller: ['has made', 'cash from the garden'] }
    args.state.game_state.ui.alerts << Alert.new(
      "#{@name} #{messages[@type][0]} #{@work_completed} #{messages[@type][1]}", color: :blue
    )
  end

  private

  def update_sprite(args)
    @sprite = args.state.game_state.automations.spritesheets[@type].get(@frame, @location[0], @location[1], 32, 32)
  end

  def update_frame(args)
    @frame = @frame < args.state.game_state.automations.spritesheets[@type].num_tiles - 1 ? @frame + 1 : 0
  end

  def move_sprite
    return if @location == @target || @target.nil?

    @location.each_with_index do |coord, i|
      direction = (@target[i] - coord).negative? ? -1 : 1
      @location[i] += direction if coord != @target[i]
    end
  end

  def auto_harvester(args)
    @target = harvest_generator(args) if @target.nil?

    return unless @location == @target

    plant = args.state.game_state.plant_manager.plants.find { |i| i.x == @location[0] && i.y == @location[1] }
    plant.harvest(args, plant) && @work_completed += 1 unless plant.nil?
    @cooldown = rand(1000)
    @target = nil
  end

  def auto_planter(args)
    return unless @location == @target

    sheet = %i[flower_red flower_blue].sample
    plant = Plant.new(args, sheet, @location[0], @location[1])
    args.state.game_state.plant_manager.plants << plant
    args.state.game_state.plant_manager.seeds -= 1
    @work_completed += 1
    @cooldown = rand(1000)
    @target = coord_generator
  end

  # Generate random coordinate within the garden
  def coord_generator
    # x 250-1200, y 50-650
    x = rand(1200)
    x += 250 if x < 250
    y = rand(650)
    y += 50 if y < 50
    [x, y]
  end

  # Sell harvest if the auto seller has moved off screen
  def auto_seller(game_state)
    return unless @location == [150, 720]

    game_state.shed.harvested_plants.each do |key, value|
      profit = 
    end
    profit = args.state.game_state.harvested_plants * args.state.game_state.price[:plant]
    args.state.game_state.cash += profit
    args.state.game_state.score += args.state.game_state.harvested_plants * 10
    args.state.game_state.harvested_plants = 0
    @work_completed += profit
    @cooldown = rand(1000)
  end

  # Auto sellers move differently than other automations and are not in the garden, they require special logic
  def move_auto_seller(args)
    off_screen = [150, 720]
    # home = [args.state.game_state.ui.labels[:harvested].x + 125, args.state.game_state.ui.labels[:harvested].y - 25]
    home = [75, 175]
    if @location == off_screen
      @target = home
    elsif @location == home && args.state.game_state.harvested_plants.positive? && @cooldown <= 0
      @target = off_screen
    else
      @target
    end
  end

  # Find a harvestable plant for the auto harvester
  def harvest_generator(args)
    harvestable_plants = []
    args.state.game_state.plant_manager.plants.each do |plant|
      harvestable_plants << plant if plant.stage == :READY_TO_HARVEST || plant.stage == :WITHERED
    end
    if harvestable_plants.empty?
      nil
    else
      target_plant = harvestable_plants.sample
      [target_plant.x, target_plant.y]
    end
  end

  # Generate a starting target for each automation
  def target_generator(args)
    case @type
    when :harvester
      nil
    when :planter
      coord_generator
    when :seller
      # harvested = args.state.game_state.ui.labels[:harvested]
      # [harvested.x + 125, harvested.y - 25]
      [75, 175]
    end
  end

  # Give each automation a unique name
  def name_generator(args)
    names = args.gtk.parse_json_file('data/names.json')
    sampled_name = names[@type.to_s].sample
    sampled_name = names[@type.to_s].sample while args.state.game_state.automations.register.include?(sampled_name)
    @name = sampled_name
  end

  # DragonRuby required methods
  def serialize
    { type: @type, cooldown: @cooldown, sprite: @sprite, name: @name, work_completed: @work_completed, location: @location, target: @target, counter: @counter }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
