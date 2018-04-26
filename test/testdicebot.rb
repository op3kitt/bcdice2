#--*-coding:utf-8-*--

require 'test-unit'
require_relative '../AutoLoad.rb'
require_relative '../module/DiceBotTestData.rb'

class TestDiceBot < Test::Unit::TestCase
  class << self
    def startup
      $logger = Logger.new(AppConfig.log.path)
      $logger.level=(AppConfig.log.level)
    end

    def shutdown
    end
  end

  def setup
  end

  def cleanup
  end

  def teardown
  end

end

# テスト用のランダマイザ部の再定義
class DiceBot
  
  def setRandomValues(rands)
    rands = [] unless(rands.is_a?(Array))
    $rands = rands
  end

  alias :__rand :rand
  def rand(targetMax)
    nextRand = $rands.shift

    raise "nextRand is nil" if( nextRand.nil? )

    value, max = nextRand
    value = value.to_i
    max = max.to_i
    
    raise "nextRand is [ #{value} / #{max} ] but requested [ #{targetMax} ] dice."  if( max != targetMax )
    
    return (value - 1)
  end

  def remain_rand
    $rands
  end
end

module DiceBotTest
  extend self

  def addTest(testDataPath, dataIndex = nil, logLevel = nil)
    unless(dataIndex==nil)
      dataIndex = dataIndex.split(':').map{|item|item.split(',').map{|item2|item2.to_i} if(item)}
    else
      dataIndex = []
    end
    if (testDataPath == 'all')
      testDataPath = AppConfig.allGameTypes
    else
      testDataPath = testDataPath.split(',')
    end
    testDataPath.zip(dataIndex).each do |name, index|
      testDataSet = []
      filename = "test/data/#{name}.txt"
      next unless(File.exist?(filename))
      
      source =
        if RUBY_VERSION < '1.9'
          File.read(filename)
        else
          File.read(filename, :encoding => 'UTF-8')
        end
      dataSetSources = source.
        gsub("\r\n", "\n").
        tr("\r", "\n").
        split("============================\n").
        map(&:chomp)
        
      dataSet =
        if RUBY_VERSION < '1.9'
          dataSetSources.each_with_index.map do |dataSetSource, i|
            DiceBotTestData.parse(dataSetSource, name, i + 1)
          end
        else
          dataSetSources.map.with_index(1) do |dataSetSource, i|
            DiceBotTestData.parse(dataSetSource, name, i)
          end
        end
      case logLevel
        when 'DEBUG'
        AppConfig.log.level = Logger::DEBUG
        AppConfig.log.path  = STDOUT
      end
      testDataSet =
        if index.nil?
          dataSet
        else
          dataSet.select { |data| index.include?(data.index) }
        end
      testDataSet.each do |data|
        testname = "#{name}_#{File.basename(filename, '.txt')}_#{data.index}"
        TestDiceBot.test testname do
          randList = data.rands
          bot = DiceBotLoader.load(data.gameType)
          bot.setRandomValues(randList)
          output, secret = bot.execute(data.input[0])
          output = DiceBotTestData.conv_remain(bot.remain_rand, output)

          assert_equal(data.output, output + (secret ? '###secret dice###' : ''))
        end
      end
    end
  end

end

ENV['DICE'] = 'all' unless(ENV['DICE'])

DiceBotTest.addTest(ENV['DICE'],ENV['INDEX'], ENV['LOG'])