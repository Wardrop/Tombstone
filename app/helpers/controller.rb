module Tombstone
  App.helpers do
    
    # Takes an optional block which is yielded directly before the allocation is validated and saved.
    # Block is given the allocation object and data hash as arguments.
    def save_allocation(allocation, data)
      allocation.db.transaction do
        values = Hash[ params.map { |k,v|
          case k
          when 'place'
            v = (!params['place'].is_a?(Array) || params['place'].reject { |v| v.empty? }.empty?) ? nil : params['place'][-1]
            k = :place_id
          when 'funeral_director'
            k = :funeral_director_id
          end
          [k, v]
        } ]
        
        allocation.set_only_valid(values)
        allocation.save(validate: false)
        
        allocation.class.valid_roles.each do |role_name|
          role_data = data[role_name]
          unless role_data.nil? || !role_data.is_a?(Hash)
            role_errors = Sequel::Model::Errors.new
            begin
              allocation.add_role(Role.create_from(role_data, role_errors))
            rescue Sequel::Rollback => e
              allocation.errors.add(role_name.to_sym, role_errors)
            end
          end
        end
        
        if params['transactions'].is_a? Array
          params['transactions'].reject{ |v| v.blank? }.each do |trans|
            trans = Transaction.new(allocation_id: allocation.id, allocation_type: allocation.type, receipt_no: trans)
            if trans.valid?
              trans.save
            else
              raise Sequel::Rollback
            end
          end
        end
        
        if data['status'] == 'provisional'
          allocation.valid?
          allocation.errors.select!{ |k,v| k == :place && !v.empty? }
          if allocation.errors.empty?
            allocation.save(validate: false)
          else
            raise Sequel::Rollback
          end
        elsif allocation.errors.empty? && allocation.valid?
          allocation.save
        else
          raise Sequel::Rollback
        end
      end
    end
    
    # Takes a string in a format similar to "some term field1:some value field2:another value", and returns a hash
    # of field:value pairs. Any text before the first field:value pair is returned as the first return value.
    def parse_search_string(str, valid_keys)
      valid_keys = valid_keys.map{|v| v.to_s}
      operators = [':']
      indices = []
      loop do
        offset = (indices.last) ? str.index(Regexp.union(operators), indices.last) + 1 : 0
        index = str.index(/(?<=^| )#{Regexp.union valid_keys}#{Regexp.union operators}/, offset)
        (index) ? indices << index : break
      end
      pairs = {}
      indices.each_index do |i|
        field, operator, value = str[Range.new(indices[i], (indices[i+1] || 0) - 1)].strip.partition(Regexp.union operators)
        pairs[field] = value.strip
      end
      return str[Range.new(0, indices.first || str.length, true)].strip.gsub(/ +/, ' '), pairs
    end
    
  end
end