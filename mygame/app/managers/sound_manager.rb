# frozen_string_literal: true

# Managed sound effects & music
class SoundManager
  attr_accessor :sfx_gain, :music_gain

  EFFECT_LIBRARY = {
    button_click: 'sounds/button_click.wav',
    button_reject: 'sounds/button_reject.wav',
    harvest_plant: 'sounds/harvest_plant.wav',
    harvest_withered: 'sounds/harvest_withered.wav',
    harvester: 'sounds/harvester.wav',
    planter: 'sounds/planter.wav',
    seller: 'sounds/seller.wav'
  }.freeze

  MUSIC_LIBRARY = {
    garden_melody: 'sounds/Garden_Melody.ogg'
  }.freeze

  def initialize
    @sfx_gain = 0.25
    @music_gain = 0.25
  end

  def play_effect(type, args)
    args.outputs.sounds << { input: EFFECT_LIBRARY[type], gain: @sfx_gain }
  end

  def play_music(type, args)
    args.audio[:music] = { input: MUSIC_LIBRARY[type], gain: @music_gain, looping: true }
  end

  private

  # DragonRuby required methods
  def serialize
    { sfx_gain: @sfx_gain, music_gain: @music_gain }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
