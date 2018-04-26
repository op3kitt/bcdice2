#--*-coding:utf-8-*--

module DiceD66

  def getD66(isSwap)
    output = 0
    
    dice_a, = roll(1, 6)
    dice_b, = roll(1, 6)
    $logger.debug("dice_a", dice_a)
    $logger.debug("dice_b", dice_b)
    
    if( isSwap and (dice_a > dice_b))
      # 大小でスワップするタイプ
      output = dice_a + dice_b * 10
    else
      # 出目そのまま
      output = dice_a * 10 + dice_b
    end
    
    $logger.debug("output", output)
    
    return output
  end

  def d66(mode)
    mode ||= @d66Type
    isSwap = ( mode > 1)
    result, = getD66(isSwap)
    return result
  end

  def rollD66(string)
    return nil if(@d66Type == 0)
    return nil unless( /^S?D66(N|S)?/i === string )
    
    isSwap =
    case($1)
      when "N"
        false
      when "S"
        true
      else
        @d66Type > 1
    end
    debug("match D66 roll")
    result, = getD66(isSwap)
    
    return "(D66#{$1}) ＞ #{result}"
  end

end