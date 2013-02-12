module Tombstone
  module ModelPermissions
    
    module Place

      def before_save
        super
        permissions.can_manage_cemeteries!
      end
      
      def before_destroy
        super
        permissions.can_manage_cemeteries!
      end
    end
    
  end
end
