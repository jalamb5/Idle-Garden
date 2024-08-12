# frozen_string_literal: true

# DragonRuby requires extensions
# rubocop:disable Style/RedundantFileExtensionInRequire
require 'app/labels.rb'
# rubocop:enable Style/RedundantFileExtensionInRequire

# Show alerts in sidebar
class Alert
  attr_accessor :y_coord, :all_coords, :message, :ttl

  def initialize(message, y_coord = 540, hover = false)
    @message = message
    @y_coord = y_coord
    @all_coords = []
    @ttl = hover ? 1 : 180
    @labels = []
    @max_length = 20
    generate_labels
  end

  def display(args)
    return if @ttl.zero?

    # Move overlapping labels unless no other labels exist
    handle_overlaps(args) unless args.state.game_state.ui.alerts.empty?

    @labels.each do |label|
      label.display(args)
      args.outputs.solids << { x: 5, y: label.y - 24, w: 180, h: 20, r: 200, g: 213, b: 185, a: 255 }
    end
    @ttl -= 1
  end

  private

  def generate_labels
    if @message.length <= @max_length
      @labels << Labels.new(5, @y_coord, '', @message, 20, [0, 0, 0, 240])
      @all_coords << @y_coord
    else
      lines = split_long_string
      lines.each do |line|
        @labels << Labels.new(5, @y_coord, '', line, 20, [0, 0, 0, 240])
        @all_coords << @y_coord
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
    args.state.game_state.ui.alerts.each do |alert|
      if alert.all_coords.include?(@labels[0].y) && self != alert
        @all_coords.map!.with_index { |_coord, index| alert.all_coords[-1] - (index + 1) * 20 }
      end
    end
    @labels.each_with_index { |l, i| l.y = @all_coords[i] }
  end

  # DragonRuby required methods
  def serialize
    { y_coord: @y_coord, all_coords: @all_coords, message: @message, ttl: @ttl }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
