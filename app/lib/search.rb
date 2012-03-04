
module Tombstone
  class Search
    @@searchable = {
      dob: {field: "[PERSON].[DATE_OF_BIRTH]", matcher: proc { |v| "09/03/1934" rescue nil }},
      name: {field: "(' '+[PERSON].[TITLE]+' '+[PERSON].[GIVEN_NAME]+' '+[PERSON].[SURNAME])", matcher: proc { |v| "% #{v}" }},
      email: {field: "[CONTACT].[EMAIL]", matcher: proc { |v| "#{v}"}},
      address: {
        field: "(' '+[CONTACT].[STREET_ADDRESS]+', '+[CONTACT].[TOWN]+' '+[CONTACT].[STATE]+' '+CAST([CONTACT].[POSTAL_CODE] as nvarchar))",
        matcher: proc { |v| "% #{v}" }
      }
    }
    @@sortable = {
      given_name: '[GIVEN_NAME]',
      surname: '[SURNAME]',
      created_at: '[CREATED_AT]',
      modified_at: '[MODIFIED_AT]'
    }
    
    class << self
      def searchable
        @@searchable
      end
      
      def sortable
        @@sortable
      end
    end
    
    def initialize
      @db = self.class.const_get(:MODEL).db
    end
    
    # Takes a hash of conditions (searchable fields with the value to match on), and an optional array of sortable fields
    # to sort on. The sort order argument should be an array where ever odd element is a field, and every even element is
    # the sort direction (either :asc, or :desc)
    # Returns a dataset corresponding to the Model association with the current class.
    def query(conditions = {}, *order)
      conditions = conditions.symbolize_keys
      @conditions = conditions.select { |k,v| @@searchable[k] }
      @order = order.each_slice(2).to_a.select { |field, dir| @@sortable[field] }
      dataset
    end
    
  protected
    
    def conditions_sql
      unless @conditions.empty?
        @conditions.map { |field, value|
          matcher = @@searchable[field][:matcher].call(value)
          "(#{@@searchable[field][:field]} LIKE #{@db.literal(matcher)})"
        }.select{|v| v}.join(' AND ').insert(0, 'WHERE ')
      end
    end
  end
  
  class AllocationSearch < Search
    MODEL = Allocation
    
    def dataset
      pk_join = [*MODEL.primary_key].reduce({}) { |memo, k| memo[k] = k; memo }
      MODEL.select_all(MODEL.table_name).
        join(searchable_dataset, pk_join).
        left_join(sortable_dataset, pk_join.merge(:role => ['reservee', 'deceased'])).
        order_by(*@order.map { |field, dir| (dir == :asc) ? field.to_sym.asc : field.to_sym.desc })
    end
    
  protected
    
    def searchable_dataset
      @db["
        SELECT DISTINCT [ALLOCATION].[ID], [ALLOCATION].[TYPE]
        FROM [ALLOCATION]
        LEFT JOIN [ROLE_ASSOCIATION] ON [ALLOCATION_ID] = [ALLOCATION].[ID] AND [ALLOCATION_TYPE] = [ALLOCATION].[TYPE]
        LEFT JOIN [ROLE] ON [ROLE].[ID] = [ROLE_ASSOCIATION].[ROLE_ID]
        LEFT JOIN [PERSON] ON [PERSON].[ID] = [ROLE].[PERSON_ID]
        LEFT JOIN [CONTACT] ON ([CONTACT].[ID] = [ROLE].[RESIDENTIAL_CONTACT_ID]) OR ([CONTACT].[ID] = [ROLE].[MAILING_CONTACT_ID])
        #{conditions_sql}
      "]
    end
    
    def sortable_dataset
      @db["
        SELECT [ROLE_ASSOCIATION].[ALLOCATION_ID] as [ID], [ROLE_ASSOCIATION].[ALLOCATION_TYPE] as [TYPE], [ROLE].[TYPE] as [ROLE], [PERSON].[SURNAME], [PERSON].[GIVEN_NAME]
        FROM [ROLE_ASSOCIATION]
        LEFT JOIN [ROLE] ON [ROLE].[ID] = [ROLE_ASSOCIATION].[ROLE_ID]
        LEFT JOIN [PERSON] ON [PERSON].[ID] = [ROLE].[PERSON_ID]
      "]
    end

  end
  
  class PersonSearch < Search
    MODEL = Person
    
    def dataset
      pk_join = [*MODEL.primary_key].reduce({}) { |memo, k| memo[k] = k; memo }
      MODEL.select_all(MODEL.table_name).
        join(searchable_dataset, pk_join).
        order_by(*@order.map { |field, dir| (dir == :asc) ? field.to_sym.asc : field.to_sym.desc })
    end
    
  protected
    
    def searchable_dataset
      @db["
        SELECT DISTINCT [PERSON].[ID]
        FROM [PERSON]
        LEFT JOIN [ROLE] ON [ROLE].[PERSON_ID] = [PERSON].[ID]
        LEFT JOIN [CONTACT] ON ([CONTACT].[ID] = [ROLE].[RESIDENTIAL_CONTACT_ID]) OR ([CONTACT].[ID] = [ROLE].[MAILING_CONTACT_ID])
        #{conditions_sql}
      "]
    end
  end
end
