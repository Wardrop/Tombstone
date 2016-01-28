-- ================================================
-- Template generated from Template Explorer using:
-- Create Procedure (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the procedure.
-- ================================================
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
IF OBJECT_ID('PersonSearch') IS NOT NULL
DROP PROC PersonSearch

CREATE PROCEDURE PersonSearch
	-- Add the parameters for the stored procedure here
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
