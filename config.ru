require_relative 'common'

Rollbar.configure do |config|
  config.enabled = ENV.has_key?('ROLLBAR_ACCESS_TOKEN')
  config.access_token = ENV['ROLLBAR_ACCESS_TOKEN']
  config.environment = ENV['RACK_ENV']
  config.use_thread
  config.disable_rack_monkey_patch = true
end

update

$logger.info 'Starting Rufus Scheduler'
$scheduler = Rufus::Scheduler.new

def $scheduler.on_error(job, error)
  $logger.error "Error in Rufus Job\n" \
                "Job: #{job.class} #{job.original.inspect} #{job.opts.inspect}\n" \
                "Error: #{error}\n#{error.backtrace.join("\n")}"

  Rollbar.error(
    error,
    job_details: "#{job.class} #{job.original.inspect} #{job.opts.inspect}",
    job: job,
    scheduler: $scheduler,
    env: ENV
  )
end

$update_job = $scheduler.schedule_every(3_600, overlap: false, timeout: 120) do
  Thread.current.thread_variable_set(:logger_label, 'Background update')
  update
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
use Middleware::PageMaker

use Rack::Static,
  urls: ['/'],
  root: 'public',
  index: 'index.html',
  header_rules: [[:all, {'Cache-Control' => 'public, max-age=300'}]]

run lambda { |env|
  [
    404,
    {'Content-Type'  => 'text/plain'},
    ['Not found!']
  ]
}
