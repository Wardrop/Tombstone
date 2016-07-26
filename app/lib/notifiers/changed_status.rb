module Tombstone
  module Notifiers
    class ChangedStatus < Base

      def template
        'changed_status'
      end

      def to
        email_addresses_for_role('coordinator', 'admin')
      end

      def subject
        "Status of #{@allocation.type.titleize} ##{@allocation.id} has changed from #{@allocation.previous_changes[:status].first.titleize} to #{@allocation.status.titleize}"
      end

    end
  end
end
