
module Tombstone
  class Person < BaseModel
    set_primary_key :id
    one_to_many :roles, :key => :person_id, :class => :'Tombstone::Role'
    
    class << self
      def valid_titles
        ['Mr', 'Ms', 'Mrs', 'Miss', 'Sir', 'Lady', 'Doctor', 'Director', 'Executor', 'Manager']
      end
      
      def search(hash, limit = 50)
        hash = hash.clone
        wildcard_params = [:given_name, :middle_name, :surname]
        wildcard_params.each { |k| hash[k] = "%#{hash[k]}%" }
        db["
        	SELECT #{limit ? 'TOP '+limit.to_s : ''} *
        	FROM
        	(
        		  SELECT Records.ID, SUM(Records.Score) as Score
        		  FROM
        		  (
        				SELECT PERSON.ID, 20 * (CONVERT(Float,(LEN(:given_name) - 2)) / NULLIF(LEN(PERSON.GIVEN_NAME), 0)) AS Score
        				FROM PERSON
        				WHERE PERSON.GIVEN_NAME LIKE :given_name
        				UNION ALL
                SELECT PERSON.ID, 10 * (CONVERT(Float,(LEN(:middle_name) - 2)) / NULLIF(LEN(PERSON.MIDDLE_NAME), 0)) AS Score
        				FROM PERSON
        				WHERE PERSON.MIDDLE_NAME LIKE :middle_name
        				UNION ALL
        				SELECT PERSON.ID, 30 * (CONVERT(Float,(LEN(:surname) - 2)) / NULLIF(LEN(PERSON.SURNAME), 0)) AS Score
        				FROM PERSON
        				WHERE PERSON.SURNAME LIKE :surname
        				UNION ALL
        				SELECT PERSON.ID, 50 AS Score
        				FROM PERSON
        				WHERE PERSON.DATE_OF_BIRTH = :date_of_birth
                UNION ALL
        				SELECT PERSON.ID, 50 AS Score
        				FROM PERSON
        				WHERE PERSON.DATE_OF_DEATH = :date_of_death
        		  ) AS Records
        		  GROUP BY Records.ID
        	) AS Scores
        	LEFT JOIN PERSON ON Scores.ID = PERSON.ID
        	WHERE Scores.Score > 0 AND (PERSON.GENDER = :gender OR :gender IS NULL OR PERSON.GENDER IS NULL)
        	ORDER BY Score DESC
        ", {
          given_name: nil,
          middle_name: nil,
          surname: nil,
          gender: nil,
          date_of_birth: nil,
          date_of_death: nil
        }.merge(hash)].to_a
      end
    end
    
    def name
      "#{title} #{given_name} #{middle_name} #{surname}"
    end
    
    def validate
      super
      validates_includes self.class.valid_titles, :title
      validates_min_length 2, [:given_name, :surname]
      validates_presence [:date_of_birth, :gender]
      validates_includes ['male', 'female'], :gender
      errors.add(:date_of_birth, "must be before today") { date_of_birth < Date.today }
    end
    
    # Filters
    def roles_by_type(type, allocation_dataset = Allocation)
      self.roles_dataset.filter(:role__type => type).
          filter(
            allocation_dataset.
              left_join(:role_association, :allocation_id => :allocation__id).
              exclude(:status => 'deleted').
              filter(:role_association__role_id => :role__id).
              exists
          )
    end
    
    def role_by_type(type)
      roles_by_type(type).first
    end
    
    # def role_count(type)
    #   Tombstone::Allocation.
    #     join(:role_association, :allocation_id => :id).
    #     join(:role, :id => :role_id, :type => type).
    #     exclude(:allocation__status => 'deleted').
    #     filter(:person_id => role.person_id).
    #     exclude(primary_key_hash.map{|k,v| ["allocation__#{k}".to_sym, v]}.sql_expr).
    #     count
    # end
    
  end
end