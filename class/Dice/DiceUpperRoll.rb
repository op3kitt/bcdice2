#--*-coding:utf-8-*--

module DiceUpperRoll

  def checkUpperRoll(arg)
    debug('udice begin string', arg)
    
    return nil unless(/^S?(\d+U\d+(\+\d+U\d+|[\+\-]\d+)*)(\[(\d+)\])?([+-]\d+)*(([<>=]+)(\d+))?(\@(\d+))?/ =~ arg)

    string = $1
    signOfInequality = marshalSignOfInequality($7)
    diff = $8.to_i
    upperTarget1 = $4
    upperTarget2 = $10

    modify = $5 || ''
    upper = getAddRollUpperTarget(upperTarget1, upperTarget2)
    
    if(upper <= 1)
      output = "(#{string}\[#{upper}\]#{modify}) ＞ 無限ロールの条件がまちがっています"
      return output
    end

    dice_a = (string + modify).gsub("-", "+-").split(/[+]/)
    debug('dice_a', dice_a)
    
    diceCommands = []
    bonus = 0

    dice_a.each do |dice_o|
      if(/(\d+)U(\d+)/ =~ dice_o)
        diceCommands.push( [$1.to_i, $2.to_i] )
      else
        bonus += dice_o.to_i
      end
    end

    diceDiff = diff - bonus
    
    diceStringList = []
    totalSuccessCount = 0;
    totalDiceCount = 0
    maxDiceValue = 0;
    totalValue = 0
    cnt1 = 0
    cnt_max = 0
    cnt_re = 0

    diceCommands.each do |diceCount, diceMax|

      upper = diceMax if( @upplerRollThreshold == "Max" )

      total, diceString, cnt1, cnt_max, maxDiceResult, successCount, cnt_re = 
        roll(diceCount, diceMax, (@sortType & 2), upper, signOfInequality, diceDiff)

      diceStringList << diceString

      totalSuccessCount += successCount
      maxDiceValue = maxDiceResult if(maxDiceResult > maxDiceValue)
      totalDiceCount += diceCount
      totalValue += total
    end

    output = diceStringList.join(",")
    
    if(bonus > 0)
      output += "+#{bonus}";
    elsif(bonus < 0)
      output += "#{bonus}";
    end

    maxValue = maxDiceValue + bonus
    totalValue += bonus

    string += "[#{upper}]" + modify;

    if( @isputsMaxDice and (totalDiceCount > 1) )
      output = "#{output} ＞ #{totalValue}"
    end

    if(signOfInequality != "")
      output = "#{output} ＞ 成功数#{totalSuccessCount}"
      string += "#{signOfInequality}#{diff}"
    else
      output += " ＞ #{maxValue}/#{totalValue}(最大/合計)"
    end

    output = "(#{string}) ＞ #{output}"

    if (output.length > AppConfig.SEND_STR_MAX)
      output ="(#{string}) ＞ ... ＞ #{totalValue}"
      if(signOfInequality == "")
        output += " ＞ #{maxValue}/#{totalValue}(最大/合計)"
      end
    end

    return nil if(output == '1')
    
    return output
  end


  def getAddRollUpperTarget(target1, target2)
    if( target1 )
      return target1.to_i
    end
    
    if( target2 )
      return target2.to_i
    end
    
    if(@upplerRollThreshold == "Max")
      return 2
    else 
      return @upplerRollThreshold;
    end
  end
end