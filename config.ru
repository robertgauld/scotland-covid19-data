require_relative 'common'

update

$logger.info 'Starting Rufas Scheduler'
scheduler = Rufus::Scheduler.new
scheduler.every 3_600 do
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
use Rack::Static,
  urls: ['/'],
  root: 'output',
  index: 'index.html',
  header_rules: [[:all, {'Cache-Control' => 'public, max-age=300'}]]

run lambda { |env|
  [
    404,
    {'Content-Type'  => 'text/plain'},
    'Not found!'
  ]
}
