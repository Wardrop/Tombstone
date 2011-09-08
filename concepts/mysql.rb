require 'mysql2'

module SQLObject
  class << self
    attr_accessor :connection_options
    
    def client
      if @client
        return @client
      else
        @client = Mysql2::Client.new(@connection_options || {})
      end
    end
    
    def included(klass)
      klass.extend(ClassMethods)
    end
  end
  
  def initialize(insert = {}, connection_options = nil)    
    unless connection_options.nil?
      @client = Mysql2::Client.new(connection_options)
    else
      @client = self.class.client
    end
  end
  
  module ClassMethods
    attr_accessor :connection_options
    
    def client
      return @client if @client
      
      if @connection_options.nil?
        SQLObject.client
      else
        @client = Mysql2::Client.new(@connection_options)
      end
    end
    
    # Gets or sets the name of the table to be used by the object. Defaults to the name of the object in snake_case (e.g. 'ObjectName' becomes 'object_name').
    def table(table_name = nil)
      if table_name.nil?
        @table_name = self.name.gsub(/\B[A-Z]/, '_\&').downcase
      else
        @table_name = table_name
      end
    end
  end
end

class Person
  include SQLObject
  table 'person'
end

