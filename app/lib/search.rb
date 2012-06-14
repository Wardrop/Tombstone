
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
          dob: proc { |v,o|
            v = date_value(v)
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
            v = date_value(v)
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
          name: proc { |v,o|
            v = text_value(v)
            "([PERSON].[TITLE]+' '+[PERSON].[GIVEN_NAME]+' '+[PERSON].[SURNAME]) LIKE #{@db.literal(v)}" 
          },
          email: proc { |v,o|
            v = text_value(v)
            "[CONTACT].[EMAIL] LIKE #{@db.literal(v)}"
          },
          address: proc { |v,o|
            v = text_value(v)
            "([CONTACT].[STREET_ADDRESS]+', '+[CONTACT].[TOWN]+' '+[CONTACT].[STATE]+' '+[CONTACT].[COUNTRY]+' '+[CONTACT].[POSTAL_CODE]) LIKE #{@db.literal(v)}"
          },
          place: proc { |v,o|
            v = text_value(v)
            "[PLACE].[FULL_NAME] LIKE #{@db.literal(v)}"
          },
        }
      end
      
      def sortable
        {
          given_name: '[GIVEN_NAME]',
          surname: '[SURNAME]',
          created_at: '[CREATED_AT]',
          modified_at: '[MODIFIED_AT]'
        }
      end
    end
    
    def initialize
      @db = self.class.const_get(:MODEL).db
    end
    
    # Takes a hash of conditions (searchable fields with the value to match on), and an optional array of sortable fields
    # to sort on. The sort order argument should be an array where ever odd element is a field, and every even element is
    # the sort direction (either :asc, or :desc)
    # Returns a dataset corresponding to the Model association with the current class.
    def query(conditions = [], *order)
      @conditions = conditions
      @order = Hash[*order]
      @order.reject! { |k,v| k.nil? || !self.class.sortable[k.to_sym] }
      dataset
    end
    
    def text_value(value)
      (value =~ /^"(.*)"$/) ? $1 : "%#{value}%"
    end
    
    def date_value(value)
      (value =~ /^"(.*)"$/) ? $1 : value
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
        order_by(*@order.map { |field, dir| (dir == 'asc') ? field.to_sym.asc : field.to_sym.desc }).
        limit(50)
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
          all: proc { |v|
            self.class.searchable.reject{|k,v| k == :all}.map { |field, matcher|
              part = instance_exec(v, &matcher)
              "(#{part})" if part
            }.select{|v| v}.join(' OR ')
          },
          name: proc { |v|
            "[PLACE].[NAME] LIKE #{@db.literal("%#{v}%")}"
          },
          type: proc { |v|
            "[PLACE].[TYPE] LIKE #{@db.literal("%#{v}%")}"
          },
          status: proc { |v|
            "[PLACE].[STATUS] LIKE #{@db.literal("%#{v}%")}"
          }
        }
      end
      
      def sortable
        {
          name: '[NAME]',
          type: '[TYPE]',
          status: '[STATUS]'
        }
      end
    end
    
    def dataset
      pk_join = [*MODEL.primary_key].reduce({}) { |memo, k| memo[k] = k; memo }
      MODEL.select_all(MODEL.table_name).where(conditions_sql).
        order_by(*@order.map { |field, dir| (dir == :asc) ? field.to_sym.asc : field.to_sym.desc })
    end
  end
end
