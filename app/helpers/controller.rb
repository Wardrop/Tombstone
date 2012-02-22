module Tombstone
  App.helpers do
    
    def saveAllocation(allocation, data)
      errors = allocation.errors
      allocation.db.transaction do
        roles = {}
        allocation.class.valid_roles.each do |role_name|
          role_data = data[role_name]
          if role_data.nil? || !role_data.is_a?(Hash)
            errors.add(role_name.to_sym, "must be added")
          else
            role_errors = Sequel::Model::Errors.new
            begin
              allocation.add_role(Role.create_from(role_data, role_errors))
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
        
        if allocation.valid?
          reservation.save
        else
          errors.merge!(reservation.errors)
          raise Sequel::Rollback
        end

        roles.each { |type, role| role.add_allocation(reservation) }
      end
    end
    
  end
end