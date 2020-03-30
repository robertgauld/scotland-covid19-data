# frozen_string_literal: true

module Make
  class Plot
    PLOT_SIZE = '900,600'

    def self.scotland(target: :file)
      $logger.info 'Plotting data for Scotland.'
      Gnuplot.open do |gp|
        Gnuplot::Plot.new(gp) do |plot|
          cases = ScotlandCovid19Data.cases
          health_boards = ScotlandCovid19Data.health_boards

          case target
          when :file
            plot.terminal "pngcairo size #{PLOT_SIZE}"
            plot.output File.join(PUBLIC_DIR, "cases_per_#{NUMBERS_PER}.png")
          when :screen
            plot.terminal "wxt size #{PLOT_SIZE} persist"
          else
            fail "#{target.inspect} is not a valid target."
          end

          plot.xdata 'time'
          plot.timefmt '\'%Y-%m-%d\''

          plot.title 'Scottish Health Board COVID-19 Cases'

          plot.key 'outside center bottom horizontal'

          plot.format 'x \'%d/%m/%y\''
          plot.xrange "['#{cases.keys.first.strftime('%Y-%m-01')}':'#{Date.parse(cases.keys.last.strftime('%Y-%m-01')).next_month.prev_day}']"

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
          deaths = ScotlandCovid19Data.deaths
          health_boards = ScotlandCovid19Data.health_boards

          case target
          when :file
            plot.terminal "pngcairo size #{PLOT_SIZE}"
            plot.output File.join(PUBLIC_DIR, "deaths_per_#{NUMBERS_PER}.png")
          when :screen
            plot.terminal "wxt size #{PLOT_SIZE} persist"
          else
            fail "#{target.inspect} is not a valid target."
          end

          plot.xdata 'time'
          plot.timefmt '\'%Y-%m-%d\''

          plot.title 'Scottish Health Board COVID-19 Deaths'

          plot.key 'outside center bottom horizontal'

          plot.format 'x \'%d/%m/%y\''
          plot.xrange "['#{deaths.keys.first.strftime('%Y-%m-01')}':'#{Date.parse(deaths.keys.last.strftime('%Y-%m-01')).next_month.prev_day}']"

          plot.logscale 'y 10'
          plot.yrange '[0:]'
          plot.ylabel "Deaths per #{NUMBERS_PER.to_s.gsub(/\B(?=(...)*\b)/, ',')}"

          plot.grid

          data = deaths.sort_by { |key, value| key }
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
          deceased = ScotlandCovid19Data.deceased
          intensive_care = ScotlandCovid19Data.intensive_care
          earliest_date = [deceased.keys.min, intensive_care.keys.min].min
          latest_date = [deceased.keys.max, intensive_care.keys.max].max

          case target
          when :file
            plot.terminal "pngcairo size #{PLOT_SIZE}"
            plot.output File.join(PUBLIC_DIR, 'icu_deceased.png')
          when :screen
            plot.terminal "wxt size #{PLOT_SIZE} persist"
          else
            fail "#{target.inspect} is not a valid target."
          end

          plot.xdata 'time'
          plot.timefmt '\'%Y-%m-%d\''

          plot.title 'Scottish COVID-19 Cumulative Deceased and Intensive Care Use'

          plot.key 'outside center bottom horizontal'

          plot.format 'x \'%d/%m/%y\''
          plot.xrange "['#{earliest_date.strftime('%Y-%m-01')}':'#{Date.parse(latest_date.strftime('%Y-%m-01')).next_month.prev_day}']"

          plot.logscale 'y 10'
          plot.yrange '[0:]'

          plot.grid

          data = (earliest_date..latest_date).map { |date| [date, intensive_care[date], deceased[date]] }
                                             .transpose

          plot.add_data Gnuplot::DataSet.new([data[0], data[1]]) { |ds|
            ds.using = '1:2'
            ds.with = 'line'
            ds.title = 'Patients in intensive care'
          }

          plot.add_data Gnuplot::DataSet.new([data[0], data[2]]) { |ds|
            ds.using = '1:2'
            ds.with = 'line'
            ds.title = 'Cumulative deceased'
          }
        end
      end

      Gnuplot.open do |gp|
        Gnuplot::Plot.new(gp) do |plot|
          tests = ScotlandCovid19Data.tests

          case target
          when :file
            plot.terminal "pngcairo size #{PLOT_SIZE}"
            plot.output File.join(PUBLIC_DIR, 'cumulative_tests.png')
          when :screen
            plot.terminal "wxt size #{PLOT_SIZE} persist"
          else
            fail "#{target.inspect} is not a valid target."
          end

          plot.xdata 'time'
          plot.timefmt '\'%Y-%m-%d\''

          plot.title 'Scottish COVID-19 Cumulative Tests'

          plot.key 'outside center bottom horizontal'

          plot.format 'x \'%d/%m/%y\''
          plot.xrange "['#{tests.keys.first.strftime('%Y-%m-01')}':'#{Date.parse(tests.keys.last.strftime('%Y-%m-01')).next_month.prev_day}']"

          plot.yrange '[0:]'

          plot.grid

          data = tests.values
                      .sort_by { |record| record['Date'] }
                      .map { |record| [record['Date'], record['Total Negative'], record['Total Positive'] + record['Total Negative']] }
                      .transpose

          plot.add_data Gnuplot::DataSet.new([data[0], data[2]]) { |ds|
            ds.using = '1:2'
            ds.with = 'filledcurve x1'
            ds.title = 'Positive'
          }

          plot.add_data Gnuplot::DataSet.new([data[0], data[1]]) { |ds|
            ds.using = '1:2'
            ds.with = 'filledcurve x1'
            ds.title = 'Negative'
          }
        end
      end

      Gnuplot.open do |gp|
        Gnuplot::Plot.new(gp) do |plot|
          tests = ScotlandCovid19Data.tests

          case target
          when :file
            plot.terminal "pngcairo size #{PLOT_SIZE}"
            plot.output File.join(PUBLIC_DIR, 'daily_tests.png')
          when :screen
            plot.terminal "wxt size #{PLOT_SIZE} persist"
          else
            fail "#{target.inspect} is not a valid target."
          end

          plot.xdata 'time'
          plot.timefmt '\'%Y-%m-%d\''

          plot.title 'Scottish COVID-19 Daily Tests'

          plot.key 'outside center bottom horizontal'

          plot.format 'x \'%d/%m/%y\''
          plot.xrange "['#{tests.keys.first.strftime('%Y-%m-01')}':'#{Date.parse(tests.keys.last.strftime('%Y-%m-01')).next_month.prev_day}']"

          plot.yrange '[0:]'

          plot.grid

          data = tests.values
                      .sort_by { |record| record['Date'] }
                      .map { |record| [record['Date'], record['Today Negative'], record['Today Positive']] }
                      .transpose

          plot.add_data Gnuplot::DataSet.new([data[0], data[2]]) { |ds|
            ds.using = '1:2'
            ds.with = 'line'
            ds.title = 'Positive'
          }

          plot.add_data Gnuplot::DataSet.new([data[0], data[1]]) { |ds|
            ds.using = '1:2'
            ds.with = 'line'
            ds.title = 'Negative'
          }
        end
      end

      Gnuplot.open do |gp|
        Gnuplot::Plot.new(gp) do |plot|
          uk_data = UkCovid19Data.uk
          scotland_data = UkCovid19Data.scotland
          data = Array.new(3) { [] }
          scotland_data.keys.sort.each do |date|
            next unless uk_data[date]

            data[0].push date
            data[1].push scotland_data.dig(date, :confirmed_cases) / uk_data.dig(date, :confirmed_cases)
            data[2].push scotland_data.dig(date, :deaths) / uk_data.dig(date, :deaths)
          end

          case target
          when :file
            plot.terminal "pngcairo size #{PLOT_SIZE}"
            plot.output File.join(PUBLIC_DIR, 'scotland_vs_uk.png')
          when :screen
            plot.terminal "wxt size #{PLOT_SIZE} persist"
          else
            fail "#{target.inspect} is not a valid target."
          end

          plot.xdata 'time'
          plot.timefmt '\'%Y-%m-%d\''

          plot.title 'Scotland vs UK'

          plot.key 'outside center bottom horizontal'

          plot.format 'x \'%d/%m/%y\''
          plot.xrange "['#{data[0].first.strftime('%Y-%m-01')}':'#{Date.parse(data[0].last.strftime('%Y-%m-01')).next_month.prev_day}']"

          plot.yrange '[0:]'
          plot.ylabel "Scotland per #{NUMBERS_PER.to_s.gsub(/\B(?=(...)*\b)/, ',')} ÷ UK per #{NUMBERS_PER.to_s.gsub(/\B(?=(...)*\b)/, ',')}"

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

    def self.health_board(name, target: :file)
      fail "#{name.inspect} is not a known health board" unless ScotlandCovid19Data.health_boards.include?(name)

      $logger.info "Plotting data for #{name}."

      cases = ScotlandCovid19Data.cases
      deaths = ScotlandCovid19Data.deaths
      data = Array.new(3) { [] }
      cases.keys.sort.each do |date|
        data[0].push date
        data[1].push cases.dig(date, name)
        data[2].push deaths.dig(date, name)
      end

      if [data[1].reject(&:nil?).max, data[2].reject(&:nil?).max].all?(0.0)
        $logger.debug "#{name} has no cases or deaths."
        return
      end

      Gnuplot.open do |gp|
        Gnuplot::Plot.new(gp) do |plot|
          case target
          when :file
            plot.terminal "pngcairo size #{PLOT_SIZE}"
            plot.output File.join(PUBLIC_DIR, "#{name.downcase.gsub(' ', '_')}_per_#{NUMBERS_PER}.png")
          when :screen
            plot.terminal "wxt size #{PLOT_SIZE} persist"
          else
            fail "#{target.inspect} is not a valid target."
          end

          plot.xdata 'time'
          plot.timefmt '\'%Y-%m-%d\''

          plot.title "COVID-19 in #{name} (per #{NUMBERS_PER.to_s.gsub(/\B(?=(...)*\b)/, ',')})"

          plot.key 'outside center bottom horizontal'

          plot.format 'x \'%d/%m/%y\''
          plot.xrange "['#{data[0].first.strftime('%Y-%m-01')}':'#{Date.parse(data[0].last.strftime('%Y-%m-01')).next_month.prev_day}']"

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
    
    def self.health_board_comparison(name, target: :file)
      $logger.info "Plotting comparison data for #{name}."

      cases = ScotlandCovid19Data.cases
      deaths = ScotlandCovid19Data.deaths
      data = Array.new(3) { [] }
      cases.keys.sort.each do |date|
        data[0].push date
        data[1].push cases.dig(date, name) ? cases.dig(date, name) / cases.dig(date, 'Grand Total') : nil
        data[2].push deaths.dig(date, name) ? deaths.dig(date, name) / deaths.dig(date, 'Grand Total') : nil
      end

      Gnuplot.open do |gp|
        Gnuplot::Plot.new(gp) do |plot|
          case target
          when :file
            plot.terminal "pngcairo size #{PLOT_SIZE}"
            plot.output File.join(PUBLIC_DIR, "#{name.downcase.gsub(' ', '_')}_vs_scotland.png")
          when :screen
            plot.terminal "wxt size #{PLOT_SIZE} persist"
          else
            fail "#{target.inspect} is not a valid target."
          end

          plot.xdata 'time'
          plot.timefmt '\'%Y-%m-%d\''

          plot.title "COVID-19 in #{name} vs Scotland"

          plot.key 'outside center bottom horizontal'

          plot.format 'x \'%d/%m/%y\''
          plot.xrange "['#{data[0].first.strftime('%Y-%m-01')}':'#{Date.parse(data[0].last.strftime('%Y-%m-01')).next_month.prev_day}']"

          plot.yrange '[0:]'
          plot.ylabel "#{name} per #{NUMBERS_PER.to_s.gsub(/\B(?=(...)*\b)/, ',')} ÷ Scotland per #{NUMBERS_PER.to_s.gsub(/\B(?=(...)*\b)/, ',')}"

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
  end
end
