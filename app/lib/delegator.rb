module Tombstone
  module Delegator
    def delegate(obj, *methods)
      methods.each do |method|
        define_method(method) { |*args| obj.send(method, *args) }
      end
    end
  end
end