#--*-coding:utf-8-*--

class API_v1
  VERSION = "0.5.0".freeze

  class << self
    def version()
      return {
        :version => VERSION,
        :bcdice2 => DiceBot.VERSION
      }
    end

    def systems()
      return {
        :systems => AppConfig.allGameTypes
      }
    end

    def systeminfo(q)
      dicebot = nil
      dicebot = DiceBotLoader.load(q["system"]) if(q["system"])
      raise "unsupported dicebot" unless(dicebot && dicebot.gameType != "DiceBot")
      return {
        :ok => true,
        :systeminfo => dicebot.info
      }
    end

    def diceroll(q)
      name = "DefaultDiceBot"
      name = q["system"] if(q["system"])
      dicebot = DiceBotLoader.load(name)
      t = Thread.new(dicebot, q["command"]) {|dicebot, command|
        Thread.current[:result] = dicebot.dice_command(command, dicebot.gameType)
      }
      t.join
      raise "unsupported command" if(t[:result][0] == "")
      dices = nil
      dices = t[:RandResults].map{|item| {:faces => item[1], :value => item[0]}} unless(t[:RandResults] == nil)
      return {
        :ok => true,
        :result => t[:result][0],
        :secret => t[:result][1],
        :dices => dices
      }
    end
  end

end