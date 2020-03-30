# frozen_string_literal: true

module Make
  class Csv
    def self.scotland
      $logger.info 'Writing CSVs for Scotland.'
      health_boards = ScotlandCovid19Data.health_boards
      cases = ScotlandCovid19Data.cases
      deaths = ScotlandCovid19Data.deaths
      intensive_care = ScotlandCovid19Data.intensive_care
      deceased = ScotlandCovid19Data.deceased
      tests = ScotlandCovid19Data.tests
      uk = UkCovid19Data.uk

      data = CSV::Table.new([], headers: ['Date', *health_boards, 'Grand Total'])  
      cases.keys.sort.each do |date|
        data.push [date, *cases.fetch(date).values_at(*health_boards, 'Grand Total')]
      end
      File.write(File.join(PUBLIC_DIR, "cases_per_#{NUMBERS_PER}.csv"), data.to_csv)

      data = CSV::Table.new([], headers: ['Date', *health_boards, 'Grand Total'])  
      deaths.keys.sort.each do |date|
        data.push [date, *cases.fetch(date).values_at(*health_boards, 'Grand Total')]
      end
      File.write(File.join(PUBLIC_DIR, "deaths_per_#{NUMBERS_PER}.csv"), data.to_csv)

      earliest_date = [deceased.keys.min, intensive_care.keys.min].min
      latest_date = [deceased.keys.max, intensive_care.keys.max].max
      data = CSV::Table.new([], headers: ['Date', 'Patients in intensive care', 'Cumulative deceased'])  
      (earliest_date..latest_date).each do |date|
        data.push [date, intensive_care[date], deceased[date]]
      end
      File.write(File.join(PUBLIC_DIR, 'icu_deceased.csv'), data.to_csv)

      data = CSV::Table.new([], headers: ['Date', 'Positive', 'Negative', 'Cumulative Positive', 'Cumulative Negative'])  
      tests.values.sort_by { |record| record['Date'] }.each do |record|
        data.push record.values_at('Date', 'Today Positive', 'Today Negative', 'Total Positive', 'Total Negative')
      end
      File.write(File.join(PUBLIC_DIR, 'tests.csv'), data.to_csv)

      data = CSV::Table.new([], headers: ['Date', 'Cases', 'Deaths', 'Cases Ratio', 'Deaths Ratio'])
      cases.keys.sort.each do |date|
        data.push [
          date,
          cases.dig(date, 'Grand Total'),
          deaths.dig(date, 'Grand Total'),
          cases.dig(date, 'Grand Total') && uk.dig(date, :confirmed_cases) ? cases.dig(date, 'Grand Total') / uk.dig(date, :confirmed_cases) : nil,
          deaths.dig(date, 'Grand Total') && uk.dig(date, :deaths) ? deaths.dig(date, 'Grand Total') / uk.dig(date, :deaths) : nil
        ]
      end
      File.write(File.join(PUBLIC_DIR, "scotland_per_#{NUMBERS_PER}.csv"), data.to_csv)
    end

    def self.health_board(name)
      fail "#{name.inspect} is not a known health board" unless ScotlandCovid19Data.health_boards.include?(name)
      $logger.info "Writing CSV for #{name}."
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
  end
end
