module Tombstone
  module Notifiers
    class ChangedIntermentDate < Base

      def template
        'changed_interment_date'
      end

      def to
        email_addresses_for_role('coordinator', 'admin')
      end

      def subject
        "Interment Date for #{@allocation.type.titleize} ##{@allocation.id} has changed"
      end

    end
  end
end
