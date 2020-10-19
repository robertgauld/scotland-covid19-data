# frozen_string_literal: true

class UkCovid19Data
  ENGLAND_FILE = 'covid-19-totals-england.csv'
  NORTHERN_IRELAND_FILE = 'covid-19-totals-northern-ireland.csv'
  SCOTLAND_FILE = 'covid-19-totals-scotland.csv'
  WALES_FILE = 'covid-19-totals-wales.csv'
  UK_FILE = 'covid-19-totals-uk.csv'
  FILES = [
    ENGLAND_FILE,
    NORTHERN_IRELAND_FILE,
    SCOTLAND_FILE,
    WALES_FILE,
    UK_FILE,
  ].freeze

  ENGLAND_SCALE = 54_000_000.to_f / NUMBERS_PER
  NORTHERN_IRELAND_SCALE = 2_000_000.to_f / NUMBERS_PER
  SCOTLAND_SCALE = 5_500_000.to_f / NUMBERS_PER
  WALES_SCALE = 3_100_000.to_f / NUMBERS_PER
  UK_SCALE = 64_600_000.to_f / NUMBERS_PER

  @@current_git_sha = ''

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

  def self.download(force: false, only: nil)
    $logger.info (force ? 'Downloading all' : 'Downloading new') + \
                 (only ? " #{only.inspect} data." : ' data.')
    force ||= update_available?
    files = only ? [*only] : FILES

    files.each do |file|
      url = "https://raw.githubusercontent.com/geeogi/covid-19-uk-data/master/data/#{file}"
      file = File.join(DATA_DIR, file)

      if !File.exist?(file) || force
        $logger.debug "#{url} => #{file}"
        src = URI(url).open
        File.open(file, 'w') do |dst|
          IO.copy_stream src, dst
        end
      end
    end

    @@current_git_sha = github_latest_commit_sha unless only
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

  def self.update_available?
    $logger.info 'Checking github for updated data'
    github_data_sha = github_latest_commit_sha
    $logger.debug "Current data: #{@@current_git_sha}, " \
                  "Github data: #{github_data_sha}, " \
                  "Data is #{(github_data_sha == @@current_git_sha) ? 'current' : 'stale'}."

    @@current_git_sha != github_data_sha
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
          tests: record['Tests'] ? record['Tests'] / scale : nil,
          confirmed_cases: record['ConfirmedCases'] ? record['ConfirmedCases'] / scale : nil,
          deaths: record['Deaths'] ? record['Deaths'] / scale : nil
        }
      end
      $logger.debug "Read UK data for #{data.keys.sort.values_at(0, -1).map(&:to_s).join(' to ')}."    
      data
    end

    def github_latest_commit_sha
      JSON.parse(URI('https://api.github.com/repos/geeogi/covid-19-uk-data/commits/master').read)['sha']
    end
  end
end
