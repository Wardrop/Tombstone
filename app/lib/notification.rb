module Tombstone
  class Notification

    @config = {}

    class << self
      attr_accessor :config
      attr_accessor :general
    end

    attr_accessor :interment, :deceased, :place

    def initialize(interment = nil, trigger_now = false)
      @interment = interment
      @deceased = interment.roles_by_type('deceased')[0].person
      @place = interment.place
      interment.add_observer(self)
      update(nil, interment.status) if trigger_now
    end

    def subject
      ERB.new(self.class.config[:email][:subject]).result(binding)
    end

    def update(old_status, new_status)
      self.class.config[:status_rules].each do |k, v|
        sendMessage(v[:notify]) if (v[:from] == old_status and v[:to] == new_status)
      end

    end

    def sendMessage(notify)

      mail = Mail.new
      mail.to = notify
      mail.cc = self.class.config[:email][:to]
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

      if (self.class.config[:enabled])
        mail.delivery_method :sendmail
        mail.deliver
      end

    end

    def interment_site_url
      "http://" << self.class.general[:hostname] << ((self.class.general[:port] == 80) ? "" :":" << self.class.general[:port].to_s) << "/interment/" << interment.id.to_s
    end

    def plain_text_body
      self.class.config[:email][:body]
    end

  end
end
