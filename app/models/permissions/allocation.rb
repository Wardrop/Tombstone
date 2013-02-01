module Tombstone
  module ModelPermissions
    
    module Allocation
      # Returns an array of states permitted for the current allocation.
      def permitted_states
        if ['completed', 'deleted'].include? status
          []
        else
          can_delete = case self.status
          when 'legacy'
            permissions.can_delete_legacy?
          when 'provisional'
            permissions.can_delete_provisional?
          when 'pending'
            permissions.can_delete_pending?
          when 'approved'
            permissions.can_delete_approved?
          when 'interred'
            permissions.can_delete_interred?
          when 'completed'
            permissions.can_delete_completed?
          else
            true
          end
          
          unpermitted = []
          unpermitted << 'approved' unless permissions.can_approve?
          unpermitted << 'interred' unless permissions.can_inter?
          unpermitted << 'completed' unless permissions.can_complete?
          unpermitted << 'deleted' unless can_delete
          permitted = self.class.valid_states.reject { |v| unpermitted.include? v }
          permitted.select! { |v| status_allowed(v) }
        end
      end
      
      def before_save
        super
        
        if self.column_changed?(:status)
          case self.status
          when 'approved'
            permissions.can_approve!
          when 'interred'
            permissions.can_inter!
          when 'completed'
            permissions.can_complete!
          when 'deleted'
            permissions.can_delete!
          end
        end
        
        case self.initial_value(:status)
        when 'legacy'
          permissions.can_edit_legacy!
        when 'provisional'
          permissions.can_edit_provisional!
        when 'pending'
          permissions.can_edit_pending!
        when 'approved'
          permissions.can_edit_approved!
        when 'interred'
          permissions.can_edit_interred!
        when 'completed'
          permissions.can_edit_completed!
        when 'deleted'
          permissions.can_edit_deleted!
        end
      end
      
      def before_destroy
        super
        case self.status
        when 'legacy'
          permissions.can_delete_legacy!
        when 'provisional'
          permissions.can_delete_provisional!
        when 'pending'
          permissions.can_delete_pending!
        when 'approved'
          permissions.can_delete_approved!
        when 'interred'
          permissions.can_delete_interred!
        when 'completed'
          permissions.can_delete_completed!
        end
      end
    end
    
  end
end
