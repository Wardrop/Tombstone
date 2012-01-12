require './support/prepare'

result = DB.execute("
SELECT id, [historical plot no]
  FROM [Cemeteries].[dbo].[Others]
 WHERE [Cemetery] = 'MAREEBA NEW' AND [Section] = 'LAWN - PLAQUE ON BEAM'
")

matches = []

result.each do |row|
  match_data = /[0-9]{1,3}/.match(row["historical plot no"])
  if match_data
    LOG.info(row)
    matches << {'id' => row['id'], 'plot' => match_data[0]}
  end
end

matches.each do |match|
  DB.execute("UPDATE Others SET plot = '#{match['plot']}' WHERE [id] = #{match['id']}")
end

# puts matches

puts "Rows found: #{matches.length}"












































