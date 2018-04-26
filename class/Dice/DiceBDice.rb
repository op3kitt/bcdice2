#--*-coding:utf-8-*--

module DiceBDice

  def checkBDice(string)
    return '1' unless(/^S?(\d+B\d+(\+\d+B\d+)*)(([<>=]+)(\d+))?/ =~ string)

    suc = 0
    signOfInequality = ""
    diff = 0
    output = ""

    debug("check barabara roll")
    
    string = $1
    if($3)
      signOfInequality = marshalSignOfInequality($4)
      diff = $5.to_i
    elsif(/([<>=]+)(\d+)/ =~ @defaultSuccessTarget)
      signOfInequality = marshalSignOfInequality($1)
      diff = $2.to_i
    end
    
    dice_a = string.split(/\+/)
    dice_cnt_total = 0
    numberSpot1 = 0

    dice_a.each do |dice_o|
      dice_cnt, dice_max = dice_o.split(/[bB]/).map(&:to_i)
      
      dice_dat = roll(dice_cnt, dice_max, @sortType & 2, 0, signOfInequality, diff)
      
      suc += dice_dat[5]
      output += "," if(output != "")
      output += dice_dat[1]
      numberSpot1 += dice_dat[2]
      dice_cnt_total += dice_cnt
    end
    
    if(signOfInequality != "")
      string += "#{signOfInequality}#{diff}"
      output = "#{output} ＞ 成功数#{suc}"
      output += getGrichText(numberSpot1, dice_cnt_total, suc)
    end
    output = "(#{string}) ＞ #{output}"
    
    return output
  end

end