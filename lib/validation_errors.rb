module Tombstone
  
  # An ordinary array, except it contains a few helper methods.
  # Array entries are expected to themselves be arrays of fields, with the last element in the array being the error message.
  # Example: ['mobile', 'phone', 'At least one phone number must be provided']
  class ValidationErrors < Array
    def add(*args)
      self << args
    end
    
    # Returns an array of fields that have errors.
    def fields
      fields = []
      self.each do |error|
        error[0..-2].each { |field| fields << field}
      end
      fields.uniq || []
    end
    
    # Returns an array of error messages.
    def messages
      messages = []
      self.each { |error| messages << error.last }        
      messages
    end
  end
end