class Button
  # helper method to create a button
  def new_button id, x, y, text
    # create a hash ("entity") that has some metadata
    # about what it represents
    entity = {
      id: id,
      rect: { x: x, y: y, w: 100, h: 50 }
    }

    # for that entity, define the primitives
    # that form it
    entity[:primitives] = [
      { x: x, y: y, w: 100, h: 50 }.border,
      { x: x, y: y, text: text }.label
    ]

    entity
  end

  # helper method for determining if a button was clicked
  def button_clicked? args, button
    return false unless args.inputs.mouse.click
    return args.inputs.mouse.point.inside_rect? button[:rect]
  end

  # def tick args
  #   # use helper method to create a button
  #   args.state.click_me_button ||= new_button :click_me, 10, 10, "click me"

  #   # render button generically using `args.outputs.primitives`
  #   args.outputs.primitives << args.state.click_me_button[:primitives]

  #   # check if the click occurred using the button_clicked? helper method
  #   if button_clicked? args, args.state.click_me_button
  #      args.gtk.notify! "click me button was clicked!"
  #   end
  # end
end
