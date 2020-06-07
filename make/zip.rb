# frozen_string_literal: true

module Make
  class Zip
    def self.all
      $logger.info 'Generating zip.'

      zip_file_name = File.join(PUBLIC_DIR, 'scotland-covid19-data.zip')
      File.unlink(zip_file_name) if File.exist?(zip_file_name)

      ::Zip::File.open(zip_file_name, ::Zip::File::CREATE) do |zipfile|
        Dir.glob(['public/*.*', 'data/*.*']).each do |file|
          next if file == 'data/Global_Mobility_Report.csv'
          zipfile.add(file, File.join(ROOT_DIR, file))
        end

        zipfile.get_output_stream('public/index.html') do |file|
          file.write Make::Html.index(updating: false, hide_zip_download_link: true)
        end

        zipfile.get_output_stream('readme.txt') do |file|
          file.write <<~__README__
            The public folder contains the website, to view it open the index.html file.
            The data folder contains the data as doenloaded from the various data sources used.

            Again my thanks to:
              * @watty62 for collecting and preprocessing the Scotland data at https://github.com/watty62/Scot_covid19
              * @tom_e_white for collecting and preprocessing the UK data at https://github.com/tomwhite/covid-19-uk-data

            Also includes data from:
              * The Scottish Government - https://github.com/DataScienceScotland/COVID-19-Management-Information
              * Google (not included in this download) - https://www.google.com/covid19/mobility/
          __README__
        end
      end
    end
  end
end
