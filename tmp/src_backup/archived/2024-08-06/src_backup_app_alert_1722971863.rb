# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/labels.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Show alerts in sidebar
class Alert
  attr_accessor :y_coord

  def initialize(message, y_coord = 540)
    @message = message
    @y_coord = y_coord
    @ttl = 120
    @labels = []
    @max_length = 20
    generate_labels
  end

  def display(args)
    return if @ttl.zero?

    @labels.each do |label|
      handle_overlaps(args) 
      label.display(args)
      args.outputs.solids << { x: 5, y: label.y - 24, w: 180, h: 20, r: 200, g: 213, b: 185, a: 100 }
    end
    @ttl -= 1
  end

  private

  def generate_labels
    if @message.length <= @max_length
      @labels << Labels.new(5, @y_coord, '', @message, 20, [0, 0, 0, 240])
    else
      lines = split_long_string
      lines.each do |line|
        @labels << Labels.new(5, @y_coord, '', line, 20, [0, 0, 0, 240])
        @y_coord -= 20
      end
    end
  end

  def split_long_string
    words = @message.split(' ')
    lines = []
    current_line = ''

    words.each do |word|
      if current_line.length + word.length + 1 <= @max_length
        current_line += ' ' unless current_line.empty?
        current_line += word
      else
        lines << current_line
        current_line = word
      end
    end

    lines << current_line unless current_line.empty?
    lines
  end

  def handle_overlaps(args)
    args.state.game_state.alerts.each do |alert|
      label.y = alert.y_coord - 20 if label.y == alert.y_coord
    end
  end
end
