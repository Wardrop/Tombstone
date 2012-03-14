module Tombstone
  class Notification

    @config = {}

    class << self
      attr_accessor :config
      attr_accessor :general
    end

    attr_accessor :interment, :deceased, :place

    def initialize(interment = nil)
      @interment = interment
      @deceased = interment.roles_by_type('deceased')[0].person
      @place = interment.place
    end

    def subject
      eval('"'+self.class.config[:email][:subject]+'"')
    end

    def sendMessage

      mail = Mail.new
      mail.to = self.class.config[:email][:to]
      mail.from = self.class.config[:email][:from]
      mail.subject = self.subject

      plain_text = ERB.new(self.plain_text_body).result(binding)
      puts plain_text
      mail.text_part do
        body plain_text
      end

      ## mail.html_part do
      ##   content_type 'text/html; charset=UTF-8'
      ##   body '<h1>This is HTML</h1>'
      ## end

      mail.delivery_method :sendmail
      mail.deliver

    end

    def plain_text_body
      %{A request for a new burial has been 'Approved'.

          Deceased: <%= deceased.title %> <%= deceased.given_name %> <%= deceased.surname %>
          Cemetery: <%= place.description %>
          Type: <%= interment.interment_type.capitalize %>
          At: <%= interment.interment_date.strftime('%A %d %B %Y') %>

          For more details http://<%= self.class.general[:hostname] %>:<%= self.class.general[:port] %>/interment/<%= interment.id.to_s %>
      }
    end

  end
end
