
module Tombstone
  class Search
    
    class << self
      def searchable
        {
          all: proc { |v,o|
            self.class.searchable.reject{|k,v| k == :all}.map { |field, matcher|
              part = instance_exec(v, &matcher)
              "(#{part})" if part
            }.select{|v| v}.join(' OR ')
          },
          id: proc { |v,o|
            v = integer_value(v)
            (v) ? "[ALLOCATION].[ID] = #{@db.literal(v)}" : nil
          },
          dob: proc { |v,o|
            v = strict_value(v)
            begin
              date = Date.strptime(v, '%d/%m/%Y')
              case o
              when ':'
                "[PERSON].[DATE_OF_BIRTH] >= #{@db.literal(date.strftime('%d/%m/%Y'))} AND [PERSON].[DATE_OF_BIRTH] < #{@db.literal((date + 1).strftime('%d/%m/%Y'))}"
              when '>'
                "[PERSON].[DATE_OF_BIRTH] > #{@db.literal(date.strftime('%d/%m/%Y'))}"
              when '<'
                "[PERSON].[DATE_OF_BIRTH] < #{@db.literal(date.strftime('%d/%m/%Y'))}"
              end
            end rescue nil
          },
          dod: proc { |v,o|
            v = strict_value(v)
            begin
              date = Date.strptime(v, '%d/%m/%Y')
              case o
              when ':'
                "[PERSON].[DATE_OF_DEATH] >= #{@db.literal(date.strftime('%d/%m/%Y'))} AND [PERSON].[DATE_OF_DEATH] < #{@db.literal((date + 1).strftime('%d/%m/%Y'))}"
              when '>'
                "[PERSON].[DATE_OF_DEATH] > #{@db.literal(date.strftime('%d/%m/%Y'))}"
              when '<'
                "[PERSON].[DATE_OF_DEATH] < #{@db.literal(date.strftime('%d/%m/%Y'))}"
              end
            end rescue nil
          },
          created: proc { |v,o|
            v = strict_value(v)
            begin
              date = Date.strptime(v, '%d/%m/%Y')
              case o
              when ':'
                "[ALLOCATION].[CREATED_AT] >= #{@db.literal(date.strftime('%d/%m/%Y'))} AND [ALLOCATION].[CREATED_AT] < #{@db.literal((date + 1).strftime('%d/%m/%Y'))}"
              when '>'
                "[ALLOCATION].[CREATED_AT] > #{@db.literal(date.strftime('%d/%m/%Y'))}"
              when '<'
                "[ALLOCATION].[CREATED_AT] < #{@db.literal(date.strftime('%d/%m/%Y'))}"
              end
            rescue
              "[ALLOCATION].[CREATED_BY] LIKE #{@db.literal(v)}"
            end
          },
          modified: proc { |v,o|
            v = strict_value(v)
            begin
              date = Date.strptime(v, '%d/%m/%Y')
              case o
              when ':'
                "[ALLOCATION].[MODIFIED_AT] >= #{@db.literal(date.strftime('%d/%m/%Y'))} AND [ALLOCATION].[MODIFIED_AT] < #{@db.literal((date + 1).strftime('%d/%m/%Y'))}"
              when '>'
                "[ALLOCATION].[MODIFIED_AT] > #{@db.literal(date.strftime('%d/%m/%Y'))}"
              when '<'
                "[ALLOCATION].[MODIFIED_AT] < #{@db.literal(date.strftime('%d/%m/%Y'))}"
              end
            rescue
              "[ALLOCATION].[MODIFIED_BY] LIKE #{@db.literal(v)}"
            end
          },
          name: proc { |v,o|
            v = wildcard_value(v)
            "([PERSON].[GIVEN_NAME]+' '+[PERSON].[SURNAME]) LIKE #{@db.literal(v)} OR
            ([ALLOCATION].[ALTERNATE_RESERVEE]) LIKE #{@db.literal(v)}" 
          },
          address: proc { |v,o|
            v = wildcard_value(v)
            "([CONTACT].[STREET_ADDRESS]+', '+[CONTACT].[TOWN]+' '+[CONTACT].[STATE]+' '+[CONTACT].[COUNTRY]+' '+[CONTACT].[POSTAL_CODE]) LIKE #{@db.literal(v)}"
          },
          interment_date: proc { |v,o|
            v = strict_value(v)
            begin
              date = Date.strptime(v, '%d/%m/%Y')
              case o
              when ':'
                "[ALLOCATION].[INTERMENT_DATE] >= #{@db.literal(date.strftime('%d/%m/%Y'))} AND [ALLOCATION].[INTERMENT_DATE] < #{@db.literal((date + 1).strftime('%d/%m/%Y'))}"
              when '>'
                "[ALLOCATION].[INTERMENT_DATE] > #{@db.literal(date.strftime('%d/%m/%Y'))}"
              when '<'
                "[ALLOCATION].[INTERMENT_DATE] < #{@db.literal(date.strftime('%d/%m/%Y'))}"
              end
            end rescue nil
          },
          place: proc { |v,o|
            v = wildcard_value(v)
            "[PLACE].[FULL_NAME] LIKE #{@db.literal(v)}"
          },
          status: proc { |v,o|
            v = wildcard_value(v)
            "[ALLOCATION].[STATUS] LIKE #{@db.literal(v)}"
          }
        }
      end
      
      def sortable
        {
          :plot => :place__name,
          # Sequel::LiteralString.new("CASE
          #   WHEN PATINDEX('%[^0-9]%', [PLACE].[NAME]) = 0
          #   THEN Cast([PLACE].[NAME] as Integer)
          #     ELSE 0
          #   END
          # ")
          :given_name => :given_name,
          :surname => :surname,
          :created_at => :created_at,
          :modified_at => :modified_at
        }
      end
    end
    
    def initialize
      @db = self.class.const_get(:MODEL).db
    end
    
    # Takes an array of hashes, where each hash is a search condition consisting of the :field, :operator and :value.
    # An optional array of field/direction pairs can also be provided to set sorting, e.g. [['name', 'desc'], ['id', 'asc']]
    # Returns a dataset corresponding to the Model associated with the current class.
    def query(conditions = [], order = [], limit = 250)
      conditions.select!{ |h| Proc === self.class.searchable[h[:field].to_sym]}
      @conditions = conditions
      @order = Hash[order].reject { |field, dir| field.nil? || !self.class.sortable[field.to_sym] }.
        map{ |field, dir| (dir == 'asc') ? self.class.sortable[field.to_sym].asc : self.class.sortable[field.to_sym].desc }
      @limit = limit
      dataset
    end
    
    def wildcard_value(value)
      (value =~ /^"(.*)"$/) ? $1 : "%#{value}%"
    end
    
    def strict_value(value)
      (value =~ /^"(.*)"$/) ? $1 : value
    end
    
    def integer_value(value)
      match = /^"?([0-9]+)"?$/.match(value)
      match && match[0]
    end
    
  protected
    
    def conditions_sql(prefix = nil)
      conditions_str = @conditions.map { |term|
        condition = instance_exec(term[:value], term[:operator], &self.class.searchable[term[:field]])
        if condition
          "(#{condition})"
        else
          @conditions.reject! { |v| v == term }
        end
      }.select { |v| v }.join(' AND ')
      if conditions_str.empty?
        ""
      else
        (prefix) ? "#{prefix} #{conditions_str}" : conditions_str.to_s
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
        left_join(:place, :place__id => :allocation__place_id).
        order_by(*@order).
        limit(@limit)
    end
    
  protected
    
    def searchable_dataset
      @db["
        SELECT DISTINCT [ALLOCATION].[ID]
        FROM [ALLOCATION]
        LEFT JOIN [ROLE_ASSOCIATION] ON [ALLOCATION_ID] = [ALLOCATION].[ID]
        LEFT JOIN [ROLE] ON [ROLE].[ID] = [ROLE_ASSOCIATION].[ROLE_ID]
        LEFT JOIN [PERSON] ON [PERSON].[ID] = [ROLE].[PERSON_ID]
        LEFT JOIN [CONTACT] ON ([CONTACT].[ID] = [ROLE].[RESIDENTIAL_CONTACT_ID]) OR ([CONTACT].[ID] = [ROLE].[MAILING_CONTACT_ID])
        LEFT JOIN [PLACE] ON [ALLOCATION].[PLACE_ID] = [PLACE].[ID]
        #{conditions_sql("WHERE")}
      "]
    end
    
    def sortable_dataset
      @db["
        SELECT [ROLE_ASSOCIATION].[ALLOCATION_ID] as [ID], [ROLE].[TYPE] as [ROLE], [PERSON].[SURNAME], [PERSON].[GIVEN_NAME]
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
        #{conditions_sql("WHERE")}
      "]
    end
  end
  
  class PlaceSearch < Search
    MODEL = Place

    class << self
      def searchable
        {
          all: proc { |v,o|
            self.class.searchable.reject{|k,v| k == :all}.map { |field, matcher|
              part = instance_exec(v, &matcher)
              "(#{part})" if part
            }.select{|v| v}.join(' OR ')
          },
          id: proc { |v,o|
            v = integer_value(v)
            (v) ? "[PLACE].[ID] = #{@db.literal(v)}" : nil
          },
          name: proc { |v,o|
            v = wildcard_value(v)
            "[PLACE].[NAME] LIKE #{@db.literal(v)}" 
          },
          full_name: proc { |v,o|
            v = wildcard_value(v)
            "[PLACE].[FULL_NAME] LIKE #{@db.literal(v)}"
          },
          type: proc { |v,o|
            v = wildcard_value(v)
            "[PLACE].[TYPE] LIKE #{@db.literal(v)}"
          },
          status: proc { |v,o|
            v = wildcard_value(v)
            "[PLACE].[STATUS] LIKE #{@db.literal(v)}"
          }
        }
      end
      
      def sortable
        {
          :name => :name,
          # Sequel::LiteralString.new("CASE
          #   WHEN PATINDEX('%[^0-9]%', [PLACE].[NAME]) = 0
          #   THEN Cast([PLACE].[NAME] as Integer)
          #     ELSE 0
          #   END
          # ")
          :full_name => :full_name,
          :type => :type,
          :status => :status
        }
      end
    end
    
    def dataset
      pk_join = [*MODEL.primary_key].reduce({}) { |memo, k| memo[k] = k; memo }
      MODEL.select_all(MODEL.table_name).where(conditions_sql).
        order_by(*@order).
        limit(@limit)
    end
  end
end
