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
      scotland_icu_deceased **options
      country_comparison 'Scotland', **options
    end

    def self.scotland_daily_tests(**options)
      $logger.info 'Plotting daily test data for Scotland.'
      data = Make::Data.scotland_tests.transpose

      basic_plot(**options, filename: 'scotland_daily_tests.png') do |plot|
        plot.title 'Scottish COVID-19 Daily Tests'

        plot.add_data Gnuplot::DataSet.new([data[0], data[1]]) { |ds|
          ds.using = '1:2'
          ds.with = 'line'
          ds.title = 'Positive'
        }

        plot.add_data Gnuplot::DataSet.new([data[0], data[2]]) { |ds|
          ds.using = '1:2'
          ds.with = 'line'
          ds.title = 'Negative'
        }
      end
    end

    def self.scotland_cumulative_tests(**options)
      $logger.info 'Plotting cumulative test data for Scotland.'
      data = Make::Data.scotland_tests
                       .map { |record| record.push record[3] + record[4] }
                       .transpose

      basic_plot(**options, filename: 'scotland_cumulative_tests.png') do |plot|
        plot.title 'Scottish COVID-19 Cumulative Tests'

        plot.add_data Gnuplot::DataSet.new([data[0], data[5]]) { |ds|
          ds.using = '1:2'
          ds.with = 'filledcurve x1'
          ds.title = 'Positive'
        }

        plot.add_data Gnuplot::DataSet.new([data[0], data[4]]) { |ds|
          ds.using = '1:2'
          ds.with = 'filledcurve x1'
          ds.title = 'Negative'
        }
      end
    end

    def self.scotland_cases_by_health_board(**options)
      $logger.info 'Plotting cases by health board data for Scotland.'
      health_boards = ScotlandCovid19Data.health_boards
      data = Make::Data.scotland_cases_by_health_board.transpose

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
      health_boards = ScotlandCovid19Data.health_boards
      data = Make::Data.scotland_deaths_by_health_board.transpose

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

    def self.scotland_icu_deceased(**options)
      $logger.info 'Plotting deceased and ICU data for Scotland.'
      data = Make::Data.scotland_icu_deceased.transpose

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
      data = Make::Data.health_board(name).transpose

      if [data[1].reject(&:nil?).max, data[2].reject(&:nil?).max].all?(0.0)
        $logger.debug "#{name} has no cases."
        if options[:target] && options[:target] != :file
          return "#{name} has no cases."
        else
          FileUtils.copy(
            File.join(ROOT_DIR, 'template', 'no_cases.png'),
            File.join(PUBLIC_DIR, "#{name.downcase.gsub(' ', '_')}_per_#{NUMBERS_PER}.png")
          )
        end
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
      data = Make::Data.health_board(name).transpose

      comparrison_plot(**options, filename: "#{name.downcase.gsub(' ', '_')}_vs_scotland.png") do |plot|
        plot.title "COVID-19 in #{name} vs Scotland"
        plot.ylabel "#{name} per #{NUMBERS_PER.to_s.gsub(/\B(?=(...)*\b)/, ',')} ÷ Scotland per #{NUMBERS_PER.to_s.gsub(/\B(?=(...)*\b)/, ',')}"

        plot.add_data Gnuplot::DataSet.new([data[0], data[3]]) { |ds|
          ds.using = '1:2'
          ds.with = 'line'
          ds.title = 'Cases'
          ds.linewidth = 2
        }

        plot.add_data Gnuplot::DataSet.new([data[0], data[4]]) { |ds|
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
      data = Make::Data.uk_cases.transpose

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
      data = Make::Data.uk_deaths.transpose

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

      $logger.info "Plotting #{name} vs UK data."
      data = Make::Data.country(name).transpose

      comparrison_plot(**options, filename: "#{name.downcase.gsub(' ', '_')}_vs_uk.png") do |plot|
        plot.title "COVID-19 in #{name} vs the UK"
        plot.ylabel "#{name} per #{NUMBERS_PER.to_s.gsub(/\B(?=(...)*\b)/, ',')} ÷ UK per #{NUMBERS_PER.to_s.gsub(/\B(?=(...)*\b)/, ',')}"

        plot.add_data Gnuplot::DataSet.new([data[0], data[3]]) { |ds|
          ds.using = '1:2'
          ds.with = 'line'
          ds.title = 'Cases'
          ds.linewidth = 2
        }

        plot.add_data Gnuplot::DataSet.new([data[0], data[4]]) { |ds|
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
