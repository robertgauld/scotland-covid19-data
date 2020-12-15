# frozen_string_literal: true

module Make
  class Html
    @@templates = Hash.new do |hash, key|
      $logger.debug "Loading template file \"#{key}.haml\""
      hash[key] = File.read(File.join(ROOT_DIR, 'template', "#{key}.haml"))
    end

    def self.index(hide_zip_download_link: false, target: :file, filename: 'index.html')
      $logger.info "Generating index file"

      data = {
        numbers_per: NUMBERS_PER,
        upto_scotland: ScotlandCovid19Data.cases.keys.last,
        upto_uk: UkCovid19Data.uk.keys.last,
        health_boards: ScotlandCovid19Data.health_boards,
        hide_zip_download_link: hide_zip_download_link
      }

      html = Haml::Engine.new(template('index.html'))
                         .render(self, data)

      case target
      when :file
        fail ArgumentError, 'filename must be passed when target is :file' unless filename
        File.write File.join(PUBLIC_DIR, filename), html
      when :screen
        puts html
      when :return
        html
      else
        fail "#{target.inspect} is not a valid target."
      end
    end

    def self.template(key)
      return @@templates['index.html'] unless ENV['RACK_ENV'] == 'development'
      File.read(File.join(ROOT_DIR, 'template', "#{key}.haml"))
    end
    private_class_method :template
  end
end
