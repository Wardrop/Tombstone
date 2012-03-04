module Tombstone
  App.helpers do
    
    # Takes an optional block which is yielded directly before the allocation is validated and saved.
    # Block is given the allocation object and data hash as arguments.
    def save_allocation(allocation, data)
      errors = allocation.errors
      allocation.db.transaction do
        allocation.save(validate: false)
        allocation.class.valid_roles.each do |role_name|
          role_data = data[role_name]
          unless role_data.nil? || !role_data.is_a?(Hash)
            role_errors = Sequel::Model::Errors.new
            begin
              allocation.add_role(Role.create_from(role_data, role_errors))
            rescue Sequel::Rollback => e
              errors.add(role_name.to_sym, role_errors)
            end
          end
        end
        
        # allocation.class.valid_roles.each do |role_name|
        #   role_data = data[role_name]
        #   if role_data.nil? || !role_data.is_a?(Hash)
        #     errors.add(role_name.to_sym, "must be added")
        #   else
        #     role_errors = Sequel::Model::Errors.new
        #     begin
        #       roles << Role.create_from(role_data, role_errors)
        #     rescue Sequel::Rollback => e
        #       errors.add(role_name.to_sym, role_errors)
        #       raise
        #     end
        #   end
        # end
        
        yield(allocation, data) if block_given?

        if errors.empty? && allocation.valid?
          allocation.save
        else
          errors.merge!(allocation.errors)
          raise Sequel::Rollback
        end
      end
    end
    
    # Takes a string in a format similar to "field1:some value field2:another value", and returns a hash of field => value pairs.
    def parse_search_string(str, valid_keys)
      Hash[*str.split(/(^| +)(#{valid_keys.join('|')}):/).reject {|v| v.strip.empty? }.map{|v| v.strip}]
    end
    
  end
end