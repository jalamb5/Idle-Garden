# frozen_string_literal: true

# Handle game logic
class Game
  def initialize(args)
    # Set splash screen
    splash
    # Set game variables
    @grass_background = { x: 200, y: 0, w: 1080, h: 720, path: 'sprites/grass_background.png' }
    @background = { x: 250, y: 50, w: 980, h: 620, path: 'sprites/background.png' }
    @plants = []
    @seeds = 500
    @harvested_plants = 0
    @cash = 5
    @price = { seed: 5, plant: 10, harvester: 150, planter: 150, seller: 50 }
    @auto_planters = []
    @auto_harvesters = []
    @auto_sellers = []
    @counter = 0
  end

  private

  def splash
    args.outputs.sprites << { x: 0, y: 0, w: 1280, h: 720, path: 'sprites/splash.png' }
  end
end
