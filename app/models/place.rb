module Tombstone
  class Place < BaseModel
    set_primary_key :id
    many_to_one :parent, :class => self, :key => :parent_id
    one_to_many :children, :class => self, :key => :parent_id
    one_to_many :allocations, :class => :'Tombstone::Allocation', :key => :place_id
    one_to_many :files, :class => :'Tombstone::Blob', :key => :place_id
    set_dataset dataset.disable_insert_output

    def_dataset_method(:with_child_count) do
      left_join(
        Place.group(:parent_id).select{[count(parent_id).as(child_count), :parent_id___child_parent_id]},
        :child_parent_id => :place__id
      )
    end

    def_dataset_method(:with_natural_order) do
      select_append("ISNULL (TRY_PARSE([place].[name] as Integer), 2147483647) as [NATURAL_ORDER]".lit).order(:NATURAL_ORDER.asc, :name.asc)
    end

    def_dataset_method(:available_only) do
      allocation_filter = Allocation.select(:place_id).exclude(status: 'deleted').group(:place_id)

      dataset = filter(:place__status => 'available').
      left_join(allocation_filter.as(:allocation), :allocation__place_id => :place__id).
      filter(allocation__place_id: nil).
      distinct
    end

    class << self
      def valid_states
        ['available', 'unavailable']
      end
    end

    def validate
      super
      validates_min_length 1, :name
      errors.add(:name, "cannot contain less than or greater than character (ie. > or <)") { !name.include?('>') && !name.include?('<') }
      validates_min_length 1, :type
      validates_includes self.class.valid_states, :status
      validates_schema_types :max_interments
      errors.add(:parent, "does not exist") if !parent_id.nil? && parent.nil?
      siblings = self.siblings(false).all
      unless siblings.empty?
        type.downcase! if type
        errors.add(:type, "must be same as siblings (#{siblings[0].type.capitalize()})") { type.casecmp(siblings[0].type) == 0 }
        errors.add(:name, "must be unique among siblings") { siblings.select{ |s| s.name == name }.empty? }
      end
    end

    def allows_reservation?(excluded_allocation = nil)
      allocations = allocations_dataset.filter(type: 'reservation').exclude(:status => 'deleted')
      allocations = allocations.exclude(excluded_allocation.primary_key_hash) if Allocation === excluded_allocation
      status == 'available' \
      && children_dataset.count == 0 \
      && allocations.count == 0
    end

    def allows_interment?(excluded_allocation = nil)
      allocations = allocations_dataset.filter(type: 'interment').exclude(:status => 'deleted')
      allocations = allocations.exclude(excluded_allocation.primary_key_hash) if Allocation === excluded_allocation
      status == 'available' \
      && children_dataset.count == 0 \
      && calculated_max_interments > allocations.count
    end

    def calculated_max_interments
      ancestors(true).reverse.reduce(1){|max, place| (place.max_interments.to_i > 0) ? place.max_interments : max}
    end

    def description
      self.full_name
    end

    def cemetery
      self.ancestors[-1]
    end

    def siblings(include_self = true)
      dataset = self.class.filter(:parent_id => parent_id).order(:id)
      if include_self
        dataset
      else
        dataset.exclude(:id => id)
      end
    end

    def children
      self.class.filter(:parent_id => id).order(:id)
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
        WHERE (id NOT IN (SELECT place_id FROM [allocation] WHERE status != 'deleted'))
          AND (id NOT IN (SELECT parent_id FROM [place] WHERE parent_id IS NOT NULL))
        ORDER BY LEVEL DESC, [order] ASC
      ", {:parent_id => self.id}].first
      (Hash === place) ? Place.call(place) : nil
    end
  end
end
