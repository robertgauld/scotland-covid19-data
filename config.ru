require_relative 'common'

update

$logger.info 'Starting Rufas Scheduler'
scheduler = Rufus::Scheduler.new
scheduler.every 3_600 do
  Thread.current.thread_variable_set(:logger_label, 'Background update')
  update
end

$logger.info 'Configuration complete'
use Rack::Static,
  urls: ['/'],
  root: 'output',
  index: 'index.html'

run lambda { |env|
  [
    404,
    {
      'Content-Type'  => 'text/plain',
      'Cache-Control' => 'public, max-age=86400'
    },
    'Not found!'
  ]
}
