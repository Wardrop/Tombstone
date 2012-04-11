module Tombstone
  App.helpers do
    
    # Takes an optional block which is yielded directly before the allocation is validated and saved.
    # Block is given the allocation object and data hash as arguments.
    def save_allocation(allocation, data)
      allocation.db.transaction do
        # Remap form values.
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
        
        allocation.set_valid_only(values)
        allocation.save(validate: false)

        roles_data = data.select { |k,v| allocation.class.valid_roles.include?(k) && !v.nil? && Hash === v }
        roles_data.reject{|k,v| v['use'] }.each do |key, role_data|
          role_errors = Sequel::Model::Errors.new
          begin
            allocation.add_role(Role.create_from(role_data, role_errors))
          rescue Sequel::Rollback => e
            allocation.errors.add(key.to_sym, role_errors)
          end
        end
        allocation.roles.each do |role|
          roles = roles_data.values.select{ |v| v['use'] ==  role.type }
          roles.each do |v|
            r = Role.new.set_valid_only(role.values.merge(type: v['type']))
            if r.valid?
              r.save
              allocation.add_role(r)
            else
              allocation.errors.add(key.to_sym, r.errors)
              raise Sequel::Rollback
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

        if allocation.status == 'provisional'
          allocation.valid?
          allocation.errors.select!{ |k,v| k == :place }
          if allocation.errors.empty?
            if !request.GET.has_key?('confirm') && allocation.has_warnings?
              raise Sequel::Rollback
            else
              allocation.save(validate: false)
            end
          else
            raise Sequel::Rollback
          end
        elsif allocation.errors.empty? && allocation.valid?
          if !request.GET.has_key?('confirm') && allocation.has_warnings?
            raise Sequel::Rollback
          else
            allocation.save
          end
        else
          raise Sequel::Rollback
        end

        update_photos

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

    def update_photos
      if !session[:new_photos].to_a.empty?
        Blob.filter(:id => session[:new_photos]).update(:enabled => 1)
      end
      if !session[:deleted_photos].to_a.empty?
        Blob.filter(:id => session[:deleted_photos]).delete
      end
      reset_photos_changes
    end

    def reset_photos_changes
      session[:new_photos] = []
      session[:deleted_photos] = []
    end
    
    def json_response(obj)
      if Hash === obj
        obj[:errors] = nil if obj[:errors] && obj[:errors].empty?
        obj[:warnings] = nil if obj[:warnings] && obj[:warnings].empty?
        self.response.status = 500 if obj[:errors] || obj[:warnings] 
      end
      obj.to_json
    end
    
    # Takes a plot name with optional range. Returns an array of generated names if range exists and is valid, otherwise
    # returns an error string when invalid. Returns nil if there are no square brackets in the string.
    # Error handling is made verbose as to guide to the user.
    def parse_place_name(name)
      if name =~ /[\[\]]/
        if name.scan(/[\[\]]/).length > 2
          'Found multiple opening or closing square brackets. Only one range can be specified.'
        elsif not name.match(/\[[^\[\]]+\]/)
          'Mismatched square brackets.'
        elsif not name.match(/\[\w+[.]{2,3}\w+\]/)
          'Invalid range specified. Must be in the form [\w..\w] or [\w...\w] where "\w" is one or more word '+
            'characters (e.g. numbers, letters).'
        else
          full, before, from, type, to, after = name.match(/(.*)\[(\w+)([.]{2,3})(\w+)\](.*)/).to_a
          begin
            range = Range.new(from, to, (type.length == 3)).to_a
            range.map! { |v| "#{before}#{v}#{after}" }
          rescue ArgumentError => e
            'Invalid range specified.'
          end
        end
      end
    end
    
  end
end