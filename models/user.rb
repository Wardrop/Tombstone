require_relative './base'
require_relative '../lib/model_permissions'

module Tombstone
  class User < BaseModel
    plugin ModelPermissions
    set_primary_key :id
    
    def role_permissions
      @role_permissions ||= Permissions.new(@values[:role])
    end
    
    def after_save
      @role_permissions.role = @values[:role] unless @values[:role].to_sym == role_permissions.role
    end
  end
end