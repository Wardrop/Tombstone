
module Tombstone
  class BaseModel < Class.new(Sequel::Model)
    set_restricted_columns :modified_by, :modified_at, :created_by, :created_at
    
    def warnings
      @warnings ||= Sequel::Model::Errors.new
    end
    
    def has_warnings?
      check_warnings
      !self.warnings.empty?
    end
    
    def check_warnings; end
    
    def validate
      datetime_columns = db_schema.select { |col, info| info[:type] == :datetime }.map { |k,v| k }
      validates_not_string datetime_columns
    end
    
    def set_valid_only(hash)
      set(self.class.valid_only(hash))
    end
    
    def primary_key_hash(aliased = false)
      keys = values.select { |k,v| primary_key.include? k }
      (aliased) ? Hash[*keys.map{|k,v| ["#{self.class.table_name}__#{k}".to_sym, v] }.flatten] : keys
    end
    
    remove_instance_variable(:@dataset)
    
    class << self
      def valid_only(hash)
        restricted = restricted_columns +
                     (restrict_primary_key? ? [*primary_key] : [])
        hash.select { |k,v|
          k = k.to_sym
          db_schema[k] && !restricted.include?(k)
        }
      end
      
      def implicit_table_name
        underscore(demodulize(name)).to_sym
      end
      
      def filter_by_columns(hash)
        hash.select { |k,v| k = k.to_sym; db_schema[k] && !restricted_columns.include?(k) }
      end
    end
  end
  
  def self.BaseModel(source)
    BaseModel::ANONYMOUS_MODEL_CLASSES[source] ||= if source.is_a?(Sequel::Database)
      c = Class.new(BaseModel)
      c.db = source
      c
    else
      Class.new(BaseModel).set_dataset(source)
    end
  end
  
end