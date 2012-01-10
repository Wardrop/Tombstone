require_relative './models_helper'

class Relationship < Sequel::Model
  set_primary_key :id
  many_to_one :source_role, {:key => :role1_id, :class => :Role}
  many_to_one :target_role, {:key => :role2_id, :class => :Role}
  
  def primary_role
    @flip ? self.target_role : self.source_role
  end
  
  def secondary_role
    @flip ? self.source_role : self.target_role
  end
  
  def flip_roles!
    @flip = true
  end
  
  def unflip_roles!
    @flip = false
  end
  
  def flipped?
    !!@flip
  end
end