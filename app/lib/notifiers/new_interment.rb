module Tombstone
  module Notifiers
    class NewInterment < Base
      
      def template
        'new_interment'
      end
      
      def to
        email_addresses_for_role('coordinator')
      end
      
      def subject
        "New interment has been created (##{@allocation.id})"
      end
      
    end
  end
end