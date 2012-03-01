
module Tombstone
  class Search
    @@searchable = {
      dob: {field: "[PERSON].[DATE_OF_BIRTH]", matcher: proc { |v| "#{v}%" }},
      name: {field: "(' '+[PERSON].[TITLE]+' '+[PERSON].[FIRST_NAME]+' '+[PERSON].[SURNAME])", matcher: proc { |v| "% #{v}%" }},
      email: {field: "[CONTACT].[EMAIL]", matcher: proc { |v| "#{v}%"}},
      address: {
        field: "(' '+[CONTACT].[STREET_ADDRESS]+', '+[CONTACT].[TOWN]+' '+[CONTACT].[STATE]+' '+CAST([CONTACT].[POSTAL_CODE] as nvarchar))",
        matcher: proc { |v| "% #{v}%" }
      }
    }
    @@sortable = {
      given_name: '[PERSON].[GIVEN_NAME]',
      surname: '[PERSON].[SURNAME]'
    }
    
    class << self
      def searchable
        @@searchable
      end
      
      def sortable
        @@sortable
      end
    end
    
    def initialize(db)
      raise ArgumentError, "Database must be an instance of Sequel::Database" unless db.is_a?(Sequel::Database)
      @db = db
    end
    
    # Takes a hash of conditions (searchable fields with the value to match on), and an optional array of sortable fields
    # to sort on. The sort order argument should be an array where ever odd element is a field, and every even element is
    # the sort direction (either :asc, or :desc)
    # Returns a dataset corresponding to the Model association with the current class.
    def query(conditions = {}, *order)
      @conditions = conditions.select { |k,v| @@searchable[k] }
      @order = order.each_slice(2).to_a.select { |field, dir| @@sortable[field] }
      to_dataset @db[sql_composer]
    end
    
  protected
  
    def to_dataset(result_set)
      model = self.class.const_get(:MODEL)
      pk = (model.primary_key.is_a? Array) ? model.primary_key : [model.primary_key]
      model.select_all(model.table_name).join(result_set, pk.reduce({}) { |memo, k|
        memo[k] = k; memo
      }).order(*@order.map { |field, dir|
        (dir == :asc) ? field.to_sym.asc : field.to_sym.desc
      })
    end
    
    def columns_sql
      unless @order.empty?
        @order.map { |field, dir|
          function = (dir == :asc) ? 'MIN' : 'MAX'
          "#{function}(#{@@sortable[field]}) AS #{field}"
        }.join(', ').insert(0, ', ')
      end
    end
    
    def conditions_sql
      unless @conditions.empty?
        @conditions.map { |field, value|
          matcher = @@searchable[field][:matcher].call(value)
          "(#{@@searchable[field][:field]} LIKE #{@db.literal(matcher)})"
        }.join(' AND ').insert(0, 'WHERE ')
      end
    end
  
    def sql_composer(*args)
      raise StandardError, "Method #{__method__} has not been implemented for class #{self.class}."
    end
  end
  
  class AllocationSearch < Search
    @@sortable = @@sortable.merge(
      created_at: {field: '[ALLOCATION].[CREATED_AT]', title: 'Date created'},
      modified_at: {field: '[ALLOCATION].[MODIFIED_AT]', title: 'Date modified'}
    )
    MODEL = Allocation
    
    def sql_composer
      pk_sql = "[ALLOCATION].[ID], [ALLOCATION].[TYPE]"
      "SELECT DISTINCT #{pk_sql} #{columns_sql}
      FROM [ALLOCATION]
      LEFT JOIN [ROLE_ASSOCIATION] ON [ALLOCATION_ID] = [ALLOCATION].[ID] AND [ALLOCATION_TYPE] = [ALLOCATION].[TYPE]
      LEFT JOIN [ROLE] ON [ROLE].[ID] = [ROLE_ASSOCIATION].[ROLE_ID]
      LEFT JOIN [PERSON] ON [PERSON].[ID] = [ROLE].[PERSON_ID]
      LEFT JOIN [CONTACT] ON ([CONTACT].[ID] = [ROLE].[RESIDENTIAL_CONTACT_ID]) OR ([CONTACT].[ID] = [ROLE].[MAILING_CONTACT_ID])
      #{conditions_sql}
      GROUP BY #{pk_sql}"
    end

  end
  
  class PersonSearch < Search
    @@sortable = @@sortable.merge(
      created_at: {field: '[PERSON].[CREATED_AT]', title: 'Date created'},
      modified_at: {field: '[PERSON].[MODIFIED_AT]', title: 'Date modified'}
    )
    MODEL = Person
      
    def sql_composer
      pk_sql = "[PERSON].[ID]"
      "SELECT DISTINCT #{pk_sql} #{columns_sql}
      FROM [PERSON]
      LEFT JOIN [ROLE] ON [ROLE].[PERSON_ID] = [PERSON].[ID]
      LEFT JOIN [CONTACT] ON [CONTACT].[ID] = [ROLE].[RESIDENTIAL_CONTACT_ID] OR [CONTACT].[ID] = [ROLE].[MAILING_CONTACT_ID]
      LEFT JOIN [ROLE_ASSOCIATION] ON [ROLE_ASSOCIATION].[ROLE_ID] = [ROLE].[ID]
      LEFT JOIN [ALLOCATION] ON [ALLOCATION].[ID] = [ROLE_ASSOCIATION].[ALLOCATION_ID] AND [ALLOCATION].[TYPE] = [ROLE_ASSOCIATION].[ALLOCATION_TYPE]
      #{conditions_sql}
      GROUP BY #{pk_sql}"
    end
  end
end
