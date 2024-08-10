# frozen_string_literal: true

# Manage pause menu
class Pause
  def initialize(args)
    draw_screen(args)
  end

  def tick(args)
    draw_screen(args)
  end

  private

  def draw_screen(args)
    args.outputs.solids << { x: 100, y: 100, w: 500, h: 500, r: 0, g: 255, b: 0, a: 55 }
  end
end
