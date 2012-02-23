class Sequel::Model::Errors
  alias_method :add_one, :add
  
  def add(key, *values)
    values.each{ |val| add_one(key, val) }
  end
end

module Tombstone
  class BaseModel < Class.new(Sequel::Model)
    set_restricted_columns :modified_by, :modified_at, :created_by, :created_at
    
    def validate
      datetime_columns = db_schema.select { |col, info| info[:type] == :datetime }.map { |k,v| k }
      validates_not_string datetime_columns
      datetime_columns.each do |field|
        errors.add(field, "must be a valid date or time") if (self[field] && !self[field].is_a?(Time))
      end
    end
    
    def set_only_valid(hash)
      set hash.select { |k,v| k = k.to_sym; db_schema[k] && !self.class.restricted_columns.include?(k) }
    end
    
    remove_instance_variable(:@dataset)
    
    class << self
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