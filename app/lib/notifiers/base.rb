
module Tombstone
  module Notifiers
    class Base
      
      def initialize(changed_allocation, existing_allocation)
        @changed_allocation = changed_allocation
        @existing_allocation = existing_allocation
      end
      
      def template
        'default'
      end
      
      def subject
        'Default Notification'
      end
      
      def to
        Tombstone.config[:email][:operator_email]
      end
      
      def send
        Mail.deliver({
          from: Tombstone.config[:email][:from],
          to: to,
          subject: subject,
          body: render
        })
      end
      
      def allocation_url
        URI.join(Tombstone.config[:base_url], "/#{@changed_allocation.type}/#{@changed_allocation.id}")
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
        ERB.new(File.read("app/views/email/#{template}.erb")).result(binding)
      end
      
    end
  end
end