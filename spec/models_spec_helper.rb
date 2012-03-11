require 'date'
require 'sequel'

current_dir = File.dirname(__FILE__)

Sequel.extension :migration 
db = Sequel::Model.db

# Recreate the database tables
db.drop_table(*db.tables)
Sequel::Migrator.apply(db, File.join(current_dir, '/../db/migrations'))

`cd #{current_dir}/../ && padrino rake db:populate --environment spec`