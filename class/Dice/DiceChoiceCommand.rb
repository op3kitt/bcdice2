#--*-coding:utf-8-*--

module DiceChoiceCommand

  def checkChoiceCommand(arg)
    debug("check choice command", arg)
    
    return nil unless(/^(S?choice\[([^,]+(,[^,]+)+)\])/i === arg)
    
    targets = $2.split(",")
    index = rand(targets.length)
    target = targets[index]
    output = "(#{$1}) ＞ #{target}"
    
    return output
  end
end