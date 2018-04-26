#--*-coding:utf-8-*--

class AbstructDiceBot

  def initialize(*arg)
    $logger.warn('Abstruct Class Method Called', Kernel.caller.first)
  end

  def roll(*arg)
    raise NotImplementedError
  end
end