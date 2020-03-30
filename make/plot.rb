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
          plot.xrange "['#{deaths.keys.first.strftime('%Y-%m-01')}':'#{Date.parse(deaths.keys.first.strftime('%Y-%m-01')).next_month.prev_day}']"

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
          plot.xrange "['#{deaths.keys.first.strftime('%Y-%m-01')}':'#{Date.parse(deaths.keys.first.strftime('%Y-%m-01')).next_month.prev_day}']"

          plot.yrange '[0:]'
          plot.ylabel "#{name} per #{NUMBERS_PER.to_s.gsub(/\B(?=(...)*\b)/, ',')} ÷ National per #{NUMBERS_PER.to_s.gsub(/\B(?=(...)*\b)/, ',')}"

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
