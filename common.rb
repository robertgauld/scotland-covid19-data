# frozen_string_literal: true

require 'csv'
require 'date'
require 'json'
require 'logger'
require 'open-uri'

Bundler.require

NUMBERS_PER = 100_000
PLOT_SIZE = '900,600'

INPUT_DIR = File.join(__dir__, 'input')
OUTPUT_DIR = File.join(__dir__, 'output')
HEALTH_BOARD_POPULATIONS_FILE = 'HB_Populations.csv'
HEALTH_BOARD_CASES_FILE = 'regional_cases.csv'
HEALTH_BOARD_DEATHS_FILE = 'regional_deaths.csv'

$VERBOSE = false

$logger = Logger.new(STDERR)
$logger.formatter = proc do |severity, datetime, progname, message|
  if Thread.current.thread_variable_get(:logger_label)
    message = "#{Thread.current.thread_variable_get(:logger_label)} - #{message}"
  end
  "#{datetime} #{severity} #{progname}: #{message.strip}\n"
end
$logger.level = ENV['LOG_LEVEL']&.to_i || Logger::DEBUG
STDOUT.sync = true

$current_data_sha = ''

if ENV['DYNO'] && !File.exist?('/app/.apt/usr/bin/gnuplot')
  FileUtils.link '/app/.apt/usr/bin/gnuplot-qt', '/app/.apt/usr/bin/gnuplot'
end

require_relative 'update'
