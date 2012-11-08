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
        roles_data.reject{ |k,v| v['use'] }.each do |key, role_data|
          role_errors = Sequel::Model::Errors.new
          begin
            if role_data['id']
              role = Role.with_pk(role_data['id'])
              if role
                role_errors = role.errors
                role.set_valid_only(role_data).save
              else
                role_errors.add(:id, "does not exist")
              end
            else
              allocation.add_role(Role.create_from(role_data, role_errors))
            end
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
              allocation.errors.add(v['type'].to_sym, r.errors)
              raise Sequel::Rollback
            end
          end
        end

        if params['transactions'].is_a? Array
          params['transactions'].reject{ |v| v.blank? }.each do |trans|
            trans = Transaction.new(allocation_id: allocation.id, receipt_no: trans)
            if trans.valid?
              trans.save
            else
              allocation.errors.add(:transaction, trans.errors)
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
            end
          else
            raise Sequel::Rollback
          end
        elsif allocation.errors.empty? && allocation.valid?
          if !request.GET.has_key?('confirm') && allocation.has_warnings?
            raise Sequel::Rollback
          end
        else
          raise Sequel::Rollback
        end
        
        if allocation.new?
          if allocation.status != 'provisonal'
            Notifiers::NewInterment.new(allocation).send
          end
        else
          if allocation.previous_changes.nil? || (allocation.previous_changes[:status] && allocation.previous_changes[:status].first == 'provisional' && allocation.status != 'deleted')
            Notifiers::NewInterment.new(allocation).send
          else
            if allocation.previous_changes[:status]
              Notifiers::ChangedStatus.new(allocation).send
            end
            unless allocation.previous_changes[:interment_date].first == allocation.interment_date
              Notifiers::ChangedIntermentDate.new(allocation).send
            end
          end
        end
      end
    end
    
    # Takes a string in a format similar to "some term field1:some value field2:another value", and returns an array of
    # terms, consisting of the field name, operator and value. Any text before the first term is returned as the first
    # return value.
    def parse_search_string(str)
      str ||= ''
      operators = [':', '>', '<']
      indices = []
      loop do
        offset = (indices.last) ? str.index(Regexp.union(operators), indices.last) + 1 : 0
        index = str.index(/(?<=^| )[a-zA-Z0-9_]+#{Regexp.union operators}/, offset)
        (index) ? indices << index : break
      end
      terms = []
      indices.each_index do |i|
        field, operator, value = str[Range.new(indices[i], (indices[i+1] || 0) - 1)].strip.partition(Regexp.union operators)
        value = value.strip
        terms << {field: field.to_sym, operator: operator, value: value.strip} unless value.empty?
      end
      general_term = str[Range.new(0, indices.first || str.length, true)].strip.gsub(/ +/, ' ')
      terms.unshift(field: :all, operator: ':', value: general_term) unless general_term.empty?
      terms
    end

    def json_response(obj = {})
      cache_control :'no-cache'
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