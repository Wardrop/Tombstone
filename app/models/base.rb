
module Tombstone
  class BaseModel < Class.new(Sequel::Model)
    set_restricted_columns :modified_by, :modified_at, :created_by, :created_at
    plugin :typecast_on_load
    remove_instance_variable(:@dataset)

    def warnings
      @warnings ||= Sequel::Model::Errors.new
    end
    
    def has_warnings?
      check_warnings
      !self.warnings.empty?
    end
    
    def check_warnings; end
    
    def validate
      validates_not_string self.class.datetime_columns
    end
    
    def set_valid_only(hash)
      set(self.class.valid_only(hash))
    end
    
    def primary_key_hash(aliased = false)
      keys = values.select { |k,v| [*primary_key].include?(k) }
      (aliased) ? Hash[*keys.map{|k,v| ["#{self.class.table_name}__#{k}".to_sym, v] }.flatten] : keys
    end
    
    def before_update
      super
      self.class.dataset.columns.each do |column|
        case column
        when :modified_by
          self.modified_by = (User.current) ? User.current.id : nil
        when :modified_at
          self.modified_at = DateTime.now
        end    
      end
    end
    
    def before_create
      super
      self.class.dataset.columns.each do |column|
        case column
        when :created_by
          self.created_by = (User.current) ? User.current.id : nil
        when :created_at
          self.created_at = DateTime.now
        end
      end
    end
    
    
    class << self
      
      def inherited(model)
        super
        model.add_typecast_on_load_columns *datetime_columns
      end
      
      def datetime_columns
        db_schema.select { |col, info| info[:type] == :datetime }.map { |k,v| k }
      end
      
      def valid_only(hash)
        restricted = restricted_columns +
                     (restrict_primary_key? ? [*primary_key] : [])
        hash.select { |k,v|
          k = k.to_sym
          db_schema[k] && !restricted.include?(k)
        }
      end
      
      def prepare_values(hash)
        valid = valid_only(hash)
        datetime_columns.each do |k|
          valid[k] = Sequel.datetime_class.parse(valid[k]) if valid[k]
        end
        valid
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