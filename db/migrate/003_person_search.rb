Sequel.migration do
  up do
    self << "SET ANSI_NULLS ON"
    self << "IF OBJECT_ID('PersonSearch') IS NOT NULL DROP PROC PersonSearch"
    self << "
      CREATE PROCEDURE PersonSearch
      	@GivenNameTerm VarChar(50) = NULL,
        @MiddleNameTerm VarChar(50) = NULL,
      	@SurnameTerm VarChar(50) = NULL,
      	@DOBTerm DateTime = NULL,
        @DODTerm DateTime = NULL,
      	@GenderTerm VarChar(50) = NULL
      AS
      BEGIN
      	SELECT *
      	FROM
      	(
      		  SELECT Records.ID, SUM(Records.Score) as Score
      		  FROM
      		  (
      				SELECT PERSON.ID, 20 * (CONVERT(Float,(LEN(@GivenNameTerm) - 2)) / LEN(PERSON.GIVEN_NAME)) AS Score
      				FROM PERSON
      				WHERE PERSON.GIVEN_NAME LIKE @GivenNameTerm
      				UNION ALL
              SELECT PERSON.ID, 10 * (CONVERT(Float,(LEN(@MiddleNameTerm) - 2)) / LEN(PERSON.MIDDLE_NAME)) AS Score
      				FROM PERSON
      				WHERE PERSON.MIDDLE_NAME LIKE @GivenNameTerm
      				UNION ALL
      				SELECT PERSON.ID, 30 * (CONVERT(Float,(LEN(@SurnameTerm) - 2)) / LEN(PERSON.SURNAME)) AS Score
      				FROM PERSON
      				WHERE PERSON.SURNAME LIKE @SurnameTerm
      				UNION ALL
      				SELECT PERSON.ID, 50 AS Score
      				FROM PERSON
      				WHERE PERSON.DATE_OF_BIRTH = @DOBTerm
              UNION ALL
      				SELECT PERSON.ID, 50 AS Score
      				FROM PERSON
      				WHERE PERSON.DATE_OF_DEATH = @DODTerm
      		  ) AS Records
      		  GROUP BY Records.ID
      	) AS Scores
      	LEFT JOIN PERSON ON Scores.ID = PERSON.ID
      	WHERE Scores.Score > 0 AND (PERSON.GENDER = @GenderTerm OR PERSON.GENDER IS NULL OR @GenderTerm IS NULL)
      	ORDER BY Score DESC
      END
    "
  end
  
  down do
    self <<  "IF OBJECT_ID('PersonSearch') IS NOT NULL DROP PROC PersonSearch"
  end
end