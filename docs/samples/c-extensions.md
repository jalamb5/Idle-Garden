### Basics - main.rb
```ruby
  # ./samples/12_c_extensions/01_basics/app/main.rb
  $gtk.ffi_misc.gtk_dlopen("ext")
  include FFI::CExt

  def tick args
    args.outputs.labels  << [640, 500, "mouse.x = #{args.mouse.x.to_i}", 5, 1]
    args.outputs.labels  << [640, 460, "square(mouse.x) = #{square(args.mouse.x.to_i)}", 5, 1]
    args.outputs.labels  << [640, 420, "mouse.y = #{args.mouse.y.to_i}", 5, 1]
    args.outputs.labels  << [640, 380, "square(mouse.y) = #{square(args.mouse.y.to_i)}", 5, 1]
  end


```

### Intermediate - main.rb
```ruby
  # ./samples/12_c_extensions/02_intermediate/app/main.rb
  $gtk.ffi_misc.gtk_dlopen("ext")
  include FFI::RE

  def split_words(input)
    words = []
    last = IntPointer.new
    re = re_compile("\\w+")
    first = re_matchp(re, input, last)
    while first != -1
      words << input.slice(first, last.value)
      input = input.slice(last.value + first, input.length)
      first = re_matchp(re, input, last)
    end
    words
  end

  def tick args
    args.outputs.labels  << [640, 500, split_words("hello, dragonriders!").join(' '), 5, 1]
  end

```

### Native Pixel Arrays - main.rb
```ruby
  # ./samples/12_c_extensions/03_native_pixel_arrays/app/main.rb
  $gtk.ffi_misc.gtk_dlopen("ext")
  include FFI::CExt

  def tick args
    args.state.rotation ||= 0

    update_scanner_texture   # this calls into a C extension!

    # New/changed pixel arrays get uploaded to the GPU before we render
    #  anything. At that point, they can be scaled, rotated, and otherwise
    #  used like any other sprite.
    w = 100
    h = 100
    x = (1280 - w) / 2
    y = (720 - h) / 2
    args.outputs.background_color = [64, 0, 128]
    args.outputs.primitives << [x, y, w, h, :scanner, args.state.rotation].sprite
    args.state.rotation += 1

    args.outputs.primitives << args.gtk.current_framerate_primitives
  end


```

### Handcrafted Extension - main.rb
```ruby
  # ./samples/12_c_extensions/04_handcrafted_extension/app/main.rb
  $gtk.ffi_misc.gtk_dlopen("ext")
  include FFI::CExt

  puts Adder.new.add_all(1, 2, 3, [4, 5, 6.0])

  def tick args
  end

```

### Handcrafted Extension - license.txt
```ruby
  # ./samples/12_c_extensions/04_handcrafted_extension/license.txt
  Copyright 2022 DragonRuby LLC

  MIT License

  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

```

### Handcrafted Extension Advanced - main.rb
```ruby
  # ./samples/12_c_extensions/04_handcrafted_extension_advanced/app/main.rb
  def build_c_extension
    v = Time.now.to_i
    $gtk.exec("cd ./mygame && (env SUFFIX=#{v} sh ./pre.sh 2>&1 | tee ./build-results.txt)")
    build_output = $gtk.read_file("build-results.txt")
    {
      dll_name: "ext_#{v}",
      build_output: build_output
    }
  end

  def tick args
    # sets console command when sample app initially opens
    if Kernel.global_tick_count == 0
      results = build_c_extension
      dll = results.dll_name
      $gtk.dlopen(dll)
      puts ""
      puts ""
      puts "========================================================="
      puts "* INFO: Static Sprites, Classes, Draw Override"
      puts "* INFO: Please specify the number of sprites to render."
      args.gtk.console.set_command "reset_with count: 100"
    end

    args.state.star_count ||= 0

    # init
    if Kernel.tick_count == 0
      args.state.stars = args.state.star_count.map { |i| Star.new }
      args.outputs.static_sprites << args.state.stars
    end

    # render framerate
    args.outputs.background_color = [0, 0, 0]
    args.outputs.primitives << args.gtk.current_framerate_primitives
  end

  # resets game, and assigns star count given by user
  def reset_with count: count
    $gtk.reset
    $gtk.args.state.star_count = count
  end

  $gtk.reset

```

### Handcrafted Extension Advanced - license.txt
```ruby
  # ./samples/12_c_extensions/04_handcrafted_extension_advanced/license.txt
  Copyright 2022 DragonRuby LLC

  MIT License

  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

```

