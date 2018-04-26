#! /bin/ruby

Dir.chdir('..')

$LOAD_PATH << Dir.pwd

require 'Autoload'

$logger = Logger.new(AppConfig.log.path)
$logger.level=(AppConfig.log.level)
AppConfig.Interface = 'CGI'

Interface.new