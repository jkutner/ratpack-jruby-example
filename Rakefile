require 'java'
require 'jruby/core_ext'
require 'bundler/setup'
Bundler.require

task "db:migrate" do
  DB = Sequel.connect(JdbcUrl.from_database_url)
  Sequel.extension :migration
  Sequel::Migrator.run(DB, 'db/migrations')
end

task "assets:precompile" do
  require 'jbundler'
  config = JBundler::Config.new
  JBundler::LockDown.new( config ).lock_down
  JBundler::LockDown.new( config ).lock_down("--vendor")
end
