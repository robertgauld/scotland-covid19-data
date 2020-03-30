# frozen_string_literal: true

module Make
  class Csv
    def self.scotland
      $logger.info 'Writing CSVs for Scotland.'
      health_boards = ScotlandCovid19Data.health_boards
      cases = ScotlandCovid19Data.cases
      deaths = ScotlandCovid19Data.deaths

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
