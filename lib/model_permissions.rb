require_relative './permissions.rb'

module Tombstone
  module ModelPermissions
    
    module DatasetMethods
      
      def permissions(perms = nil, is_clone = false)
        unless perms.nil? || perms.is_a?(Tombstone::Permissions)
          raise RuntimeError, "Dataset expects object of type Tombstone::Permissions, #{perms.class} given." 
        end
        
        if is_clone
          if perms.nil?
            @permissions ||= Permissions.new
          else
            @original_row_proc ||= self.row_proc
            self.row_proc = proc do |hash|
              model_obj = @original_row_proc.call(hash)
              model_obj.permissions(perms)
              model_obj
            end
            
            @permissions = perms
            self
          end
        else
          self.clone.permissions(perms, true)
        end
      end
      
    end
    
    module InstanceMethods
      
      def permissions(perms = nil)
        if perms.nil?
          @permissions ||= Permissions.new
        else
          raise RuntimeError, "Dataset expects object of type Tombstone::Permissions, #{perms.class} given." unless perms.is_a?(Tombstone::Permissions)
          @permissions = perms
          self
        end
      end
      
    end
  end
end
