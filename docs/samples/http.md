### Retrieve Images - main.rb
```ruby
  # ./samples/11_http/01_retrieve_images/app/main.rb
  $gtk.register_cvar 'app.warn_seconds', "seconds to wait before starting", :uint, 11

  def tick args
    args.outputs.background_color = [0, 0, 0]

    # Show a warning at the start.
    args.state.warning_debounce ||= args.cvars['app.warn_seconds'].value * 60
    if args.state.warning_debounce > 0
      args.state.warning_debounce -= 1
      args.outputs.labels << [640, 600, "This app shows random images from the Internet.", 10, 1, 255, 255, 255]
      args.outputs.labels << [640, 500, "Quit in the next few seconds if this is a problem.", 10, 1, 255, 255, 255]
      args.outputs.labels << [640, 350, "#{(args.state.warning_debounce / 60.0).to_i}", 10, 1, 255, 255, 255]
      return
    end

    args.state.download_debounce ||= 0   # start immediately, reset to non zero later.
    args.state.photos ||= []

    # Put a little pause between each download.
    if args.state.download.nil?
      if args.state.download_debounce > 0
        args.state.download_debounce -= 1
      else
        args.state.download = $gtk.http_get 'https://picsum.photos/200/300.jpg'
      end
    end

    if !args.state.download.nil?
      if args.state.download[:complete]
        if args.state.download[:http_response_code] == 200
          fname = "sprites/#{args.state.photos.length}.jpg"
          $gtk.write_file fname, args.state.download[:response_data]
          args.state.photos << [ 100 + rand(1080), 500 - rand(480), fname, rand(80) - 40 ]
        end
        args.state.download = nil
        args.state.download_debounce = (rand(3) + 2) * 60
      end
    end

    # draw any downloaded photos...
    args.state.photos.each { |i|
      args.outputs.primitives << [i[0], i[1], 200, 300, i[2], i[3]].sprite
    }

    # Draw a download progress bar...
    args.outputs.primitives << [0, 0, 1280, 30, 0, 0, 0, 255].solid
    if !args.state.download.nil?
      br = args.state.download[:response_read]
      total = args.state.download[:response_total]
      if total != 0
        pct = br.to_f / total.to_f
        args.outputs.primitives << [0, 0, 1280 * pct, 30, 0, 0, 255, 255].solid
      end
    end
  end

```

### In Game Web Server Http Get - main.rb
```ruby
  # ./samples/11_http/02_in_game_web_server_http_get/app/main.rb
  def tick args
    args.state.reqnum ||= 0
    # by default the embedded webserver is disabled in a production build
    # to enable the http server in a production build you need to:
    # - update metadata/cvars.txt
    # - manually start the server up with enable_in_prod set to true:
    args.gtk.start_server! port: 3000, enable_in_prod: true
    args.outputs.background_color = [0, 0, 0]
    args.outputs.labels << { x: 640,
                             y: 360,
                             text: "Point your web browser at http://localhost:#{args.state.port}/",
                             size_px: 30,
                             anchor_x: 0.5,
                             anchor_y: 0.5 }

    args.outputs.labels << { x: 640,
                             y: 360,
                             text: "See metadata/cvars.txt for webserer configuration requirements.",
                             size_px: 30,
                             anchor_x: 0.5,
                             anchor_y: 1.5 }

    if Kernel.tick_count == 1
      $gtk.openurl "http://localhost:3000"
    end

    args.inputs.http_requests.each { |req|
      puts("METHOD: #{req.method}");
      puts("URI: #{req.uri}");
      puts("HEADERS:");
      req.headers.each { |k,v| puts("  #{k}: #{v}") }

      if (req.uri == '/')
        # headers and body can be nil if you don't care about them.
        # If you don't set the Content-Type, it will default to
        #  "text/html; charset=utf-8".
        # Don't set Content-Length; we'll ignore it and calculate it for you
        args.state.reqnum += 1
        req.respond 200, "<html><head><title>hello</title></head><body><h1>This #{req.method} was request number #{args.state.reqnum}!</h1></body></html>\n", { 'X-DRGTK-header' => 'Powered by DragonRuby!' }
      else
        req.reject
      end
    }
  end

```

### In Game Web Server Http Get - Metadata - cvars.txt
```ruby
  # ./samples/11_http/02_in_game_web_server_http_get/metadata/cvars.txt
  webserver.enabled=true
  webserver.port=3000
  webserver.remote_clients=false

```

### In Game Web Server Http Post - main.rb
```ruby
  # ./samples/11_http/03_in_game_web_server_http_post/app/main.rb
  def tick args
    # by default the embedded webserver is disabled in a production build
    # to enable the http server in a production build you need to:
    # - update metadata/cvars.txt
    # - manually start the server up with enable_in_prod set to true:
    args.gtk.start_server! port: $cvars["webserver.port"].value, enable_in_prod: true

    # defaults
    args.state.post_button      = args.layout.rect(row: 0, col: 0, w: 5, h: 1).merge(text: "execute http_post")
    args.state.post_body_button = args.layout.rect(row: 1, col: 0, w: 5, h: 1).merge(text: "execute http_post_body")
    args.state.request_to_s ||= ""
    args.state.request_body ||= ""

    # render
    args.state.post_button.yield_self do |b|
      args.outputs.borders << b
      args.outputs.labels  << b.merge(text: b.text,
                                      y:    b.y + 30,
                                      x:    b.x + 10)
    end

    args.state.post_body_button.yield_self do |b|
      args.outputs.borders << b
      args.outputs.labels  << b.merge(text: b.text,
                                      y:    b.y + 30,
                                      x:    b.x + 10)
    end

    draw_label args, 0,  6, "Request:", args.state.request_to_s
    draw_label args, 0, 14, "Request Body Unaltered:", args.state.request_body

    # input
    if args.inputs.mouse.click
      # ============= HTTP_POST =============
      if (args.inputs.mouse.inside_rect? args.state.post_button)
        # ========= DATA TO SEND ===========
        form_fields = { "userId" => "#{Time.now.to_i}" }
        # ==================================

        args.gtk.http_post "http://localhost:9001/testing",
                           form_fields,
                           ["Content-Type: application/x-www-form-urlencoded"]

        args.gtk.notify! "http_post"
      end

      # ============= HTTP_POST_BODY =============
      if (args.inputs.mouse.inside_rect? args.state.post_body_button)
        # =========== DATA TO SEND ==============
        json = "{ \"userId\": \"#{Time.now.to_i}\"}"
        # ==================================

        args.gtk.http_post_body "http://localhost:9001/testing",
                                json,
                                ["Content-Type: application/json", "Content-Length: #{json.length}"]

        args.gtk.notify! "http_post_body"
      end
    end

    # calc
    args.inputs.http_requests.each do |r|
      puts "#{r}"
      if r.uri == "/testing"
        puts r
        args.state.request_to_s = "#{r}"
        args.state.request_body = r.raw_body
        r.respond 200, "ok"
      end
    end
  end

  def draw_label args, row, col, header, text
    label_pos = args.layout.rect(row: row, col: col, w: 0, h: 0)
    args.outputs.labels << "#{header}\n\n#{text}".wrapped_lines(80).map_with_index do |l, i|
      { x: label_pos.x, y: label_pos.y - (i * 15), text: l, size_enum: -2 }
    end
  end

```

### In Game Web Server Http Post - Metadata - cvars.txt
```ruby
  # ./samples/11_http/03_in_game_web_server_http_post/metadata/cvars.txt
  webserver.enabled=true
  webserver.port=9001
  webserver.remote_clients=false

```
