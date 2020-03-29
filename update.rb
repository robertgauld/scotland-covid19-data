#!/usr/bin/env ruby
# frozen_string_literal: true

def update
  $logger.info 'Updating data'
  $logger.debug "Input directory: #{INPUT_DIR}"
  $logger.debug "Output directory: #{OUTPUT_DIR}"

  $logger.info 'Checking github for updated data'
  github_data_sha = JSON.parse(URI('https://api.github.com/repos/watty62/Scot_covid19/commits/master').open.string)['sha']
  $logger.debug "Current data: #{$current_data_sha}, Github data: #{github_data_sha} #{github_data_sha == $current_data_sha}"
  if github_data_sha == $current_data_sha
    $logger.info 'No new data'
    return
  end
  $current_data_sha = github_data_sha

  $logger.info "Reading health board data (#{HEALTH_BOARD_POPULATIONS_FILE})."
  health_boards = []
  health_board_scale = { 'Grand Total' => 0 }
  CSV.read(File.join(INPUT_DIR, HEALTH_BOARD_POPULATIONS_FILE), headers: true, converters: :numeric)
     .each { |record| health_boards.push record['Name'] unless health_boards.include? record['Name'] }
     .each { |record| health_board_scale[record['Name']] = record['Population'].to_f / NUMBERS_PER }
     .each { |record| health_board_scale['Grand Total'] += record['Population'].to_f / NUMBERS_PER }
  health_boards.delete 'Grand Total'
  health_boards.sort!
  $logger.debug "Read #{health_boards.count} health boards."

  date_converter = ->(value, field) { field.header.eql?('Date') ? Date.parse(value) : value }
  number_converter = ->(value, field) { !field.header.eql?('Date') ? value.eql?('X') ? nil : value.to_i / health_board_scale.fetch(field.header) : value }
  $logger.info "Reading cases data (#{HEALTH_BOARD_CASES_FILE})."
  cases = CSV.read(File.join(INPUT_DIR, HEALTH_BOARD_CASES_FILE), headers: true, converters: [number_converter, date_converter])
             .map { |record| [record['Date'], [*health_boards, 'Grand Total'].zip(record.values_at(*health_boards, 'Grand Total')).to_h] }
             .to_h
  $logger.debug "Read cases data for #{cases.keys.sort.values_at(0, -1).map(&:to_s).join(' to ')}."
  $logger.info "Reading deaths data (#{HEALTH_BOARD_DEATHS_FILE})."
  deaths = CSV.read(File.join(INPUT_DIR, HEALTH_BOARD_DEATHS_FILE), headers: true, converters: [number_converter, date_converter])
              .map { |record| [record['Date'], [*health_boards, 'Grand Total'].zip(record.values_at(*health_boards, 'Grand Total')).to_h] }
              .to_h
  $logger.debug "Read deaths data for #{deaths.keys.sort.values_at(0, -1).map(&:to_s).join(' to ')}."

  $logger.info 'Writing data for Scotland.'
  File.open(File.join(OUTPUT_DIR, "cases_per_#{NUMBERS_PER}.csv"), 'w') do |file|
    data = CSV::Table.new([], headers: ['Date', *health_boards, 'Grand Total'])

    cases.keys.sort.each do |date|
      data.push [date, *cases.fetch(date).values_at(*health_boards, 'Grand Total')]
    end

    file.puts data.to_csv
  end

  File.open(File.join(OUTPUT_DIR, "deaths_per_#{NUMBERS_PER}.csv"), 'w') do |file|
    data = CSV::Table.new([], headers: ['Date', *health_boards, 'Grand Total'])

    deaths.keys.sort.each do |date|
      data.push [date, *cases.fetch(date).values_at(*health_boards, 'Grand Total')]
    end

    file.puts data.to_csv
  end

  health_boards.each do |health_board|
    $logger.info "Writing data for #{health_board}."
    File.open(File.join(OUTPUT_DIR, "#{health_board.downcase.gsub(' ', '_')}_per_#{NUMBERS_PER}.csv"), 'w') do |file|
      data = CSV::Table.new([], headers: ['Date', 'Cases', 'Deaths', 'Cases Ratio', 'Deaths Ratio'])

      cases.keys.sort.each do |date|
        data.push [
          date,
          cases.dig(date, health_board),
          deaths.dig(date, health_board),
          cases.dig(date, health_board) ? cases.dig(date, health_board) / cases.dig(date, 'Grand Total') : nil,
          deaths.dig(date, health_board) ? deaths.dig(date, health_board) / deaths.dig(date, 'Grand Total') : nil
        ]
      end

      file.puts data.to_csv
    end
  end

  $logger.info 'Plotting data for Scotland.'
  Gnuplot.open do |gp|
    Gnuplot::Plot.new(gp) do |plot|
      plot.terminal "pngcairo size #{PLOT_SIZE}"
      plot.output File.join(OUTPUT_DIR, "cases_per_#{NUMBERS_PER}.png")

      plot.xdata 'time'
      plot.timefmt '\'%Y-%m-%d\''

      plot.title 'Scottish Health Board COVID-19 Cases'

      plot.key 'outside center bottom horizontal'

      plot.format 'x \'%d/%m/%y\''
      plot.xrange "['#{cases.keys.first.strftime('%Y-%m-01')}':'#{Date.parse(cases.keys.first.strftime('%Y-%m-01')).next_month.prev_day}']"

      plot.logscale 'y 10'
      plot.yrange '[0:]'
      plot.ylabel "Cases per #{NUMBERS_PER.to_s.gsub(/\B(?=(...)*\b)/, ',')}"

      plot.grid

      data = cases.sort_by { |key, value| key }
                  .map { |key, value| [key.to_s, *value.sort_by(&:first).map(&:last)] }
                  .transpose

      data[1..-2].each.with_index do |this_data, index|
        plot.add_data Gnuplot::DataSet.new([data[0], this_data]) { |ds|
          ds.using = '1:2'
          ds.with = 'line'
          ds.title = health_boards[index]
        }
      end
    end
  end

  Gnuplot.open do |gp|
    Gnuplot::Plot.new(gp) do |plot|
      plot.terminal "pngcairo size #{PLOT_SIZE}"
      plot.output File.join(OUTPUT_DIR, "deaths_per_#{NUMBERS_PER}.png")

      plot.xdata 'time'
      plot.timefmt '\'%Y-%m-%d\''

      plot.title 'Scottish Health Board COVID-19 Deaths'

      plot.key 'outside center bottom horizontal'

      plot.format 'x \'%d/%m/%y\''
      plot.xrange "['#{deaths.keys.first.strftime('%Y-%m-01')}':'#{Date.parse(deaths.keys.first.strftime('%Y-%m-01')).next_month.prev_day}']"

      plot.logscale 'y 10'
      plot.yrange '[0:]'
      plot.ylabel "Deaths per #{NUMBERS_PER.to_s.gsub(/\B(?=(...)*\b)/, ',')}"

      plot.grid

      data = Array.new(health_boards.count + 1) { [] }
      deaths.keys.sort.each do |date|
        data[0].push date.to_s
        health_boards.each.with_index do |health_board, index|
          data[index + 1].push cases.fetch(date).fetch(health_board)
        end
      end
  
      data[1..-1].each.with_index do |this_data, index|
        plot.add_data Gnuplot::DataSet.new([data[0], this_data]) { |ds|
          ds.using = '1:2'
          ds.with = 'line'
          ds.title = health_boards[index]
        }
      end
    end
  end

  health_boards.each do |health_board|
    $logger.info "Plotting data for #{health_board}."

    data = Array.new(3) { [] }
    cases.keys.sort.each do |date|
      data[0].push date
      data[1].push cases.dig(date, health_board)
      data[2].push deaths.dig(date, health_board)
    end

    if [data[1].reject(&:nil?).max, data[2].reject(&:nil?).max].all?(0.0)
      $logger.debug "#{health_board} has no cases or deaths."
      next
    end

    Gnuplot.open do |gp|
      Gnuplot::Plot.new(gp) do |plot|
        plot.terminal "pngcairo size #{PLOT_SIZE}"
        plot.output File.join(OUTPUT_DIR, "#{health_board.downcase.gsub(' ', '_')}_per_#{NUMBERS_PER}.png")

        plot.xdata 'time'
        plot.timefmt '\'%Y-%m-%d\''
  
        plot.title "COVID-19 in #{health_board} (per #{NUMBERS_PER.to_s.gsub(/\B(?=(...)*\b)/, ',')})"

        plot.key 'outside center bottom horizontal'
  
        plot.format 'x \'%d/%m/%y\''
        plot.xrange "['#{deaths.keys.first.strftime('%Y-%m-01')}':'#{Date.parse(deaths.keys.first.strftime('%Y-%m-01')).next_month.prev_day}']"
  
        plot.logscale 'y 10'
        plot.yrange '[0:]'

        plot.grid

        plot.add_data Gnuplot::DataSet.new([data[0], data[1]]) { |ds|
          ds.using = '1:2'
          ds.with = 'line'
          ds.title = 'Cases'
          ds.linewidth = 2
        }

        plot.add_data Gnuplot::DataSet.new([data[0], data[2]]) { |ds|
          ds.using = '1:2'
          ds.with = 'line'
          ds.title = 'Deaths'
          ds.linewidth = 2
        }
      end
    end
  end

  health_boards.each do |health_board|
    $logger.info "Plotting comparison data for #{health_board}."

    data = Array.new(3) { [] }
    cases.keys.sort.each do |date|
      data[0].push date
      data[1].push cases.dig(date, health_board) ? cases.dig(date, health_board) / cases.dig(date, 'Grand Total') : nil
      data[2].push deaths.dig(date, health_board) ? deaths.dig(date, health_board) / deaths.dig(date, 'Grand Total') : nil
    end

    Gnuplot.open do |gp|
      Gnuplot::Plot.new(gp) do |plot|
        plot.terminal "pngcairo size #{PLOT_SIZE}"
        plot.output File.join(OUTPUT_DIR, "#{health_board.downcase.gsub(' ', '_')}_vs_scotland.png")

        plot.xdata 'time'
        plot.timefmt '\'%Y-%m-%d\''
  
        plot.title "COVID-19 in #{health_board} vs Scotland"
  
        plot.key 'outside center bottom horizontal'
  
        plot.format 'x \'%d/%m/%y\''
        plot.xrange "['#{deaths.keys.first.strftime('%Y-%m-01')}':'#{Date.parse(deaths.keys.first.strftime('%Y-%m-01')).next_month.prev_day}']"
  
        plot.yrange '[0:]'
        plot.ylabel "#{health_board} per #{NUMBERS_PER.to_s.gsub(/\B(?=(...)*\b)/, ',')} ÷ National per #{NUMBERS_PER.to_s.gsub(/\B(?=(...)*\b)/, ',')}"
  
        plot.grid

        # plot 1 lw 1 lt rgb '#88ff88',
        plot.add_data Gnuplot::DataSet.new('1') { |ds|
          ds.linewidth = 1
          ds.title = ''
        }

        plot.add_data Gnuplot::DataSet.new([data[0], data[1]]) { |ds|
          ds.using = '1:2'
          ds.with = 'line'
          ds.title = 'Cases'
          ds.linewidth = 2
        }

        plot.add_data Gnuplot::DataSet.new([data[0], data[2]]) { |ds|
          ds.using = '1:2'
          ds.with = 'line'
          ds.title = 'Deaths'
          ds.linewidth = 2
        }
      end
    end
  end

  $logger.info 'Updating index file'
  File.write(
    File.join(OUTPUT_DIR, 'index.html'),
    Haml::Engine.new(File.read(File.join(__dir__, 'index.haml')))
                .render(self, {numbers_per: NUMBERS_PER, upto: cases.keys.last, health_boards: health_boards})
  )
end
