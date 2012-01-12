require './support/prepare'

result = DB.execute("
     SELECT Details.id, Details.reserve, [Date of Burial], [Grouped].*
      FROM [Cemeteries_Old].[dbo].[Others] as Details
      JOIN ( SELECT [Surname], [Given Name], [Middle Name], [Historical Plot No], COUNT(*) as [Count]
               FROM [Cemeteries_Old].[dbo].[Others]
              WHERE [Given Name] IS NOT NULL
                AND [Surname] IS NOT NULL
                AND ([Interment] IS NULL OR [Interment] IN ('1', '0', ''))
            GROUP BY ALL [Surname], [Given Name], [Middle Name], [Historical Plot No]
            HAVING Count(*) = 2
               AND MIN(CAST(reserve as tinyint)) = 0
               AND MAX(CAST(reserve as tinyint)) = 1
               AND LEN(MAX([Date of Burial])) >= 1
            ) as Grouped
        ON [Grouped].[Surname] = Details.[Surname] AND
           [Grouped].[Given Name] = Details.[Given Name] AND
           [Grouped].[Historical Plot No] = Details.[Historical Plot No]
  ORDER BY [Historical Plot No] ASC, [Surname] ASC, [Given Name] ASC, [Middle Name] ASC, [reserve] DESC
").to_a

puts "About to act on #{result.count} rows."

result.each_slice(2) do |set|
  reservation = set[0]
  burial = set[1]
  
  
  if reservation['reserve'] != true || burial['reserve'] == true
    puts 'Record mismatch found.'
    next
  end

  LOG.info DB.execute("
  BEGIN TRY
    BEGIN TRANSACTION res#{reservation["id"]}bur#{burial["id"]};
      DELETE FROM [Cemeteries_Old].[dbo].[Others] WHERE id = '#{reservation["id"]}';
      
      UPDATE [Cemeteries_Old].[dbo].[Others]
      SET reserve = 1, interment = '1'
      WHERE id = '#{burial["id"]}';
    COMMIT;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0
     ROLLBACK;
  END CATCH
  ").cancel
end












































