#--*-coding:utf-8-*--

module DiceBotLoader
  extend self

  @dicebot = {}

  def load(name = 'DefaultDiceBot')
    d_name = name.downcase
    if(name2 = @dicebot.find{ |s,| s.casecmp(d_name)==0 })
      return @dicebot[name2[0]]
    elsif(name3 = AppConfig.allGameTypes.find{ |s,| d_name.casecmp(s)==0 })
      bot = DiceBot.const_get(name3).new
      FileList["#{AppConfig.tabledir}/#{bot.gameType}_*.txt"].each{|filename|
        table = TableFileData.new(File.basename(filename, ".txt"), bot.gameType)
        bot.TableDatas.store(table.command, table)
      }
      return @dicebot.store(name3, bot)
    elsif(@dicebot['DefaultDiceBot'])
      return @dicebot['DefaultDiceBot']
    else
      return @dicebot.store('DefaultDiceBot', DiceBot.new)
    end
  end

end