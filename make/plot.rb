# frozen_string_literal: true

module Make
  class Plot
    PLOT_SIZE = '900,600'

    def self.all(**options)
      scotland **options
      health_boards **options
      nil
    end

    def self.health_boards(**options)
      ScotlandCovid19Data.health_boards.each do |health_board|
        health_board health_board, **options
        health_board_comparison health_board, **options
      end
      nil
    end

    def self.scotland(**options)
      scotland_daily_tests **options
      scotland_cumulative_tests **options
      scotland_cases_by_health_board **options
      scotland_deaths_by_health_board **options
      scotland_deceased_and_icu **options
      scotland_vs_uk **options
    end

    def self.scotland_daily_tests(**options)
      $logger.info 'Plotting daily test data for Scotland.'
      tests = ScotlandCovid19Data.tests
      data = tests.values
                  .sort_by { |record| record['Date'] }
                  .map { |record| [record['Date'], record['Today Negative'], record['Today Positive']] }
                  .transpose

      basic_plot(**options, filename: 'daily_tests.png') do |plot|
        plot.title 'Scottish COVID-19 Daily Tests'
        plot.xrange "['#{tests.keys.first.strftime('%Y-%m-01')}':'#{Date.parse(tests.keys.last.strftime('%Y-%m-01')).next_month.prev_day}']"

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

    def self.scotland_cumulative_tests(**options)
      $logger.info 'Plotting cumulative test data for Scotland.'
      tests = ScotlandCovid19Data.tests
      data = tests.values
                  .sort_by { |record| record['Date'] }
                  .map { |record| [record['Date'], record['Total Negative'], record['Total Positive'] + record['Total Negative']] }
                  .transpose

      basic_plot(**options, filename: 'cumulative_tests.png') do |plot|
        plot.title 'Scottish COVID-19 Cumulative Tests'
        plot.xrange "['#{tests.keys.first.strftime('%Y-%m-01')}':'#{Date.parse(tests.keys.last.strftime('%Y-%m-01')).next_month.prev_day}']"

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

    def self.scotland_cases_by_health_board(**options)
      $logger.info 'Plotting cases by health board data for Scotland.'
      cases = ScotlandCovid19Data.cases
      health_boards = ScotlandCovid19Data.health_boards
      data = cases.sort_by { |key, value| key }
                  .map { |key, value| [key.to_s, *value.sort_by(&:first).map(&:last)] }
                  .transpose

      basic_plot(**options, filename: "cases_per_#{NUMBERS_PER}.png") do |plot|
        plot.title 'Scottish Health Board COVID-19 Cases'
        plot.xrange "['#{Date.parse(data[0].first).strftime('%Y-%m-01')}':'#{Date.parse(Date.parse(data[0].last).strftime('%Y-%m-01')).next_month.prev_day}']"
        plot.logscale 'y 10'

        data[1..-2].each.with_index do |this_data, index|
          plot.add_data Gnuplot::DataSet.new([data[0], this_data]) { |ds|
            ds.using = '1:2'
            ds.with = 'line'
            ds.title = health_boards[index]
          }
        end
      end
    end

    def self.scotland_deaths_by_health_board(**options)
      $logger.info 'Plotting deaths by health board data for Scotland.'
      deaths = ScotlandCovid19Data.deaths
      health_boards = ScotlandCovid19Data.health_boards
      data = deaths.sort_by { |key, value| key }
                   .map { |key, value| [key.to_s, *value.sort_by(&:first).map(&:last)] }
                   .transpose

      basic_plot(**options, filename: "deaths_per_#{NUMBERS_PER}.png") do |plot|
        plot.title 'Scottish Health Board COVID-19 Deaths'
        plot.xrange "['#{Date.parse(data[0].first).strftime('%Y-%m-01')}':'#{Date.parse(Date.parse(data[0].last).strftime('%Y-%m-01')).next_month.prev_day}']"
        plot.logscale 'y 10'

        data[1..-2].each.with_index do |this_data, index|
          plot.add_data Gnuplot::DataSet.new([data[0], this_data]) { |ds|
            ds.using = '1:2'
            ds.with = 'line'
            ds.title = health_boards[index]
          }
        end
      end
    end

    def self.scotland_deceased_and_icu(**options)
      $logger.info 'Plotting deceased and ICU data for Scotland.'
      deceased = ScotlandCovid19Data.deceased
      intensive_care = ScotlandCovid19Data.intensive_care
      earliest_date = [deceased.keys.min, intensive_care.keys.min].min
      latest_date = [deceased.keys.max, intensive_care.keys.max].max
      data = (earliest_date..latest_date).map { |date| [date, intensive_care[date], deceased[date]] }
                                         .transpose


      basic_plot(**options, filename: 'icu_deceased.png') do |plot|
        plot.title 'Scottish COVID-19 Cumulative Deceased and Intensive Care Use'
        plot.xrange "['#{earliest_date.strftime('%Y-%m-01')}':'#{Date.parse(latest_date.strftime('%Y-%m-01')).next_month.prev_day}']"
        plot.logscale 'y 10'

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

    def self.scotland_vs_uk(**options)
      $logger.info 'Plotting Scotland vs UK data.'
      uk_data = UkCovid19Data.uk
      scotland_data = UkCovid19Data.scotland
      data = Array.new(3) { [] }
      scotland_data.keys.sort.each do |date|
        next unless uk_data[date]

        data[0].push date
        data[1].push scotland_data.dig(date, :confirmed_cases) / uk_data.dig(date, :confirmed_cases)
        data[2].push scotland_data.dig(date, :deaths) / uk_data.dig(date, :deaths)
      end

      comparrison_plot(**options, filename: 'scotland_vs_uk.png') do |plot|
        plot.title 'Scotland vs UK'
        plot.xrange "['#{data[0].first.strftime('%Y-%m-01')}':'#{Date.parse(data[0].last.strftime('%Y-%m-01')).next_month.prev_day}']"

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

    def self.health_board(name, **options)
      fail "#{name.inspect} is not a known health board" unless ScotlandCovid19Data.health_boards.include?(name)

      $logger.info "Plotting health board data for #{name}."

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

      basic_plot(**options, filename: "#{name.downcase.gsub(' ', '_')}_per_#{NUMBERS_PER}.png") do |plot|
        plot.title "COVID-19 in #{name} (per #{NUMBERS_PER.to_s.gsub(/\B(?=(...)*\b)/, ',')})"
        plot.xrange "['#{data[0].first.strftime('%Y-%m-01')}':'#{Date.parse(data[0].last.strftime('%Y-%m-01')).next_month.prev_day}']"
        plot.logscale 'y 10'

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
    
    def self.health_board_comparison(name, **options)
      $logger.info "Plotting #{name} vs Scotland data."

      cases = ScotlandCovid19Data.cases
      deaths = ScotlandCovid19Data.deaths
      data = Array.new(3) { [] }
      cases.keys.sort.each do |date|
        data[0].push date
        data[1].push cases.dig(date, name) ? cases.dig(date, name) / cases.dig(date, 'Grand Total') : nil
        data[2].push deaths.dig(date, name) ? deaths.dig(date, name) / deaths.dig(date, 'Grand Total') : nil
      end

      comparrison_plot(**options, filename: "#{name.downcase.gsub(' ', '_')}_vs_scotland.png") do |plot|
        plot.title "COVID-19 in #{name} vs Scotland"
        plot.xrange "['#{data[0].first.strftime('%Y-%m-01')}':'#{Date.parse(data[0].last.strftime('%Y-%m-01')).next_month.prev_day}']"
        plot.ylabel "#{name} per #{NUMBERS_PER.to_s.gsub(/\B(?=(...)*\b)/, ',')} ÷ Scotland per #{NUMBERS_PER.to_s.gsub(/\B(?=(...)*\b)/, ',')}"

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

    class << self
      private

      def basic_plot(target: :file, filename: nil)
        Gnuplot.open do |gp|
          Gnuplot::Plot.new(gp) do |plot|
            case target
            when :file
              fail ArgumentError, 'filename must be passed when target is :file' unless filename
              plot.terminal "pngcairo size #{PLOT_SIZE}"
              plot.output File.join(PUBLIC_DIR, filename)
            when :screen
              plot.terminal "wxt size #{PLOT_SIZE} persist"
            else
              fail "#{target.inspect} is not a valid target."
            end

            plot.xdata 'time'
            plot.timefmt '\'%Y-%m-%d\''
            plot.key 'outside center bottom horizontal'
            plot.format 'x \'%d/%m/%y\''
            plot.yrange '[0:]'
            plot.grid

            yield plot
          end
        end
        nil
      end

      def comparrison_plot(**options)
        basic_plot(**options) do |plot|
          # plot 1 lw 1 lt rgb '#88ff88',
          plot.add_data Gnuplot::DataSet.new('1') { |ds|
            ds.linewidth = 1
            ds.title = ''
          }

          yield plot
        end
        nil
      end
    end
  end
end
