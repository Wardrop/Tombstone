require './support/prepare'

result = DB.execute("
  SELECT id, [Given Name], CHARINDEX(' ', [Given Name]) as Chindex
    FROM [Cemeteries].[dbo].[Others]
   WHERE [Middle Name] IS NULL
     AND [Given Name] IS NOT NULL
     AND CHARINDEX(' ', [Given Name]) > 0
").to_a

puts "About to act on #{result.count} rows."
count = 0

result.each do |row|
  matches = row['Given Name'].match(/^([a-zA-Z]{2,}) ([a-zA-Z ]+)$/)
  next if matches.nil?
  
  count += 1

  LOG.info DB.execute("
  BEGIN TRY
    BEGIN TRANSACTION;
      UPDATE [Cemeteries].[dbo].[Others]
      SET [Given Name] = '#{DB.escape(matches[1])}', [Middle Name] = '#{DB.escape(matches[2])}'
      WHERE id = '#{row["id"]}';
    COMMIT;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0
     ROLLBACK;
  END CATCH
  ").cancel
end

puts count












































