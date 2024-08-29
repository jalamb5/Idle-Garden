# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/automation.rb'
require 'app/game.rb'
require 'app/labels.rb'
require 'app/alert.rb'
require 'app/managers/load_manager.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Manage logic for clicking buttons
module ButtonActions
  def self.start(startup)
    startup.splash_state = false
    true
  end

  def self.sell(game_state, type)
    return false if game_state.shed.harvested_plants[type] <= 0

    game_state.cash += game_state.shed.harvested_plants[type] * game_state.price[type]
    game_state.score += game_state.shed.harvested_plants[type] * 10
    game_state.shed.harvested_plants[type] = 0
    true
  end

  def self.buy_seed(game_state, type)
    return false if (game_state.cash - game_state.price.seed[type]).negative?

    game_state.plant_manager.seeds[type] += 1
    game_state.cash -= game_state.price.seed[type]
    true
  end

  def self.select_seed(game_state, type)
    game_state.plant_manager.selection = type
  end

  def self.buy_auto_harvester(args)
    return false if (args.state.game_state.cash - args.state.game_state.price[:harvester]).negative?

    auto_harvester = Automation.new(:harvester, args)
    args.state.game_state.automations.auto_harvesters << auto_harvester
    args.state.game_state.cash -= args.state.game_state.price[:harvester]
    args.state.game_state.ui.alerts << Alert.new("#{auto_harvester.name} is helping in the garden!", color: :blue)
    true
  end

  def self.buy_auto_seller(args)
    return false if (args.state.game_state.cash - args.state.game_state.price[:seller]).negative?

    auto_seller = Automation.new(:seller, args)
    args.state.game_state.automations.auto_sellers << auto_seller
    args.state.game_state.cash -= args.state.game_state.price[:seller]
    args.state.game_state.ui.alerts << Alert.new("#{auto_seller.name} is helping to sell your harvest!", color: :blue)
    true
  end

  def self.buy_auto_planter(args)
    return false if (args.state.game_state.cash - args.state.game_state.price[:planter]).negative?

    auto_planter = Automation.new(:planter, args)
    args.state.game_state.automations.auto_planters << auto_planter
    args.state.game_state.cash -= args.state.game_state.price[:planter]
    args.state.game_state.ui.alerts << Alert.new("#{auto_planter.name} is helping in the garden!", color: :blue)
    true
  end

  def self.shed(args)
    args.state.game_state.shed.open == false ? (args.state.game_state.shed.open = true) : (args.state.game_state.shed.open = false)
    true
  end

  # Saves the state of the game in a text file called game_state.txt
  def self.save(args)
    # Collect data not stored in game_state
    args.state.game_state.save_data = { sfx_gain: args.state.startup.sound_manager.sfx_gain,
                                        music_gain: args.state.startup.sound_manager.music_gain,
                                        save_version: 1 }
    # Write save file
    $gtk.serialize_state('game_state.txt', args.state.game_state)
    true
  end

  # Load save happens before game_state initialization, requires args.state
  def self.load_save(state)
    state.load_state = LoadManager.new
    state.startup.splash_state = false
    true
  end

  def self.pause_game(game_state)
    game_state.paused == true ? (game_state.paused = false) : (game_state.paused = true)
    true
  end

  def self.mute_music(args)
    args.audio[:music][:gain] = args.audio[:music][:gain].zero? ? 0.25 : 0
    args.state.startup.sound_manager.music_gain = args.state.startup.sound_manager.music_gain.zero? ? 0.25 : 0
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
