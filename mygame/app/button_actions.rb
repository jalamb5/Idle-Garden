# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/automation.rb'
require 'app/game.rb'
require 'app/labels.rb'
require 'app/alert.rb'
require 'app/managers/load_manager.rb'
require 'app/consumable.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Manage logic for clicking buttons
module ButtonActions
  def self.start(boot)
    boot.splash_state = false
    true
  end

  def self.sell(args, type)
    game_state = args.state.game_state
    return false if game_state.shed.inventory[type].quantity <= 0

    fertility_bonus = game_state.shed.inventory[type].bonus
    game_state.cash += calculate_price(game_state, type, fertility_bonus)
    game_state.score += calculate_score(game_state, type, fertility_bonus)
    game_state.shed.inventory[type].quantity = 0
    game_state.shed.inventory[type].bonus = 0
    if fertility_bonus.positive?
      args.state.boot.ui_manager.game_ui.alerts << Alert.new("You earned a fertility bonus of #{fertility_bonus}!")
    end
    true
  end

  def self.calculate_price(game_state, type, fertility_bonus)
    price = 0
    price += game_state.shed.inventory[type].quantity * game_state.price[type]
    price += fertility_bonus
    price
  end

  # def self.calculate_fertility_bonus(game_state, type)
  #   bonus = 0
  #   game_state.shed.harvested_plants[type].each do |plant|
  #     bonus += plant.soil_plot.tile
  #   end
  #   bonus
  # end

  def self.calculate_score(game_state, type, fertility_bonus)
    score = 0
    score += game_state.shed.inventory[type].quantity * 10
    score += fertility_bonus
    score
  end

  def self.buy(game_state, type)
    return false if (game_state.cash - game_state.price[type]).negative?

    game_state.shed.inventory[type] ? (game_state.shed.inventory[type].quantity += 1) : (game_state.shed.inventory[type] = Consumable.new(type))

    game_state.cash -= game_state.price[type]
    true
  end

  def self.select(game_state, type)
    game_state.shed.selection = type
  end

  def self.buy_auto_harvester(args)
    return false if (args.state.game_state.cash - args.state.game_state.price[:harvester]).negative?

    auto_harvester = Automation.new(:harvester, args)
    args.state.game_state.automations.auto_harvesters << auto_harvester
    args.state.game_state.cash -= args.state.game_state.price[:harvester]
    args.state.boot.ui_manager.game_ui.alerts << Alert.new("#{auto_harvester.name} is helping in the garden!", color: :blue)
    true
  end

  def self.buy_auto_seller(args)
    return false if (args.state.game_state.cash - args.state.game_state.price[:seller]).negative?

    auto_seller = Automation.new(:seller, args)
    args.state.game_state.automations.auto_sellers << auto_seller
    args.state.game_state.cash -= args.state.game_state.price[:seller]
    args.state.boot.ui_manager.game_ui.alerts << Alert.new("#{auto_seller.name} is helping to sell your harvest!", color: :blue)
    true
  end

  def self.buy_auto_planter(args)
    return false if (args.state.game_state.cash - args.state.game_state.price[:planter]).negative?

    auto_planter = Automation.new(:planter, args)
    args.state.game_state.automations.auto_planters << auto_planter
    args.state.game_state.cash -= args.state.game_state.price[:planter]
    args.state.boot.ui_manager.game_ui.alerts << Alert.new("#{auto_planter.name} is helping in the garden!", color: :blue)
    true
  end

  def self.shed(args)
    args.state.game_state.shed.open == false ? (args.state.game_state.shed.open = true) : (args.state.game_state.shed.open = false)
    true
  end

  # Saves the state of the game in a text file called game_state.txt
  def self.save(args)
    # Collect data not stored in game_state
    args.state.game_state.save_data = { sfx_gain: args.state.boot.sound_manager.sfx_gain,
                                        music_gain: args.state.boot.sound_manager.music_gain,
                                        save_version: 1 }
    # Write save file
    $gtk.serialize_state('game_state.txt', args.state.game_state)
    true
  end

  # Load save happens before game_state initialization, requires args.state
  def self.load_save(state)
    state.load_state = LoadManager.new
    state.boot.splash_state = false
    true
  end

  def self.pause_game(game_state)
    game_state.paused == true ? (game_state.paused = false) : (game_state.paused = true)
    true
  end

  def self.mute_music(args)
    args.audio[:music][:gain] = args.audio[:music][:gain].zero? ? 0.25 : 0
    args.state.boot.sound_manager.music_gain = args.state.boot.sound_manager.music_gain.zero? ? 0.25 : 0
    true
  end

  def self.mute_sfx(sound_manager)
    sound_manager.sfx_gain = sound_manager.sfx_gain.zero? ? 0.25 : 0
    true
  end

  def self.quit
    $gtk.request_quit
  end
end
