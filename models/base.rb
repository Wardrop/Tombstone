require 'sequel'

module Tombstone
  class BaseModel < Class.new(Sequel::Model)
    remove_instance_variable(:@dataset)
    def self.implicit_table_name
      underscore(demodulize(name)).to_sym
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