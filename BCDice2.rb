#--*-coding:utf-8-*--

$LOAD_PATH << File.dirname(__FILE__)

class BCDice2
  def initialize
    $logger = Logger.new(AppConfig.log.path)
    $logger.level=(AppConfig.log.level)
  end

  def run
    inf = Interface.new
    $logger.debug("wait")
    #inf.open
    #bot = DiceBotLoader.load("D")
    #      bot.execute("2d6")
  end
end

require 'Autoload'

BCDice2.new.run