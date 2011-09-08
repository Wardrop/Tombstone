require "mysql2"
require "set"

module Tombstone
  module MySQLObject

    attr_reader :client
    
    # Takes 2 optional arguments. _values_ should be a hash of field/value pairs. _connection_options_ creates a new instance-specific connection to the
    # database using the given hash of connection options.
    def initialize(values = {}, connection_options = nil)
      @values = {}
      set(values) unless values.empty?
      unless connection_options.nil?
        @client = Mysql2::Client.new(connection_options)
      else
        @client = self.class.client
      end
    end
    
    def [](field)
      field = field.to_s
      @values[field]
    end
    
    def []=(field, value)
      field = field.to_s
      if self.class.fields.select { |f| f.to_s == field }.length >= 1
        @values[field] = value
      else
        raise ArgumentError, "The field '#{field}' does not exist."
      end
    end
    
    # If _replace_all_ is set to true, all existing field values are cleared before the new values are applied. Non-existant fields are ignored.
    def set(values, replace_all = false)
      @values = {} if replace_all
      values.each { |k,v| self[k] = v }
    end
    
    # Returns true when valid, or a ValidationErrors object when invalid. This method is intended to be overriden.
    def validate
      true
    end
    
    def save
      client.query <<-QUERY
        INSERT INTO `#{table}` (#{self.class.format_fields(@values.keys)}) VALUES (#{self.class.format_values(@values.values)})
        ON DUPLICATE KEY UPDATE #{self.class.format_set(@values)}
      QUERY
      client.last_id
      client.affected_rows >= 1
    end
    
    def delete
      if self.class.key_fields.empty?
        criteria = @values
      else
        criteria = {}
        self.class.key_fields.each { |k| criteria[k] = @values[k] }
      end
      client.query("DELETE FROM `#{table}` WHERE #{self.class.format_criteria(criteria)}")
      client.affected_rows >= 1
    end
    
    def to_hash
      @values
    end
  
  public
    
    class << self
      attr_reader :connection_options
      def connection_options=(options)
        @connection_options = options
        @client = nil
      end
      
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
    
    module ClassMethods
      attr_reader :connection_options
      def connection_options=(options)
        @connection_options = options
        @client = nil
      end
      
      def client
        return @client if @client
        if @connection_options.nil?
          MySQLObject.client
        else
          @client = Mysql2::Client.new(@connection_options)
        end
      end
      
      # The name of the primary table to be used. Defaults to the snake_case'd object name. Setting the table name to nil resets it to the default value.
      # Returns the current table name if no argument is given, or the new table name being set.
      # Note, child classes may override key methods such as #save, if for example the class represents objects stored over multiple tables. They may choose
      # to respect or ignore the defined table, or may use additional tables.
      def table(table_name = false)
        if table_name == false
          @table_name ||= self.name.to_s.split('::').last.gsub(/\B[A-Z]/, '_\&').downcase
        elsif(table_name.nil?)
          @table_name = nil
          self.table
        else
          @table_name = table_name
        end
      end
      
      # Loads an object from the database matching the given crtiria hash. Returns a new instance if found, otherwise false.
      def load(criteria = {})
        result = client.query("SELECT #{format_fields} FROM `#{table}` WHERE #{format_criteria(criteria)} LIMIT 1")
        return self.new(result.to_a[0]) if result.count >= 1
        false
      end
      
      # Defines the fields respresented by this object. String's represent standard fields, where as Symbol's are interpreted as key fields (e.g primary keys)
      def fields(*field_names)
        if field_names.empty?
          @fields ||= Set.new
        elsif field_names.length == 1 && field_names[0].nil?
          @fields = Set.new
        else
          @fields = field_names.to_set
        end
      end
      
      # Returns an array of fields of type Symbol (indicating that they're key fields) as strings.
      def key_fields
        fields.select { |f| f.is_a? Symbol }.map { |f| f.to_s }
      end
      
      def format_fields(fields = nil)
        fields ||= self.fields
        fields.map{ |v| "`#{client.escape(v.to_s)}`" }.join(', ')
      end
      
      def format_values(values)
        values.map{ |v| "'#{client.escape(v.to_s)}'" }.join(', ')
      end
      
      def format_set(keys, values = {})
        key_values = (keys.is_a? Hash) ? keys : Hash[keys.zip values]
        key_values.map { |k,v|
          "`#{client.escape(k.to_s)}` = '#{client.escape(v.to_s)}'"
        }.join(', ')
      end
      
      def format_criteria(keys, values = {})
        criteria = (keys.is_a? Hash) ? keys : Hash[keys.zip values]        
        return 'true' if criteria.empty?
        criteria.map { |k,v|
          "`#{client.escape(k.to_s)}` = '#{client.escape(v.to_s)}'"
        }.join(' AND ')
      end
    end
    
  end
end
