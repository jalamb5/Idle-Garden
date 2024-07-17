# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/startup.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

def tick(args)
  args.state.startup ||= Startup.new(args)
  args.state.startup.tick(args)
  # args.state.game_state ||= Game.new(args)
  # args.state.game_state.tick(args)
end
