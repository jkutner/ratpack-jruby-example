require 'java'
require 'bundler/setup'
require 'jbundler'
require 'sequel'
require 'json'

java_import 'ratpack.server.RatpackServer'
java_import 'ratpack.registry.Registry'

JavaString = java.lang.Class.forName("java.lang.String")

def create_jdbc_url(db_url)
  db_server = db_url.split('@')[1]
  db_host = db_server.split(':')[0]
  db_port = db_server.split(':')[1].split('/')[0]
  db_name = db_server.split(':')[1].split('/')[1]

  db_creds = db_url.split('@')[0].gsub('postgres://', '')
  db_user = db_creds.split(':')[0]
  db_pass = db_creds.split(':')[1]

  "jdbc:postgresql://#{db_host}:#{db_port}/#{db_name}?user=#{db_user}&password=#{db_pass}&sslmode=require"
end

DB = Sequel.connect(create_jdbc_url(ENV['DATABASE_URL']))

DB.run "CREATE TABLE IF NOT EXISTS widgets (id serial not null primary key, name text)"

class Widget < Sequel::Model
  plugin :json_serializer
end

RatpackServer.start do |b|
  b.handlers do |chain|
    chain.get("") do |ctx|
      ctx.render("Hello from Ratpack JRuby")
    end

    chain.prefix("widgets") do |c1|
      c1.get("") do |ctx|
        count = DB[:widgets].count
        ctx.render("all of them: #{count.inspect}")
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
          ctx.next(Registry.single(id))
        end

        c2.get do |ctx|
          id = ctx.get(JavaString)
          widget = Widget[id.to_i]
          ctx.render(widget.to_json)
        end
      end
    end
  end
end
