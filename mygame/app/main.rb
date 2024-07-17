# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/startup.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

def tick(args)
  args.state.startup ||= Startup.new(args)
  args.state.startup.tick(args)
end
