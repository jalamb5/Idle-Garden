# frozen_string_literal: true

# Show alerts in sidebar
class Alert
  # DragonRuby requires extensions
  # rubocop:disable Style/RedundantFileExtensionInRequire
  require 'app/labels.rb'
  # rubocop:enable Style/RedundantFileExtensionInRequire

  def initialize(message, y_coord = 540)
    @message = message
    @y_coord = y_coord
    @ttl = 1200
  end

  def display(args)
    while @ttl.positive?
      args.outputs.solids << { x: 5, y: @y_coord - 24, w: 180, h: 20, r: 200, g: 213, b: 185, a: 100 }
      Labels.new(5, @y_coord, '', @message, 20, [0, 0, 0, 240]).display(args)
      @ttl -= 1
    end
  end
end
