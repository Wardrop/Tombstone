module Tombstone
  class Notification

    @config = {}
    @pending_mail_notifications = []

    class << self
      attr_accessor :config
      attr_accessor :general
    end

    attr_accessor :interment
    attr_accessor :deceased
    attr_accessor :place
    attr_accessor :pending_mail_notifications

    def initialize(interment = nil, trigger_now = false)
      self.interment = interment
      self.deceased = interment.role_by_type('deceased').person
      self.place = interment.place
      interment.add_observer(self)
      if (trigger_now)
        self.update(nil, interment.status)
        sendMessages
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

      mail.delivery_method :sendmail
      self.pending_mail_notifications << mail
      puts "Pending " << self.pending_mail_notifications.to_s
    end

    def sendMessages
      if (self.class.config[:enabled] && !self.pending_mail_notifications.nil? )
        self.pending_mail_notifications.each do |mail|
          mail.deliver
        end
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
