#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler'
require_relative '../common'

if ENV['DYNO'] && !File.exist?('/app/.apt/usr/bin/gnuplot')
  FileUtils.link(
    "#{ENV.fetch('BUILD_DIR')}/.apt/usr/bin/gnuplot-qt",
    "#{ENV.fetch('BUILD_DIR')}/.apt/usr/bin/gnuplot"
  )
end

update


