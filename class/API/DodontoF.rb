#--*-coding:utf-8-*--

class API_DodontoF
  VERSION = "0.5.0".freeze

  class << self
    def getDiceBotInfos()
      result = []
      AppConfig.allGameTypes.each do |name|
        begin
          bot = DiceBotLoader.load(name)
          result.push(bot.info)
        rescue => e
          $logger.debug(e)
        end
      end
      result.push({
        "name" => "BaseDiceBot",
        "gameType" => "BaseDiceBot",
        "prefixs" => ["\\d+D\\d*","\\d+B\\d+","\\d+R\\d+","\\d+U\\d+","C\\(","\\([\\d\\+\\-\\*\\/]+\\)","\\d+U\\d+","(\\d+|\\[\\d+\\.\\.\\.\\d+\\])D(\\d+|\\[\\d+\\.\\.\\.\\d+\\])","\\d+[\\+\\-\\*\\/]","D66","make","choice\\["],
        "info" => "【ダイスボット】チャットにダイス用の文字を入力するとダイスロールが可能\n入力例）２ｄ６＋１　攻撃！\n出力例）2d6+1　攻撃！\n　　　　  diceBot: (2d6) → 7\n上記のようにダイス文字の後ろに空白を入れて発言する事も可能。\n以下、使用例\n　3D6+1>=9 ：3d6+1で目標値9以上かの判定\n　1D100<=50 ：D100で50％目標の下方ロールの例\n　3U6[5] ：3d6のダイス目が5以上の場合に振り足しして合計する(上方無限)\n　3B6 ：3d6のダイス目をバラバラのまま出力する（合計しない）\n　10B6>=4 ：10d6を振り4以上のダイス目の個数を数える\n　(8/2)D(4+6)<=(5*3)：個数・ダイス・達成値には四則演算も使用可能\n　C(10-4*3/2+2)：C(計算式）で計算だけの実行も可能\n　choice[a,b,c]：列挙した要素から一つを選択表示。ランダム攻撃対象決定などに\n　S3d6 ： 各コマンドの先頭に「S」を付けると他人結果の見えないシークレットロール\n　3d6/2 ： ダイス出目を割り算（切り捨て）。切り上げは /2U、四捨五入は /2R。\n　D66 ： D66ダイス。順序はゲームに依存。D66N：そのまま、D66S：昇順。\n"
      })
      return result
    end

    def sendDiceBotChatMessage(q)
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