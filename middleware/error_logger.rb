# frozen_string_literal: true

module Middleware
  class ErrorLogger
    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    rescue StandardError => e
      $logger.error "#{env['HTTP_X_FORWARDED_FOR'] || env["REMOTE_ADDR"]} " \
                    "#{env[Rack::REQUEST_METHOD]} #{env[Rack::SCRIPT_NAME]} #{env[Rack::PATH_INFO]} " \
                    "\n#{e}\n#{e.backtrace.join("\n")}"
      raise e if ENV['RACK_ENV'] == 'development'
      [503, {'Content-Type'  => 'text/plain'}, ['Server error']]
    end
  end
end
