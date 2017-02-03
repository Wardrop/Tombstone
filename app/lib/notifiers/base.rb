
module Tombstone
  module Notifiers
    class Base

      def initialize(allocation)
        @allocation = allocation
      end

      def template
        'default'
      end

      def subject
        'Default Notification'
      end

      def to

      end

      def email_addresses_for_role(*roles)
        ldap = LDAP.new(Tombstone::CONFIG[:ldap][:username], Tombstone::CONFIG[:ldap][:password])
        roles.map { |role|
          ldap.user_details_for(Tombstone::User.filter(role: role.to_s).naked.all.map! { |v| v[:id] }).map! do |v|
            v[:mail][0]
          end
        }.flatten.compact
      end

      def send
        [*to].each do |recipient|
          Mail.deliver({
            from: Tombstone::CONFIG[:email][:from],
            to: recipient,
            subject: "Tombstone: #{subject}",
            body: render
          })
        end
      end

      def allocation_url
        URI.join(Tombstone::CONFIG[:base_url], "/#{@allocation.type}/#{@allocation.id}")
      end

    protected

      def print(fallback = 'none', &block)
        value = block.call rescue nil
        if value.blank?
          fallback
        else
          case value
            when Time, DateTime, Date
              ((value.hour + value.min + value.sec) > 0) ? value.strftime('%d/%m/%Y %l:%M%P') : value.strftime('%d/%m/%Y')
            else
              value
          end
        end
      end

      def render
        ERB.new(File.read("views/email/#{template}.erb")).result(binding)
      end

    end
  end
end
