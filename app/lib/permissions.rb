require 'set'

module Tombstone
  class Permissions
    @map = {}
    @options = Set.new([
      :can_create,
      :can_edit,
      :can_delete,
      :can_approve,
      :can_inter,
      :can_complete,
      :can_delete_legacy,
      :can_delete_provisional,
      :can_delete_pending,
      :can_delete_approved,
      :can_delete_interred,
      :can_delete_completed,
      :can_delete_deleted,
      :can_edit_legacy,
      :can_edit_provisional,
      :can_edit_pending,
      :can_edit_approved,
      :can_edit_interred,
      :can_edit_completed,
      :can_edit_deleted,
      :can_delete_files,
      :can_manage_cemeteries
    ]).freeze

    class << self
      attr_reader :options
      attr_accessor :map
    end

    attr_accessor :role

    def initialize(role = nil)
      @role = (role) ? role.to_sym : :default
      define_permission_methods
    end

    attr_reader :role
    def role=(role)
      @role = role.to_sym
      define_permission_methods
    end

    def to_hash
      @perms
    end

  private

    def define_permission_methods
      @perms = self.class.map[@role.to_sym] || {}
      self.class.options.each do |permission|
        define_singleton_method "#{permission}?".to_sym do
          return !!@perms[permission]
        end
        define_singleton_method "#{permission}!".to_sym do
          raise PermissionsError, "Role '#{@role}' does not have the permission '#{permission}'." unless @perms[permission]
        end
      end
    end

  end

  class PermissionsError < StandardError

  end
end
