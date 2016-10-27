module Tombstone
  class Sequel::Model::Errors
    # Override method to support taking a block which is only executed if the field doesn't currently have any errors.
    # Also adds support for multiple error messages.
    def add(att, *msg)
      fetch(att){self[att] = []}
      if block_given?
        self[att].push(*msg) if self[att].empty? && !yield
      else
        self[att].push(*msg)
      end
    end
  end
end
