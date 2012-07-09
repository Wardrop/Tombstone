module Tombstone
  module Notifiers
    class ChangedIntermentDate < Base
      
      def template
        'changed_interment_date'
      end
      
      def to
        email_addresses_for_role('coordinator')
      end
      
      def subject
        "Interment Date of #{@changed_allocation.type.titleize} ##{@changed_allocation.id} has changed"
      end
      
    end
  end
end