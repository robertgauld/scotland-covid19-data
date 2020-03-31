# frozen_string_literal: true

module Make
  class Csv
    def self.all(**options)
      uk_cases **options
      uk_deaths **options
      scotland **options
      health_boards **options
      country('England', **options)
      country('Scotland', **options)
      country('Wales', **options)
      country('Northern Ireland', **options)
      nil
    end

    def self.health_boards(**options)
      ScotlandCovid19Data.health_boards.each do |health_board|
        health_board health_board, **options
      end
      nil
    end

    def self.scotland(**options)
      scotland_cases **options
      scotland_deaths **options
      scotland_icu_deceased **options
      scotland_tests **options
    end

    def self.scotland_cases
      $logger.info 'Writing cases CSV for Scotland.'
      health_boards = ScotlandCovid19Data.health_boards
      cases = ScotlandCovid19Data.cases

      data = CSV::Table.new([], headers: ['Date', *health_boards, 'Grand Total'])  
      cases.keys.sort.each do |date|
        data.push [date, *cases.fetch(date).values_at(*health_boards, 'Grand Total')]
      end
      File.write(File.join(PUBLIC_DIR, "scotland_cases_per_#{NUMBERS_PER}.csv"), data.to_csv)
    end

    def self.scotland_deaths
      $logger.info 'Writing deaths CSV for Scotland.'
      health_boards = ScotlandCovid19Data.health_boards
      deaths = ScotlandCovid19Data.deaths

      data = CSV::Table.new([], headers: ['Date', *health_boards, 'Grand Total'])  
      deaths.keys.sort.each do |date|
        data.push [date, *deaths.fetch(date).values_at(*health_boards, 'Grand Total')]
      end
      File.write(File.join(PUBLIC_DIR, "scotland_deaths_per_#{NUMBERS_PER}.csv"), data.to_csv)
    end

    def self.scotland_icu_deceased(**options)
      $logger.info 'Writing ICU and deceased CSV for Scotland.'
      intensive_care = ScotlandCovid19Data.intensive_care
      deceased = ScotlandCovid19Data.deceased

      earliest_date = [deceased.keys.min, intensive_care.keys.min].min
      latest_date = [deceased.keys.max, intensive_care.keys.max].max

      data = CSV::Table.new([], headers: ['Date', 'Patients in intensive care', 'Cumulative deceased'])  
      (earliest_date..latest_date).each do |date|
        data.push [date, intensive_care[date], deceased[date]]
      end
      File.write(File.join(PUBLIC_DIR, 'scotland_icu_deceased.csv'), data.to_csv)
    end

    def self.scotland_tests(**options)
      $logger.info 'Writing tests CSV for Scotland.'
      tests = ScotlandCovid19Data.tests


      data = CSV::Table.new([], headers: ['Date', 'Positive', 'Negative', 'Cumulative Positive', 'Cumulative Negative'])  
      tests.values.sort_by { |record| record['Date'] }.each do |record|
        data.push record.values_at('Date', 'Today Positive', 'Today Negative', 'Total Positive', 'Total Negative')
      end
      File.write(File.join(PUBLIC_DIR, 'scotland_tests.csv'), data.to_csv)
    end

    def self.health_board(name)
      fail "#{name.inspect} is not a known health board" unless ScotlandCovid19Data.health_boards.include?(name)
      $logger.info "Writing health board CSV for #{name}."
      cases = ScotlandCovid19Data.cases
      deaths = ScotlandCovid19Data.deaths
      data = CSV::Table.new([], headers: ['Date', 'Cases', 'Deaths', 'Cases Ratio', 'Deaths Ratio'])

      cases.keys.sort.each do |date|
        data.push [
          date,
          cases.dig(date, name),
          deaths.dig(date, name),
          cases.dig(date, name) ? cases.dig(date, name) / cases.dig(date, 'Grand Total') : nil,
          deaths.dig(date, name) ? deaths.dig(date, name) / deaths.dig(date, 'Grand Total') : nil
        ]
      end

      File.write(
        File.join(PUBLIC_DIR, "#{name.downcase.gsub(' ', '_')}_per_#{NUMBERS_PER}.csv"),
        data.to_csv
      )
    end

    def self.country(name)
      unless ['England', 'Scotland', 'Wales', 'Northern Ireland'].include?(name)
        fail "#{name.inspect} is not a known country"
      end

      $logger.info "Writing country CSV for #{name}."

      uk = UkCovid19Data.uk
      country = UkCovid19Data.send name.downcase.gsub(' ', '_')
      start_date = [uk.keys.min, country.keys.min].max
      finish_date = [uk.keys.max, country.keys.max].min


      data = CSV::Table.new([], headers: ['Date', 'Cases', 'Deaths', 'Cases Ratio', 'Deaths Ratio'])
      (start_date..finish_date).each do |date|
        next unless uk.dig(date, :confirmed_cases) &&
                    uk.dig(date, :deaths) &&
                    country.dig(date, :confirmed_cases) &&
                    country.dig(date, :deaths)

        data.push [
          date,
          country.dig(date, :confirmed_cases),
          country.dig(date, :deaths),
          country.dig(date, :confirmed_cases) / uk.dig(date, :confirmed_cases),
          country.dig(date, :deaths) / uk.dig(date, :deaths)
        ]
      end

      File.write(File.join(PUBLIC_DIR, "#{name.downcase.gsub(' ', '_')}_per_#{NUMBERS_PER}.csv"), data.to_csv)
    end

    def self.uk_cases
      $logger.info 'Writing cases CSV for UK.'
      uk = UkCovid19Data.uk
      england = UkCovid19Data.england
      scotland = UkCovid19Data.scotland
      wales = UkCovid19Data.wales
      northern_ireland = UkCovid19Data.northern_ireland
      start_date = [england.keys.min, scotland.keys.min, wales.keys.min, northern_ireland.keys.min].min
      finish_date = [england.keys.max, scotland.keys.max, wales.keys.max, northern_ireland.keys.max].max

      data = CSV::Table.new([], headers: ['Date', 'England', 'Scotland', 'Wales', 'Northern', 'Grand Total'])  
      (start_date..finish_date).each do |date|
        data.push [
          date,
          england.dig(date, :confirmed_cases),
          scotland.dig(date, :confirmed_cases),
          wales.dig(date, :confirmed_cases),
          northern_ireland.dig(date, :confirmed_cases),
          uk.dig(date, :confirmed_cases),
        ]
      end

      File.write(File.join(PUBLIC_DIR, "uk_cases_per_#{NUMBERS_PER}.csv"), data.to_csv)
    end

    def self.uk_deaths
      $logger.info 'Writing deaths CSV for UK.'
      uk = UkCovid19Data.uk
      england = UkCovid19Data.england
      scotland = UkCovid19Data.scotland
      wales = UkCovid19Data.wales
      northern_ireland = UkCovid19Data.northern_ireland
      start_date = [england.keys.min, scotland.keys.min, wales.keys.min, northern_ireland.keys.min].min
      finish_date = [england.keys.max, scotland.keys.max, wales.keys.max, northern_ireland.keys.max].max

      data = CSV::Table.new([], headers: ['Date', 'England', 'Scotland', 'Wales', 'Northern', 'Grand Total'])  
      (start_date..finish_date).each do |date|
        data.push [
          date,
          england.dig(date, :deaths),
          scotland.dig(date, :deaths),
          wales.dig(date, :deaths),
          northern_ireland.dig(date, :deaths),
          uk.dig(date, :deaths),
        ]
      end

      File.write(File.join(PUBLIC_DIR, "uk_deaths_per_#{NUMBERS_PER}.csv"), data.to_csv)
    end

    def self.uk_deaths_OLD
      $logger.info 'Writing deaths CSV for UK.'
      health_boards = ScotlandCovid19Data.health_boards
      deaths = ScotlandCovid19Data.deaths

      data = CSV::Table.new([], headers: ['Date', *health_boards, 'Grand Total'])  
      deaths.keys.sort.each do |date|
        data.push [date, *deaths.fetch(date).values_at(*health_boards, 'Grand Total')]
      end
      File.write(File.join(PUBLIC_DIR, "uk_deaths_per_#{NUMBERS_PER}.csv"), data.to_csv)
    end
  end
end
