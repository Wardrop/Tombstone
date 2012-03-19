module Tombstone
  class Notification

    @config = {}

    class << self
      attr_accessor :config
      attr_accessor :general
    end

    attr_accessor :interment
    attr_accessor :notify

    def initialize(interment = nil, trigger_now = false)
      self.interment = interment
      self.notify = []
      interment.add_observer(self)
      if (trigger_now)
        self.update(nil, interment.status)
        send_notifications
      end
    end

    def subject
      ERB.new(self.class.config[:email][:subject]).result(binding)
    end

    def update(old_status, new_status)
      self.class.config[:status_rules].each do |k, v|
        queueNotification(v[:notify]) if (v[:from_status] == old_status and v[:to_status] == new_status)
      end
    end

    def queueNotification(notify)
      @notify << notify
    end

    def send_notifications()

      return if self.notify.nil?

      deceased = self.interment.role_by_type('deceased').person
      place = self.interment.place

      mail = Mail.new
      mail.to = self.notify
      mail.cc = self.class.config[:email][:cc]
      mail.from = self.class.config[:email][:from]
      mail.subject = self.subject

      plain_text = ERB.new(self.plain_text_body).result(binding)
      puts plain_text
      mail.text_part do
        body plain_text
      end

      mail.delivery_method :sendmail
      mail.deliver if (self.class.config[:enabled])
    end

    def interment_site_url
      "http://" << self.class.general[:hostname] << ((self.class.general[:port] == 80) ? "" :":" << self.class.general[:port].to_s) << "/interment/" << interment.id.to_s
    end

    def plain_text_body
      self.class.config[:email][:body]
    end

  end
end
