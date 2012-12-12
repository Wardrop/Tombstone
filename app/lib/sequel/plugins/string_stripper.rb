module Sequel::Plugins::StringStripper::InstanceMethods
  # Add a rescue around the call to #strip to fall-through when dealing with blob and other non UTF-8 data.
  def []=(k, v)
    v.is_a?(String) ? super(k, (v.strip rescue v)) : super
  end
end
