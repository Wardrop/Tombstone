module Tombstone
  module ModelPermissions
    
    module Allocation
      def permitted_states
        can_delete = case self.status
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
        self.class.valid_states.reject { |v| unpermitted.include? v }
      end
      
      def before_save
        super
        if self.changed_columns.include? :status
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
        
        case self.status
        when 'approved'
          permissions.can_edit_approved!
        when 'interred'
          permissions.can_edit_interred!
        when 'completed'
          permissions.can_edit_completed!
        end
      end
      
      def before_destroy
        super
        case self.status
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
