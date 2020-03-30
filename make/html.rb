# frozen_string_literal: true

module Make
  class Html
    @@templates = Hash.new do |hash, key|
      $logger.debug "Loading template file \"#{key}.haml\""
      hash[key] = File.read(File.join(ROOT_DIR, 'template', "#{key}.haml"))
    end
  
    def self.index(save: false)
      $logger.info "#{save ? 'Updating' : 'Generating'} index file"

      data = {
        numbers_per: NUMBERS_PER,
        upto_scotland: ScotlandCovid19Data.cases.keys.last,
        upto_uk: UkCovid19Data.uk.keys.last,
        updating: $update_job&.running?,
        health_boards: ScotlandCovid19Data.health_boards
      }

      html = Haml::Engine.new(template('index.html'))
                         .render(self, data)

      File.write(File.join(PUBLIC_DIR, 'index.html'), html) if save
      html
    end

    def self.template(key)
      return @@templates['index.html'] unless ENV['RACK_ENV'] == 'development'
      File.read(File.join(ROOT_DIR, 'template', "#{key}.haml"))
    end
    private_class_method :template
  end
end
