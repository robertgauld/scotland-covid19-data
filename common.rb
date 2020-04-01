# frozen_string_literal: true

require 'csv'
require 'date'
require 'json'
require 'logger'
require 'open-uri'

Bundler.require

require 'rollbar/middleware/rack'

ROOT_DIR = __dir__
DATA_DIR = File.join(ROOT_DIR, 'data')
PUBLIC_DIR = File.join(ROOT_DIR, 'public')

NUMBERS_PER = 100_000

loader = Zeitwerk::Loader.new
loader.push_dir(ROOT_DIR)
loader.ignore(File.join(ROOT_DIR, 'data'))
loader.ignore(File.join(ROOT_DIR, 'public'))
loader.ignore(File.join(ROOT_DIR, 'template'))
loader.setup

$VERBOSE = false

$logger = Logger.new(STDOUT)
$logger.formatter = proc do |severity, datetime, progname, message|
  if Thread.current.thread_variable_get(:logger_label)
    message = "#{Thread.current.thread_variable_get(:logger_label)} - #{message}"
  end
  "#{datetime} #{severity} #{progname}: #{message.strip}\n"
end
$logger.level = ENV['LOG_LEVEL']&.to_i || ENV['RACK_ENV'].eql?('development') ? Logger::DEBUG : Logger::INFO
STDOUT.sync = true

$current_data_sha = ''

if ENV['DYNO'] && !File.exist?('/app/.apt/usr/bin/gnuplot')
  FileUtils.link '/app/.apt/usr/bin/gnuplot-qt', '/app/.apt/usr/bin/gnuplot'
end

def update
  return unless ScotlandCovid19Data.update_available? || 
                UkCovid19Data.update_available?

  ScotlandCovid19Data.update
  UkCovid19Data.update

  Make::Csv.all
  Make::Plot.all

  Make::Zip.all

  nil
end
