module Tombstone
  module Notifiers
    class NewInterment < Base
      
      def template
        'new_interment'
      end
      
      def to
        Tombstone.config[:email][:coordinator_email]
      end
      
      def subject
        "New interment has been created (##{@changed_allocation.id})"
      end
      
    end
  end
end