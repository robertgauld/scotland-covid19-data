ENV['RACK_ENV'] ||= 'development'

require_relative 'common'

Rollbar.configure do |config|
  config.enabled = ENV.has_key?('ROLLBAR_ACCESS_TOKEN')
  config.access_token = ENV['ROLLBAR_ACCESS_TOKEN']
  config.environment = ENV['RACK_ENV']
  config.use_thread
  config.disable_rack_monkey_patch = true
end
class Rack::CommonLogger
  def log(env, status, header, began_at)
    length = extract_content_length(header)

    msg = FORMAT % [
      env['HTTP_X_FORWARDED_FOR'] || env["REMOTE_ADDR"] || "-",
      env["REMOTE_USER"] || "-",
      Time.now.strftime("%d/%b/%Y:%H:%M:%S %z"),
      env[Rack::REQUEST_METHOD],
      env[Rack::SCRIPT_NAME],
      env[Rack::PATH_INFO],
      env[Rack::QUERY_STRING].empty? ? "" : "?#{env[Rack::QUERY_STRING]}",
      env[Rack::SERVER_PROTOCOL],
      status.to_s[0..3],
      length,
      Rack::Utils.clock_time - began_at ]

    $logger.info "Web Request - #{msg.strip}"
  end
end

$logger.info 'Configuration complete'
use Middleware::ErrorLogger
use Rollbar::Middleware::Rack

if ENV.key?('SCOUT_KEY')
  ScoutApm::Rack.install!

  class ScoutMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      ScoutApm::Rack.transaction("#{env['PATH_INFO'].to_s.length < 2 ? 'index-page' : env['PATH_INFO']}", env) do
        @app.call(env)
      end
    end
  end

  use ScoutMiddleware
end

use Rack::Static,
  urls: ['/'],
  root: 'public',
  index: 'index.html',
  header_rules: [[:all, {'Cache-Control' => 'public, max-age=300'}]]

$logger.info 'Running rack app'
run lambda { |_env|
  [
    404,
    {'Content-Type' => 'text/plain'},
    ['Not found!']
  ]
}
