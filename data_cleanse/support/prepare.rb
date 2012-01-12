require 'tiny_tds'
require 'logger'

LOG = Logger.new('./log.txt')
DB = TinyTds::Client.new(username: 'trc\\trcadmin', password: File.read('./support/password.txt').strip, database: 'Cemeteries', host: 'trcsql02.trc.local')