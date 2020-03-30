# frozen_string_literal: true

module Middleware
  class PageMaker
    PROCS = {
      '/' => ->(_env) { make_response(Make::Html.index) },
    }.freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      app = PROCS[env['PATH_INFO']] || @app
      app.call(env)
    end

    class << self
      private

      def make_response(body, content_type: 'text/html', status: 200)
        [
          status,
          {'Content-Type'  => content_type, 'Content-Length' => body.length.to_s, 'Cache-Control' => 'public, max-age=300'},
          [body]
        ]
      end
    end
  end
end

