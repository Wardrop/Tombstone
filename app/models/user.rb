module Tombstone
  class User < BaseModel
    plugin ModelPermissions
    set_primary_key :id
    unrestrict_primary_key
    
    attr_accessor :ldap
    
    def role_permissions
      @role_permissions ||= Permissions.new(@values[:role])
    end
    
    def authenticate(password)
      @ldap = LDAP.new(id, password)
      @ldap.authenticate
    end
    
    def ldap
      raise StandardError, "Must authenticate user before fetching LDAP object." unless @ldap && @ldap.authenticated?
      @ldap
    end
    
    def after_save
      super
      @role_permissions.role = @values[:role] unless @values[:role].to_sym == role_permissions.role
    end
  end
end
