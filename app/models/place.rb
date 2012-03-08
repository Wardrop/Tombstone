
module Tombstone
  class Place < BaseModel
    set_primary_key :id
    many_to_one :parent, :class => self, :key => :parent_id
    one_to_many :children, :class => self, :key => :parent_id
    one_to_many :allocations, :class => :'Tombstone::Allocation', :key => :place_id
    
    def_dataset_method(:with_child_count) do
      left_join(Place.group(:parent_id).select{[count(parent_id).as(child_count), :parent_id___child_parent_id]}, :child_parent_id => :place__id)
    end
    
    def_dataset_method(:available_only) do
      allocation_filter = Allocation.select(:place_id).exclude(status: 'deleted').group(:place_id)
      filter(:place__status => 'available').
      left_join(allocation_filter.as(:allocation), :place_id => :id).
      filter(allocation__place_id: nil).
        select_all(:place).
        distinct
    end
    
    class << self
      def valid_states
        ['available', 'unavailable']
      end
    end
    
    def validate
      super
      errors.add(:status, "must be one of: #{self.class.valid_states.join(', ')}") if !self.class.valid_states.include? status
      validates_min_length 2, :type
    end
    
    def allows_interment?
      status == 'available' \
      && children_dataset.count == 0 \
      && calculated_max_interments > allocations_dataset.filter(type: 'interment').exclude(:status => 'deleted').count
    end
    
    def calculated_max_interments
      ancestors(true).reverse.reduce(1){|max, place| (place.max_interments.to_i > 0) ? place.max_interments : max}
    end
    
    def siblings
      self.class.filter(:parent_id => parent_id).order(:id)
    end
    
    def ancestors(include_self = false, upto = 0)
      column_string = self.class.dataset.columns.map { |v| "[#{v}]"}.join(', ')
      aliased_column_string = self.class.dataset.columns.map { |v| "p.[#{v}]"}.join(', ')
      array = self.db["
        WITH PlaceAncestors (#{column_string})
        AS
        (
        -- Anchor member definition
            SELECT #{column_string}
            FROM dbo.Place
            WHERE ID = :id
            UNION ALL
        -- Recursive member definition
        	  SELECT #{aliased_column_string}
            FROM dbo.Place AS p
            INNER JOIN PlaceAncestors AS a
        		ON p.ID = a.Parent_ID
            WHERE p.ID != :upto
        )
        -- Statement that executes the CTE
        SELECT *
        FROM PlaceAncestors
        GO
      ", {:id => self.id, :upto => upto}].to_a
      ((include_self) ? array : array[1..-1]).map { |v| Place.call(v) }
    end
    
    def next_available
      column_string = self.class.dataset.columns.map { |v| "[#{v}]"}.join(', ')
      aliased_column_string = self.class.dataset.columns.map { |v| "p.[#{v}]"}.join(', ')
      place = self.db["   
        WITH PlaceChildren (#{column_string}, LEVEL, [ORDER])
        AS
        (
        -- Anchor member definition   
        	SELECT #{column_string}, 0 as LEVEL, CAST(RIGHT('0000000' + CAST(id as nvarchar),7) as nvarchar) as [ORDER]
        	FROM [PLACE]
        	WHERE status = 'available'
        		AND parent_id = :parent_id
        	UNION ALL
              
        -- Recursive member definition
        	SELECT #{aliased_column_string}, LEVEL + 1, CAST(([ORDER] + RIGHT('0000000' + CAST(p.id as nvarchar),7)) as nvarchar)
        	FROM [PLACE] as p
        	INNER JOIN PlaceChildren AS a
        		ON p.parent_id = a.ID
        	WHERE p.status = 'available'
        		AND p.parent_id = a.id
        )
        
        -- Statement that executes the CTE
        SELECT TOP 1 #{column_string}
        FROM PlaceChildren
        WHERE (id NOT IN (SELECT place_id FROM [allocation] WHERE type = 'interment' AND status != 'deleted'))
          AND (id NOT IN (SELECT parent_id FROM [place] WHERE parent_id IS NOT NULL))
        ORDER BY LEVEL DESC, [order] ASC
      ", {:parent_id => self.id}].first
      Place.call(place)
    end
  end
end