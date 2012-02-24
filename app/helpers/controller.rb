module Tombstone
  App.helpers do
    
    # Takes an optional block which is yielded directly before the allocation is validated and saved.
    # Block is given the allocation object and data hash as arguments.
    def save_allocation(allocation, data)
      errors = allocation.errors
      allocation.db.transaction do
        roles = []
        allocation.class.valid_roles.each do |role_name|
          role_data = data[role_name]
          if role_data.nil? || !role_data.is_a?(Hash)
            errors.add(role_name.to_sym, "must be added")
          else
            role_errors = Sequel::Model::Errors.new
            begin
              roles << Role.create_from(role_data, role_errors)
            rescue Sequel::Rollback => e
              errors.add(role_name.to_sym, role_errors)
              raise
            end
          end
        end

        if !data[:place].is_a?(Array) || data[:place].reject { |v| v.empty? }.empty?
          errors.add(:place, "must be selected")
          raise Sequel::Rollback
        end
        
        yield(allocation, data) if block_given?
        
        if errors.empty? && allocation.valid?
          allocation.save
          roles.each { |role| allocation.add_role(role) }
        else
          errors.merge!(allocation.errors)
          raise Sequel::Rollback
        end
      end
    end
    
  end
end