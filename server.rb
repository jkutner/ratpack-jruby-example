require 'java'
require 'jruby/core_ext'
require 'bundler/setup'
Bundler.require

java_import 'ratpack.server.RatpackServer'
java_import 'ratpack.registry.Registry'
java_import 'ratpack.exec.Blocking'
java_import 'ratpack.stream.Streams'
java_import 'ratpack.http.ResponseChunks'
java_import 'java.time.Duration'

java_import 'ratpack.server.BaseDir'
java_import 'ratpack.guice.Guice'
java_import 'ratpack.dropwizard.metrics.DropwizardMetricsConfig'
java_import 'ratpack.dropwizard.metrics.DropwizardMetricsModule'
java_import 'ratpack.dropwizard.metrics.MetricsWebsocketBroadcastHandler'

require './db/init'
require './lib/widget'

RatpackServer.start do |b|
  b.server_config do |config|
    config.base_dir(BaseDir.find)
    config.props("application.properties")
    config.require("/metrics", DropwizardMetricsConfig.java_class)
  end

  b.registry(Guice.registry { |s|
    s.module(DropwizardMetricsModule.new)
  })

  b.handlers do |chain|
    chain.get do |ctx|
      ctx.render("Hello from Ratpack JRuby")
    end

    chain.files do |f|
      f.dir("public").indexFiles("metrics.html")
    end

    chain.get("metrics-report", MetricsWebsocketBroadcastHandler.new)

    chain.get("stream") do |ctx|
      publisher = Streams.periodically(ctx, Duration.ofMillis(5)) do |i|
        i < 10 ? i.to_s : nil
      end
      ctx.render(ResponseChunks.stringChunks(publisher))
    end

    chain.prefix("widgets") do |c1|
      c1.get do |ctx|
        Blocking.get do
          DB[:widgets].all
        end.then do |widgets|
          ctx.render(JSON.dump(widgets))
        end
      end

      c1.get("count") do |ctx|
        Blocking.get do
          DB[:widgets].count
        end.then do |i|
          ctx.render(JSON.dump({count: i}))
        end
      end

      c1.post("new") do |ctx|
        widget = Widget.new
        widget.name = SecureRandom.hex(10)
        widget.save
        ctx.render(widget.to_json)
      end

      c1.prefix(":id") do |c2|
        c2.all do |ctx|
          id = ctx.path_tokens['id']
          widget = Widget[id.to_i]
          ctx.next(Registry.single(Widget.java_class, widget))
        end

        c2.get do |ctx|
          widget = ctx.get(Widget.java_class)
          ctx.render(widget.to_json)
        end

        c2.get("name") do |ctx|
          widget = ctx.get(Widget.java_class)
          ctx.render(widget.name)
        end
      end
    end
  end
end
