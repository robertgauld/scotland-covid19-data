# frozen_string_literal: true

module Make
  class Html
    TEMPLATE_DIR = File.join(ROOT_DIR, 'template')

    def self.index(save: false)
      $logger.info "#{save ? 'Updating' : 'Generating'} index file"

      data = {
        numbers_per: NUMBERS_PER,
        upto: ScotlandCovid19Data.cases.keys.last,
        updating: $update_job&.running?,
        health_boards: ScotlandCovid19Data.health_boards
      }

      html = Haml::Engine.new(File.read(File.join(TEMPLATE_DIR, 'index.haml')))
                         .render(self, data)

      File.write(File.join(PUBLIC_DIR, 'index.html'), html) if save
      html
    end
  end
end