### Handcrafted Extension Advanced - Metadata - cvars.txt
```ruby
  # ./samples/12_c_extensions/04_handcrafted_extension_advanced/metadata/cvars.txt
  log.filter_subsystems=HTTPServer

  # Whether or not the game should use the whole display, be sure to
  # expose $gtk.set_window_fullscreen(false) or $gtk.request_quit
  # to the player so they can get out of full screen mode.
  # renderer.fullscreen=true

  # Milliseconds to sleep per frame when in the background (zero to disable)
  # renderer.background_sleep=0

  # Set the window as borderless.
  # Note: the ability to quit the application via OS shortcuts will not
  # work if this value is true and you must provide a means to exit the
  # game and wire it up to $gtk.request_quit
  # renderer.borderless=true

```

### Ios main.rb
```ruby
  # ./samples/12_c_extensions/05_ios_c_extensions/app/main.rb
  # NOTE: This is assumed to be executed with mygame as the root directory
  #       you'll need to copy this code over there to try it out.

  # Steps:
  # 1. Create ext.h and ext.m
  # 2. Create Info.plist file
  # 3. Add before_create_payload to IOSWizard (which does the following):
  #    a. run ./dragonruby-bind against C Extension and update implementation file
  #    b. create output location for iOS Framework
  #    c. compile C extension into Framework
  #    d. copy framework to Payload directory and Sign
  # 4. Run $wizards.ios.start env: (:prod|:dev|:hotload) to create ipa
  # 5. Invoke args.gtk.dlopen giving the name of the C Extensions (~1s to load).
  # 6. Invoke methods as needed.

  # ===================================================
  # before_create_payload iOS Wizard
  # ===================================================
  class IOSWizard < Wizard
    def before_create_payload
      puts "* INFO - before_create_payload"

      # invoke ./dragonruby-bind
      sh "./dragonruby-bind --output=mygame/ext-bind.m mygame/ext.h"

      # update generated implementation file
      contents = $gtk.read_file "ext-bind.m"
      contents = contents.gsub("#include \"mygame/ext.h\"", "#include \"mygame/ext.h\"\n#include \"mygame/ext.m\"")
      puts contents

      $gtk.write_file "ext-bind.m", contents

      # create output location
      sh "rm -rf ./mygame/native/ios-device/ext.framework"
      sh "mkdir -p ./mygame/native/ios-device/ext.framework"

      # compile C extension into framework
      sh <<-S
  clang -I. -I./mruby/include -I./include -o "./mygame/native/ios-device/ext.framework/ext" \\
        -arch arm64 -dynamiclib -isysroot "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk" \\
        -install_name @rpath/ext.framework/ext \\
        -fembed-bitcode -Xlinker -rpath -Xlinker @loader_path/Frameworks -dead_strip -Xlinker -rpath -fobjc-arc -fobjc-link-runtime \\
        -F/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks \\
        -miphoneos-version-min=10.3 -Wl,-no_pie -licucore -stdlib=libc++ \\
        -framework CFNetwork -framework UIKit -framework Foundation \\
        ./mygame/ext-bind.m
  S

      # stage extension
      sh "cp ./mygame/native/ios-device/Info.plist ./mygame/native/ios-device/ext.framework/Info.plist"
      sh "mkdir -p \"#{app_path}/Frameworks/ext.framework/\""
      sh "cp -r \"#{root_folder}/native/ios-device/ext.framework/\" \"#{app_path}/Frameworks/ext.framework/\""

      # sign
      sh <<-S
  CODESIGN_ALLOCATE=#{codesign_allocate_path} #{codesign_path} \\
                                              -f -s \"#{certificate_name}\" \\
                                              \"#{app_path}/Frameworks/ext.framework/ext\"
  S
    end
  end

  def tick args
    if Kernel.tick_count == 60 && args.gtk.platform?(:ios)
      args.gtk.dlopen 'ext'
      include FFI::CExt
      puts "the results of hello world are:"
      puts hello_world()
      $gtk.console.show
    end
  end

```

### Ios Metadata - cvars.txt
```ruby
  # ./samples/12_c_extensions/05_ios_c_extensions/metadata/cvars.txt

```

### Ios Metadata - ios_metadata.txt
```ruby
  # ./samples/12_c_extensions/05_ios_c_extensions/metadata/ios_metadata.txt
  teamid=TEAMID
  appid=APPID
  appname=ICON NAME
  version=1.0
  devcert=NAME OF DEV CERT
  prodcert=NAME OF PROD CERT

```
