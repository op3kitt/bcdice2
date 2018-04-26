#--*-coding:utf-8-*--

module DiceRnDice

  def checkRnDice(arg)
    debug('check xRn roll arg', arg)
    return nil unless(/S?[\d]+R[\d]+/i === arg)

    output = dice_command_xRn(arg, getValue(:nick_e))
    return nil if( output.nil? or output == '1' )
    return output unless(output == "")

    return nil unless( /^S?(\d+R\d+)(\[(\d+)\])?(([<>=]+)(\d+))?(\@(\d+))?/ =~ arg)
    
      string = $1
      rerollNumber_1 = $3
      rerollNumber_2 = $8
      signOfInequality = $5
      diff = $6

      if(signOfInequality)
        diff = diff.to_i
        signOfInequality = marshalSignOfInequality(signOfInequality)
      elsif(/([<>=]+)(\d+)/ =~ @defaultSuccessTarget)
        diff = $2.to_i
        signOfInequality = marshalSignOfInequality($1)
      end



      rerollNumber = getRerollNumber(rerollNumber_1, rerollNumber_2, diff)

    begin

      numberSpot1Total = 0
      dice_cnt_total =0
      round = 0
      successCount = 0

      dice_cnt, dice_max = string.split(/[rR]/).map(&:to_i)

      begin
        total, dice_str, numberSpot1, cnt_max, n_max, success, rerollCount =
          roll(dice_cnt, dice_max, (@sortType & 2), 0, signOfInequality, diff, rerollNumber)
        debug('bcdice.roll : total, dice_str, numberSpot1, cnt_max, n_max, success, rerollCount',
                        total, dice_str, numberSpot1, cnt_max, n_max, success, rerollCount, signOfInequality)
        
        successCount += success
        numberSpot1Total += numberSpot1 unless(round > 0)
        output += " + " if(round > 0)
        output += dice_str
        dice_cnt_total += dice_cnt
        dice_cnt = rerollCount

        round += 1
      end while(isReRollAgain(dice_cnt, round))

      output = "#{output} ＞ 成功数#{successCount}"
      string += "[#{rerollNumber}]#{signOfInequality}#{diff}"
      output += getGrichText(numberSpot1Total, dice_cnt_total, successCount)

      output = "(#{string}) ＞ #{output}"

      if( output.length > AppConfig.SEND_STR_MAX )    # 長すぎたときの救済
        output = "(#{string}) ＞ ... ＞ 回転数#{round} ＞ 成功数#{successCount}"
      end
    rescue => e
      output = "#{string} ＞ " + e.to_s
    end
    return nil if( output.nil? or output == '1' )
    
    debug('xRn output', output)
    
    return "#{getValue(:nick_e)}: "+ output
  end

  def getRerollNumber(rerollNumber_1, rerollNumber_2, diff)
    $logger.debug("rndice", [rerollNumber_1,rerollNumber_2,diff])
    result =
    if( rerollNumber_1 )
      rerollNumber_1.to_i
    elsif( rerollNumber_2 )
      rerollNumber_2.to_i
    elsif( @rerollNumber != 0 )
      @rerollNumber
    elsif( not diff.nil?)
      diff
    else
      raise "条件が間違っています。2R6>=5 あるいは 2R6[5] のように振り足し目標値を指定してください。"
    end
    if(result <= 1)
      raise "条件が間違っています。振り足し目標値は2以上を指定してください。"
    end
    return result
  end

end