# coding: utf-8
# Copyright 2019 DragonRuby LLC
# MIT License
# notify.rb has been released under MIT (*only this file*).

module GTK
  class Runtime
    class Messages; class << self
      def messages_check_thermal_state
        <<-S
* WARNING: Your game (or some other process on the device) is causing the device to have high temps.
You can manually get the current thermal state of the device by calling ~gtk.get_thermal_state~

#+begin_src
  def tick args
    args.outputs.labels << { x: 30, y: 30.from_top, text: "thermal state: \#{$gtk.current_thermal_state}" }
  end
#+end_src

NOTE: ~$gtk.disable_console~ will also disable the CTRL+R reset behavior.
S
      end

      def messages_reset_via_ctrl_r
        <<-S
* INFO: You pressed CTRL+R which is a key combo reserved by DragonRuby.
Pressing CTRL+R invokes ~$gtk.reset_next_tick~ (safely resetting your game with a convenient key combo).

If you want to disable this behavior, add the following to the top of =main.rb=:

#+begin_src
  $gtk.disable_reset_via_ctrl_r

  def tick args
    ...
  end
#+end_src

NOTE: ~$gtk.disable_console~ will also disable the CTRL+R reset behavior.
S
      end

      def messages_stop_music_is_deprecated
        <<-S
* WARNING: ~Runtime#stop_music~ is deprecated and will be removed in future versions.

Sounds that loop are no longer supported via args.outputs.sounds:

1. Migrate over to ~args.audio~ (for more info see type ~args.docs_audio~ in the Console).
2. Delete the usage of ~stop_music~.

For details
S
      end

      def messages_looping_sounds_behavior_change
      <<-S
* WARNING: ~Outputs#sounds~ no longer supports looping (one-time sounds are still supported).

Use ~Args#audio~ instead for looping sounds.

Here's how to migrate looping sounds. Here's an example of bg music being started on tick zero:

#+begin_src
  def tick args
    if Kernel.tick_count == 0
      # bg music will not loop after completion
      # use args.audio to create a looping (see below)
      args.outputs.sounds << "sounds/bg-music.ogg"
    end
  end
#+end_src

The example above becomes:

#+begin_src
  def tick args
    if Kernel.tick_count == 0
      args.audio[:bg_music] = { input: "sounds/bg-music.ogg", looping: true }
    end
  end
#+end_src

Additional options that can be passed to ~Args#audio~:

#+begin_src
  def tick args
    if Kernel.tick_count == 0
      args.audio[:bg_music] = {
        input:  "sounds/bg-music.ogg",
        looping: true,
        gain:    1.0,
        pitch:   1.0,
        paused:  false,
        # additional keys/values to help with context (metadata) can be added safely
      }
    end
  end
#+end_src

You can use ~Args#audio~ for one time sounds too.

The following is still valid/supported:

#+begin_src
  def tick args
    # play a non-looping sound every second
    if (Kernel.tick_count % 60) == 0
      args.outputs.sounds << "sounds/coin.wav"
    end
  end
#+end_src

But can be written to use ~args.audio~ as:

#+begin_src
  def tick args
    if (Kernel.tick_count % 60) == 0
      args.audio[:coin] = { input: "sounds/coin.wav" }
    end
  end
#+end_src
S
      end # end looping_sounds_behavior_change_message
    end; end # end self
  end # end runtime class
end # end gtk
