require "logeater/parser"
require "logeater/reader"
require "logeater/request"
require "logeater/event"
require "logeater/logfile"
require "logeater/eventfile"
require "logeater/version"
require "yaml"
require "erb"

database_url = ENV["DATABASE_URL"] unless ENV["RAILS_ENV"] == "test"
if database_url
  uri = Addressable::URI.parse(database_url)
  config = {
    adapter: "postgresql",
    encoding: "utf8",
    min_messages: "WARNING",
    database: uri.path[1..-1],
    host: uri.host,
    username: uri.user,
    password: uri.password,
    port: uri.port
  }
else
  config_file = File.expand_path("../../db/config.yml", __FILE__)
  config = YAML.load(ERB.new(File.read(config_file)).result).with_indifferent_access[ENV["RAILS_ENV"] || "development"]
end
ActiveRecord::Base.establish_connection config

module Logeater
end
