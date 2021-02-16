# frozen_string_literal: true

class GoogleMobilityData
  DATA_FILE = 'Global_Mobility_Report.csv'
  VERSION_FILE = 'Global_Mobility_Report.version'

  REGIONS = {
    'Scotland' => %w{
      Aberdeen\ City
      Aberdeenshire
      Angus\ Council
      Argyll\ and\ Bute\ Council
      Clackmannanshire
      Dumfries\ and\ Galloway
      Dundee\ City\ Council
      East\ Ayrshire\ Council
      East\ Dunbartonshire\ Council
      East\ Lothian\ Council
      East\ Renfrewshire\ Council
      Edinburgh
      Falkirk
      Fife
      Glasgow\ City
      Highland\ Council
      Inverclyde
      Midlothian
      Moray
      Na\ h-Eileanan\ an\ Iar
      North\ Ayrshire\ Council
      North\ Lanarkshire
      Orkney
      Perth\ and\ Kinross
      Renfrewshire
      Scottish\ Borders
      Shetland\ Islands
      South\ Ayrshire\ Council
      South\ Lanarkshire
      Stirling
      West\ Dunbartonshire\ Council
      West\ Lothian
    }
  }.freeze

  def self.data
    load unless defined?(@@data)
    @@data
  end

  def self.accessed_at
    defined?(@@accessed_at) ? @@accessed_at : nil
  end

  def self.download(force: false)
    $logger.info (force ? 'Downloading all' : 'Downloading new') + ' data.'
    force ||= update_available?

    src = URI('https://www.gstatic.com/covid19/mobility/Global_Mobility_Report.csv').open
    File.open(File.join(DATA_DIR, DATA_FILE), 'w') do |dst|
      IO.copy_stream src, dst
    end

    @@accessed_at = Time.now
    File.write(
      File.join(DATA_DIR, VERSION_FILE),
      URI.open('https://www.google.com/covid19/mobility/')
         .read
         .match(/Reports created (\d{4}-\d{2}-\d{2})/)[1]
    )
  end

  def self.update
    download
    load
  end

  def self.update_available?
    $logger.info 'Checking for updated data'

    version = URI.open('https://www.google.com/covid19/mobility/')
                 .read
                 .match(/Reports created (\d{4}-\d{2}-\d{2})/)[1]

    $logger.debug "Current data: #{current_version}, " \
                  "Google data: #{version}, " \
                  "Data is #{(version == current_version) ? 'current' : 'stale'}."

    current_version != version
  end

  def self.current_version
    return nil unless File.exist?(File.join(DATA_DIR, VERSION_FILE))

    File.read(File.join(DATA_DIR, VERSION_FILE))
  end

  class << self
    private

    def load
      $logger.info 'Reading Google mobility data.'
      unless File.exist?(File.join(DATA_DIR, DATA_FILE))
        download
      end

      # @@data Hash: region/"UK" -> date -> Array of array of values
      @@data = Hash.new { |h1, k1| h1[k1] = Hash.new { |h2, k2| h2[k2] = Array.new } }
      # 0:country_code 1:country 2:region 3:sub_region, 4:metro_area, 5:iso_3166_2_code, 6:census_fips_code 7:place_id 8:date
      # 9:retail_and_recreation 10:grocery_and_pharmacy 11:parks 12:transit_stations 13:workplaces 14:residential
      File.foreach(File.join(DATA_DIR, DATA_FILE)) do |line|
        next unless line.start_with?('GB,')
        line = CSV.parse_line(line)
        next unless line[2].nil? || REGIONS['Scotland'].include?(line[2])

        data = line[9..14].map { |v| v&.to_i }
        date = Date.parse(line[8])
        key = line[2].nil? ? 'UK' : 'Scotland'
        @@data[key][date].push data
        @@data[line[2]][date].push data
      end

      # @@data Hash: region/"UK" -> Array [date, values]
      # convert {date -> [[values_1], [values_2] ... [values_n]]} to [date, *sum_of_values]
      @@data.transform_values! do |hash|
        hash.map do |date, values|
          [
            date,
            *values.reduce(Array.new(6, 0)) { |sums, items| (0..5).each { |i| sums[i] += items[i] if items[i] }; sums }.map { |v| v / values.count }
          ]
        end
      end

      $logger.debug 'Read Google mobility data.'
    end
  end
end
