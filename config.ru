Dir.chdir File.expand_path("../app", __FILE__)
require './app.rb'
run Tombstone::Root
