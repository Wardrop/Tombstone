module Tombstone
  module ModelPermissions
    
    module BaseModel
      def self.included(klass)
        delegate :permissions, :to => klass
        klass.extend(Module.new {
          attr_accessor :permissions
        })
      end
      
      def before_save
        super
        self.new? ? permissions.can_create! : permissions.can_edit!
      end
      
      def before_destroy
        super
        permissions.can_delete!
      end
    end
    
  end
end