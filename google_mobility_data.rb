# frozen_string_literal: true

class GoogleMobilityData
  FILE = 'Global_Mobility_Report.csv'
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

  @@current_cachebust = ''

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

    index = Nokogiri::HTML.parse(
      URI.open('https://www.google.com/covid19/mobility/'),
      nil,
      nil,
      Nokogiri::XML::ParseOptions.new.nonet.noent.noblanks.noerror.nowarning
    )

    href = index.at_xpath("//a[@aria-label = 'Download global CSV']")['href']
    src = URI(href).open
    File.open(File.join(DATA_DIR, FILE), 'w') do |dst|
      IO.copy_stream src, dst
    end

    @@accessed_at = Time.now
    @@current_cachebust = href.match(/\?cachebust=([0-9a-zA-Z]+)\Z/)[1]
  end

  def self.update
    download
    load
  end

  def self.update_available?
    $logger.info 'Checking for updated data'

    index = Nokogiri::HTML.parse(
      URI.open('https://www.google.com/covid19/mobility/'),
      nil,
      nil,
      Nokogiri::XML::ParseOptions.new.nonet.noent.noblanks.noerror.nowarning
    )

    href = index.at_xpath("//a[@aria-label = 'Download global CSV']")['href']
    cachebust = href.match(/\?cachebust=([0-9a-zA-Z]+)\Z/)[1]

    $logger.debug "Current data: #{@@current_cachebust}, " \
                  "Google data: #{cachebust}, " \
                  "Data is #{(cachebust == @@current_cachebust) ? 'current' : 'stale'}."

    @@current_cachebust != cachebust
  end

  class << self
    private

    def load
      $logger.info 'Reading Google mobility data.'
      unless File.exist?(File.join(DATA_DIR, FILE))
        download
      end

      # @@data Hash: region/"UK" -> date -> Array of array of values
      @@data = Hash.new { |h1, k1| h1[k1] = Hash.new { |h2, k2| h2[k2] = Array.new } }
      # 0:country_code 1:country 2:region 3:sub_region, 4:metro_area, 5:iso_3166_2_code, 6:census_fips_code 7:date
      # 8:retail_and_recreation 9:grocery_and_pharmacy 10:parks 11:transit_stations 12:workplaces 13:residential
      File.foreach(File.join(DATA_DIR, FILE)) do |line|
        next unless line.start_with?('GB,')
        line = CSV.parse_line(line)
        next unless line[2].nil? || REGIONS['Scotland'].include?(line[2])

        data = line[8..13].map { |v| v&.to_i }
        date = Date.parse(line[7])
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
