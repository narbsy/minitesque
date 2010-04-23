require 'logger'
require 'testy'
require 'resque/server'

use Rack::ShowExceptions

run Rack::URLMap.new \
  "/" => Testy.new,
  "/resque" => Resque::Server.new
