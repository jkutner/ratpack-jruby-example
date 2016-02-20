require 'java'
require 'jbundler'

java_import 'ratpack.server.RatpackServer'

RatpackServer.start do |b|
  b.handlers do |chain|
    chain.get("") do |ctx|
      ctx.render("Hello from Ratpack JRuby")
    end
  end
end
