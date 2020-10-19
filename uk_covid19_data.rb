# frozen_string_literal: true

class UkCovid19Data
  VERSION_FILE = 'UkCovid19Data.version'
  CASES_FILE = 'covid-19-cases.csv'
  DEATHS_FILE = 'covid-19-deaths.csv'

  ENGLAND_FILE = 'covid-19-totals-england.csv'
  NORTHERN_IRELAND_FILE = 'covid-19-totals-northern-ireland.csv'
  SCOTLAND_FILE = 'covid-19-totals-scotland.csv'
  WALES_FILE = 'covid-19-totals-wales.csv'
  UK_FILE = 'covid-19-totals-uk.csv'

  ENGLAND_SCALE = 54_000_000.to_f / NUMBERS_PER
  NORTHERN_IRELAND_SCALE = 2_000_000.to_f / NUMBERS_PER
  SCOTLAND_SCALE = 5_500_000.to_f / NUMBERS_PER
  WALES_SCALE = 3_100_000.to_f / NUMBERS_PER
  UK_SCALE = 64_600_000.to_f / NUMBERS_PER

  def self.uk
    load_uk unless defined?(@@uk)
    @@uk
  end

  def self.england
    load_england unless defined?(@@england)
    @@england
  end

  def self.scotland
    load_scotland unless defined?(@@scotland)
    @@scotland
  end

  def self.wales
    load_wales unless defined?(@@wales)
    @@wales
  end

  def self.northern_ireland
    load_northern_ireland unless defined?(@@northern_ireland)
    @@northern_ireland
  end

  def self.cases
    load_cases unless defined?(@@cases)
    @@cases
  end

  def self.deaths
    load_deaths unless defined?(@@deaths)
    @@deaths
  end

  def self.download
    $logger.info 'Downloading & Generating UK data.'

    $logger.debug 'Downloading UK cases'
    src = URI('https://api.coronavirus.data.gov.uk/v1/data?filters=areaType=nation&structure=%7B%22areaName%22:%22areaName%22,%22date%22:%22date%22,%22newCasesByPublishDate%22:%22newCasesByPublishDate%22,%22cumCasesByPublishDate%22:%22cumCasesByPublishDate%22%7D&format=csv').open
    File.open(File.join(DATA_DIR, CASES_FILE), 'w') do |dst|
      IO.copy_stream src, dst
    end

    $logger.debug 'Downloading UK deaths'
    src = URI('https://api.coronavirus.data.gov.uk/v1/data?filters=areaType=nation&structure=%7B%22areaName%22:%22areaName%22,%22date%22:%22date%22,%22newDeaths28DaysByDeathDate%22:%22newDeaths28DaysByDeathDate%22,%22cumDeaths28DaysByDeathDate%22:%22cumDeaths28DaysByDeathDate%22%7D&format=csv').open
    File.open(File.join(DATA_DIR, DEATHS_FILE), 'w') do |dst|
      IO.copy_stream src, dst
    end

    $logger.debug 'Generating UK and nation data'
    data = Hash.new { |h, k| h[k] = Hash.new { |j, l| j[l] = [nil, 0, nil, 0] } }
    # nation => data => [new_cases, cum_cases, new_deaths, cum_deaths]

    File.readlines(File.join(DATA_DIR, CASES_FILE)).each do |line|
      next if line.start_with? 'area'

      line = line.strip.split(',') # nation, date, new, cum
      data['UK'][line[1]][0] ||= 0
      data['UK'][line[1]][0] += line[2].to_i
      data['UK'][line[1]][1] += line[3].to_i
      data[line[0]][line[1]][0] = line[2]&.to_i
      data[line[0]][line[1]][1] = line[3]&.to_i
    end

    File.readlines(File.join(DATA_DIR, DEATHS_FILE)).each do |line|
      next if line.strip.start_with? 'area'

      line = line.split(',') # nation, date, new, cum
      data['UK'][line[1]][2] ||= 0
      data['UK'][line[1]][2] += line[2].to_i
      data['UK'][line[1]][3] += line[3].to_i
      data[line[0]][line[1]][2] = line[2]&.to_i
      data[line[0]][line[1]][3] = line[3]&.to_i
    end

    $logger.debug 'Saving UK and nation data'
    File.write(
      File.join(DATA_DIR, UK_FILE),
      "Date,Cases,Cumulative Cases,Deaths,Cumulative Deaths\n" + data['UK'].map { |k, v| [k, *v] }.sort_by(&:first).map { |a| a.join(',') }.join("\n") + "\n"
    )
    File.write(
      File.join(DATA_DIR, ENGLAND_FILE),
      "Date,Cases,Cumulative Cases,Deaths,Cumulative Deaths\n" + data['England'].map { |k, v| [k, *v] }.sort_by(&:first).map { |a| a.join(',') }.join("\n") + "\n"
    )
    File.write(
      File.join(DATA_DIR, SCOTLAND_FILE),
      "Date,Cases,Cumulative Cases,Deaths,Cumulative Deaths\n" + data['Scotland'].map { |k, v| [k, *v] }.sort_by(&:first).map { |a| a.join(',') }.join("\n") + "\n"
    )
    File.write(
      File.join(DATA_DIR, WALES_FILE),
      "Date,Cases,Cumulative Cases,Deaths,Cumulative Deaths\n" + data['Wales'].map { |k, v| [k, *v] }.sort_by(&:first).map { |a| a.join(',') }.join("\n") + "\n"
    )
    File.write(
      File.join(DATA_DIR, NORTHERN_IRELAND_FILE),
      "Date,Cases,Cumulative Cases,Deaths,Cumulative Deaths\n" + data['Northern Ireland'].map { |k, v| [k, *v] }.sort_by(&:first).map { |a| a.join(',') }.join("\n") + "\n"
    )
  end

  def self.update_available?
    true
  end

  def self.load
    load_uk
    load_england
    load_scotland
    load_wales
    load_northern_ireland
  end

  def self.update
    download
    load
  end

  class << self
    private

    def load_uk
      @@uk = load_(UK_FILE, UK_SCALE)
    end

    def load_england
      @@england = load_(ENGLAND_FILE, ENGLAND_SCALE)
    end

    def load_scotland
      @@scotland = load_(SCOTLAND_FILE, SCOTLAND_SCALE)
    end

    def load_wales
      @@wales = load_(WALES_FILE, WALES_SCALE)
    end

    def load_northern_ireland
      @@northern_ireland = load_(NORTHERN_IRELAND_FILE, NORTHERN_IRELAND_SCALE)
    end

    def load_(file, scale)
      $logger.info "Reading UK data (#{file})."
      unless File.exist?(File.join(DATA_DIR, file))
        download(only: file)
      end

      date_converter = ->(value, field) { field.header.eql?('Date') ? Date.parse(value) : value }
      data = {}
      CSV.read(File.join(DATA_DIR, file), headers: true, converters: [:numeric, date_converter]).each do |record|
        data[record['Date']] = {
          date: record['Date'],
          daily_cases: record['Cases'] ? record['Cases'] / scale : nil,
          daily_deaths: record['Deaths'] ? record['Deaths'] / scale : nil,
          cumulative_cases: record['Cumulative Cases'] ? record['Cumulative Cases'] / scale : nil,
          cumulative_deaths: record['Cumulative Deaths'] ? record['Cumulative Deaths'] / scale : nil
        }
      end
      $logger.debug "Read UK data for #{data.keys.sort.values_at(0, -1).map(&:to_s).join(' to ')}."    
      data
    end
  end
end
