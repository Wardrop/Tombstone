module Tombstone
  module Notifiers
    class ChangedStatus < Base
      
      def template
        'changed_status'
      end
      
      def to
        Tombstone.config[:email][:coordinator_email]
      end
      
      def subject
        "Status of #{@changed_allocation.type.titleize} ##{@changed_allocation.id} has changed from #{@changed_allocation.status.titleize} to #{@existing_allocation.status.titleize}"
      end
      
    end
  end
end