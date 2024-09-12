# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/boot.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

def tick(args)
  args.state.boot ||= Boot.new(args)
  args.state.boot.tick(args)
end
