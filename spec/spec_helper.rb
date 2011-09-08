SPEC_CONFIG = eval(File.read(File.join(File.dirname(__FILE__),'spec_config.rb')))

Mysql2::Client.default_query_options[:connect_flags] |= Mysql2::Client::MULTI_STATEMENTS
client = Mysql2::Client.new(SPEC_CONFIG[:db].merge(:database => nil))
client.query("
  DROP DATABASE IF EXISTS `#{SPEC_CONFIG[:db][:database]}`;
  CREATE DATABASE `#{SPEC_CONFIG[:db][:database]}`;
  USE `#{SPEC_CONFIG[:db][:database]}`;
  
  CREATE TABLE `user` (
    `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
    `name` varchar(128) NOT NULL,
    `email` varchar(255) DEFAULT NULL,
    `age` tinyint(3) unsigned DEFAULT NULL,
    PRIMARY KEY (`id`)
  ) ENGINE=MyISAM DEFAULT CHARSET=latin1;
")