# frozen_string_literal: true

module Make
  class Plot
    PLOT_SIZE = '900,600'

    def self.all(**options)
      uk **options
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
      country_comparison 'Scotland', **options
    end

    def self.scotland_daily_tests(**options)
      $logger.info 'Plotting daily test data for Scotland.'
      tests = ScotlandCovid19Data.tests
      data = tests.values
                  .sort_by { |record| record['Date'] }
                  .map { |record| [record['Date'], record['Today Negative'], record['Today Positive']] }
                  .transpose

      basic_plot(**options, filename: 'scotland_daily_tests.png') do |plot|
        plot.title 'Scottish COVID-19 Daily Tests'

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

      basic_plot(**options, filename: 'scotland_cumulative_tests.png') do |plot|
        plot.title 'Scottish COVID-19 Cumulative Tests'

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

      basic_plot(**options, filename: "scotland_cases_per_#{NUMBERS_PER}.png") do |plot|
        plot.title 'Scottish Health Board COVID-19 Cases'
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

      basic_plot(**options, filename: "scotland_deaths_per_#{NUMBERS_PER}.png") do |plot|
        plot.title 'Scottish Health Board COVID-19 Deaths'
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


      basic_plot(**options, filename: 'scotland_icu_deceased.png') do |plot|
        plot.title 'Scottish COVID-19 Cumulative Deceased and Intensive Care Use'
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
      fail "#{name.inspect} is not a known health board" unless ScotlandCovid19Data.health_boards.include?(name)

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

    def self.uk(**options)
      uk_cases_by_country **options
      uk_deaths_by_country **options
      country_comparison 'England', **options
      country_comparison 'Scotland', **options
      country_comparison 'Wales', **options
      country_comparison 'Northern Ireland', **options
    end

    def self.uk_cases_by_country(**options)
      $logger.info 'Plotting cases by country data for UK.'
      england = UkCovid19Data.england
      scotland = UkCovid19Data.scotland
      wales = UkCovid19Data.wales
      northern_ireland = UkCovid19Data.northern_ireland
      start_date = [england.keys.min, scotland.keys.min, wales.keys.min, northern_ireland.keys.min].min
      finish_date = [england.keys.max, scotland.keys.max, wales.keys.max, northern_ireland.keys.max].max

      data = Array.new(5) { Array.new(finish_date - start_date) }
      (start_date..finish_date).each do |date|
        data[0].push date
        data[1].push england.dig(date, :confirmed_cases)
        data[2].push scotland.dig(date, :confirmed_cases)
        data[3].push wales.dig(date, :confirmed_cases)
        data[4].push northern_ireland.dig(date, :confirmed_cases)
      end

      basic_plot(**options, filename: "uk_cases_per_#{NUMBERS_PER}.png") do |plot|
        plot.title 'UK COVID-19 Cases'
        plot.logscale 'y 10'

        plot.add_data Gnuplot::DataSet.new([data[0], data[1]]) { |ds|
          ds.using = '1:2'
          ds.with = 'line'
          ds.title = 'England'
          ds.linewidth = 2
          ds.linecolor = 'rgb "red"'
        }

        plot.add_data Gnuplot::DataSet.new([data[0], data[2]]) { |ds|
          ds.using = '1:2'
          ds.with = 'line'
          ds.title = 'Scotland'
          ds.linewidth = 2
          ds.linecolor = 'rgb "blue"'
        }

        plot.add_data Gnuplot::DataSet.new([data[0], data[3]]) { |ds|
          ds.using = '1:2'
          ds.with = 'line'
          ds.title = 'Wales'
          ds.linewidth = 2
          ds.linecolor = 'rgb "green"'
        }

        plot.add_data Gnuplot::DataSet.new([data[0], data[4]]) { |ds|
          ds.using = '1:2'
          ds.with = 'line'
          ds.title = 'Northern Ireland'
          ds.linewidth = 2
          ds.linecolor = 'rgb "cyan"'
        }
      end
    end

    def self.uk_deaths_by_country(**options)
      $logger.info 'Plotting cases by country data for UK.'
      england = UkCovid19Data.england
      scotland = UkCovid19Data.scotland
      wales = UkCovid19Data.wales
      northern_ireland = UkCovid19Data.northern_ireland
      start_date = [england.keys.min, scotland.keys.min, wales.keys.min, northern_ireland.keys.min].min
      finish_date = [england.keys.max, scotland.keys.max, wales.keys.max, northern_ireland.keys.max].max

      data = Array.new(5) { Array.new(finish_date - start_date) }
      (start_date..finish_date).each do |date|
        data[0].push date
        data[1].push england.dig(date, :deaths)
        data[2].push scotland.dig(date, :deaths)
        data[3].push wales.dig(date, :deaths)
        data[4].push northern_ireland.dig(date, :deaths)
      end

      basic_plot(**options, filename: "uk_deaths_per_#{NUMBERS_PER}.png") do |plot|
        plot.title 'UK COVID-19 Deaths'
        plot.logscale 'y 10'

        plot.add_data Gnuplot::DataSet.new([data[0], data[1]]) { |ds|
          ds.using = '1:2'
          ds.with = 'line'
          ds.title = 'England'
          ds.linewidth = 2
          ds.linecolor = 'rgb "red"'
        }

        plot.add_data Gnuplot::DataSet.new([data[0], data[2]]) { |ds|
          ds.using = '1:2'
          ds.with = 'line'
          ds.title = 'Scotland'
          ds.linewidth = 2
          ds.linecolor = 'rgb "blue"'
        }

        plot.add_data Gnuplot::DataSet.new([data[0], data[3]]) { |ds|
          ds.using = '1:2'
          ds.with = 'line'
          ds.title = 'Wales'
          ds.linewidth = 2
          ds.linecolor = 'rgb "green"'
        }

        plot.add_data Gnuplot::DataSet.new([data[0], data[4]]) { |ds|
          ds.using = '1:2'
          ds.with = 'line'
          ds.title = 'Northern Ireland'
          ds.linewidth = 2
          ds.linecolor = 'rgb "cyan"'
        }
      end
    end

    def self.country_comparison(name, **options)
      unless ['England', 'Scotland', 'Wales', 'Northern Ireland'].include?(name)
        fail "#{name.inspect} is not a known country"
      end

      $logger.info "Plotting #{name} vs Scotland data."

      uk = UkCovid19Data.uk
      country = UkCovid19Data.send name.downcase.gsub(' ', '_')
      start_date = [uk.keys.min, country.keys.min].max
      finish_date = [uk.keys.max, country.keys.max].min

      data = Array.new(3) { [] }
      (start_date..finish_date).each do |date|
        next unless uk.dig(date, :confirmed_cases) &&
                    uk.dig(date, :deaths) &&
                    country.dig(date, :confirmed_cases) &&
                    country.dig(date, :deaths)

        data[0].push date
        data[1].push country.dig(date, :confirmed_cases) / uk.dig(date, :confirmed_cases)
        data[2].push country.dig(date, :deaths) / uk.dig(date, :deaths)
      end

      comparrison_plot(**options, filename: "#{name.downcase.gsub(' ', '_')}_vs_uk.png") do |plot|
        plot.title "COVID-19 in #{name} vs the UK"
        plot.ylabel "#{name} per #{NUMBERS_PER.to_s.gsub(/\B(?=(...)*\b)/, ',')} ÷ UK per #{NUMBERS_PER.to_s.gsub(/\B(?=(...)*\b)/, ',')}"

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
            plot.format 'x \'%d/%m/%y\''
            plot.xrange "['#{Date.new(2020, 2, 17)}':'#{Date.today}']"

            plot.yrange '[0:]'

            plot.key 'outside center bottom horizontal'
            plot.grid

            yield plot
          end
        end
        nil
      end

      def comparrison_plot(**options)
        basic_plot(**options) do |plot|
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
