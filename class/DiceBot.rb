#--*-coding:utf-8-*--

class DiceBot < AbstructDiceBot
  VERSION = "2.02.29".freeze
  EMPTY_PREFIXES_PATTERN = (/(^|\s)(S)?()(\s|$)/i).freeze

  include DiceAddingUp, DiceBDice, DiceD66, DiceRnDice, DiceChoiceCommand, DiceUpperRoll

  def self.VERSION
    VERSION
  end

  # 接頭辞（反応するコマンド）の配列を返す
  # @return [Array<String>]
  def self.prefixes
    @prefixes
  end

  # 接頭辞（反応するコマンド）の正規表現を返す
  # @return [Regexp]
  def self.prefixesPattern
    @prefixesPattern
  end

  # 接頭辞（反応するコマンド）を設定する
  # @param [Array<String>] prefixes 接頭辞のパターンの配列
  # @return [self]
  def self.setPrefixes(prefixes)
    @prefixes = prefixes.
      # 最適化が効くように内容の文字列を変更不可にする
      map(&:freeze).
      # 配列全体を変更不可にする
      freeze
    @prefixesPattern = (/(^|\s)(S)?(#{prefixes.join('|')})(\s|$)/i).freeze

    self
  end

  # 接頭辞（反応するコマンド）をクリアする
  # @return [self]
  def self.clearPrefixes
    @prefixes = [].freeze
    @prefixesPattern = EMPTY_PREFIXES_PATTERN

    self
  end

  # 継承された際にダイスボットの接頭辞リストをクリアする
  # @param [DiceBot] subclass DiceBotを継承したクラス
  # @return [void]
  def self.inherited(subclass)
    @inf = true
    subclass.clearPrefixes
  end

  @inf = false

  def debug(*arg)
    $logger.debug(*arg)
  end
  
  @@DEFAULT_SEND_MODE = 2                  # デフォルトの送信形式(0=結果のみ,1=0+式,2=1+ダイス個別)

  clearPrefixes

  def initialize
    @sendMode = @@DEFAULT_SEND_MODE #(0=結果のみ,1=0+式,2=1+ダイス個別)
    @sortType = 0      #ソート設定(1 = 足し算ダイスでソート有, 2 = バラバラロール（Bコマンド）でソート有, 3 = １と２両方ソート有）
    @sameDiceRerollCount = 0     #ゾロ目で振り足し(0=無し, 1=全部同じ目, 2=ダイスのうち2個以上同じ目)
    @sameDiceRerollType = 0   #ゾロ目で振り足しのロール種別(0=判定のみ, 1=ダメージのみ, 2=両方)
    @d66Type = 1        #d66の差し替え(0=D66無し, 1=順番そのまま([5,3]->53), 2=昇順入れ替え([5,3]->35)
    @isputsMaxDice = false      #最大値表示
    @upplerRollThreshold = 0      #上方無限
    @unlimitedRollDiceType = 0    #無限ロールのダイス
    @rerollNumber = 0      #振り足しする条件
    @defaultSuccessTarget = ""      #目標値が空欄の時の目標値
    @rerollLimitCount = 10000    #振り足し回数上限
    @fractionType = "omit"     #端数の処理 ("omit"=切り捨て, "roundUp"=切り上げ, "roundOff"=四捨五入)

    @gameType = 'DiceBot'
    @@bcdice = self
    @dicebot = self

    @TableDatas = {}

    if !prefixs.empty? && self.class.prefixes.empty?
      # 従来の方法（#prefixs）で接頭辞を設定していた場合でも
      # クラス側に接頭辞が設定されるようにする
      $stderr.puts("#{gameType}: #prefixs is deprecated. Please use .setPrefixes.")
      setPrefixes(prefixs)
    end
  end

  def setDiceText(diceText)
    debug("setDiceText diceText", diceText)
    setValue(:diceText, diceText)
  end

  def sendMode
    @sendMode
  end
  def sortType
    @sortType
  end

  def bcdice
    @@bcdice
  end

  def TableDatas
    @TableDatas
  end

  def info
    {
      'name' => gameName,
      'gameType' => gameType,
      'prefixs' => self.class.prefixes,
      'info' => getHelpMessage,
    }
  end


  def getHelpMessage
    ''
  end

  # 接頭辞（反応するコマンド）の配列を返す
  # @return [Array<String>]
  def prefixes
    self.class.prefixes
  end

  # @deprecated 代わりに {#prefixes} を使ってください
  alias prefixs prefixes

  def gameType
    @gameType
  end

  def gameName
    @gameType
  end

  def execute(command)
    t = Thread.new(command) {|command|
      setValue :result, dice_command(command, gameType)
    }
    t.join
    return t[:result]
  end

  def roll(dice_cnt = 1, dice_max = 6, dice_sort = 0, dice_add = 0 , dice_ul = '' , dice_diff = 0 , dice_re = nil)

    dice_cnt = dice_cnt.to_i
    dice_max = dice_max.to_i
    total = 0
    dice_str = ""
    numberSpot1 = 0
    cnt_max = 0
    n_max = 0
    n_max_p = 0
    cnt_suc = 0
    rerollCount = 0
    dice_result = []

    #ダイスの上限設定チェック
    unless( (dice_cnt <= AppConfig.DICE_MAXCNT) and (dice_max <= AppConfig.DICE_MAXNUM) )
      return 0, "", 0, 0, 0, 0, 0
    end

    dice_cnt.times do |i|
      i += 1
      dice_now = 0
      dice_n = 0
      dice_st_n = ""
      round = 0
      
      begin
        
        dice_n = rand(dice_max).to_i + 1
        
        dice_now += dice_n
        
        debug('@diceBot.sendMode', @sendMode)
        if( @sendMode >= 2 )
          dice_st_n += "," unless( dice_st_n.empty? )
          dice_st_n += "#{dice_n}"
        end
        round += 1
        
      end while( (dice_add > 1) and (dice_n >= dice_add) )
      
      total +=  dice_now
      
      if( dice_ul != '' )
        suc = check_hit(dice_now, dice_ul, dice_diff)
        cnt_suc += suc
      end
      
      if( dice_re )
        rerollCount += 1 if(dice_now >= dice_re)
      end
      
      if( (@sendMode >= 2) and (round >= 2) )
        dice_result.push( "#{dice_now}[#{dice_st_n}]" )
      else
        dice_result.push( dice_now )
      end
        
      numberSpot1 += 1 if( dice_now == 1 )
      cnt_max += 1 if( dice_now == dice_max )
      if( dice_now > n_max_p)
        n_max_p = dice_now
        n_max = 1
      elsif(dice_now == n_max_p)
        n_max += 1
      end
    end

    if( dice_sort != 0 )
      dice_str = dice_result.sort_by{|a| dice_num(a)}.join(",")
    else
      dice_str = dice_result.join(",")
    end
    
    return total, dice_str, numberSpot1, cnt_max, n_max_p, cnt_suc, rerollCount
  end

  def isReRollAgain(dice_cnt, round)
    debug("isReRollAgain dice_cnt, round", dice_cnt, round)
    ( (dice_cnt > 0) && ((round < @rerollLimitCount) || (@rerollLimitCount == 0)) )
  end

  def dice_num(dice_str)
    dice_str = dice_str.to_s
    return dice_str.sub(/\[[\d,]+\]/, '').to_i
  end

  def check_hit(dice_now, signOfInequality, diff)

    if( diff.is_a?(String) )
      unless( /\d/ =~ diff )
        return 0
      end
      diff = diff.to_i
    end

    begin
      if(dice_now.send(signOfInequality, diff.to_i))
        return 1
      else
        return 0
      end
    rescue
      return 0
    end
  end



  def dice_command(string, nick_e)
    if(/:/ =~ nick_e)
      nick_e = nick_e.split(":").first
    end
    setValue(:nick_e, nick_e + " ")
p string
    #string = @@bcdice.getOriginalMessage if( isGetOriginalMessage )
    string = string.split(/\s/, 2).first
    string = parren_killer(string)
    setValue(:originalMessage, string)
    string = string.upcase

    string = getOriginalMessage if( isGetOriginalMessage )

    $logger.debug('dice_command Begin string', string)
    secret_flg = false
    
    unless( /^((S)?.*)/i =~ string )
      $logger.debug('not match in prefixs')
      return '1', secret_flg 
    end
    secretMarker = $2
    command = $1

    command = removeDiceCommandMessage(command)
    $logger.debug("dicebot after command", command)
    
    $logger.debug('match')
    #begin
      output_msg, secret_flg = rollDiceCommandCatched(command)
    #rescue => e
    #  $logger.debug("an error occurd in dice_command", e)
    #  output_msg = "1"
    #end
    output_msg = '1' if( output_msg.nil? or output_msg.empty?)
    if (output_msg != '1')
      output_msg = "#{nick_e} : #{output_msg}" 
      return output_msg, secret_flg
    end

    if( output_msg == '1')
      output_msg = rollD66(command)
      output_msg = '1' if( output_msg.nil? )
      output_msg = "#{nick_e} : #{output_msg}" if(output_msg != '1')
    end

    if( output_msg == '1')
      output_msg, = checkAddRoll(command)
      output_msg = '1' if( output_msg.nil? )
      output_msg = "#{nick_e} : #{output_msg}" if(output_msg != '1')
    end
    
    if( output_msg == '1')
      output_msg = checkBDice(command)
      output_msg = '1' if( output_msg.nil? )
      output_msg = "#{nick_e} : #{output_msg}" if(output_msg != '1')
    end

    if( output_msg.to_s == '1')
      output_msg = checkRnDice(command)
      output_msg = '1' if( output_msg.nil? )
      output_msg = "#{output_msg}" if(output_msg != '1')
    end
    
    if( output_msg == '1')
      output_msg = checkUpperRoll(command)
      output_msg = '1' if( output_msg.nil? )
      output_msg = "#{nick_e} : #{output_msg}" if(output_msg != '1')
    end

    if( output_msg == '1')
      output_msg = checkChoiceCommand(command)
      output_msg = '1' if( output_msg.nil? )
      output_msg = "#{nick_e} : #{output_msg}" if(output_msg != '1')
    end

    if( output_msg == '1')
      output_msg, secret_flg = getTableDataResult(command) 
      output_msg = '1' if( output_msg.nil? )
      if(output_msg != '1')
        output_msg = "#{nick_e} :#{output_msg}" 
        return output_msg, secret_flg
      end
    end
    
    if( secretMarker )   # 隠しロール
      secret_flg = true if(output_msg != '1')
    end
    
    output_msg = "" if(output_msg == "1")
    return output_msg, secret_flg
  end
  
  def check_suc(*check_param)
    total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max = *check_param
    
    debug('check params : total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max',
          total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)
    
    return "" unless(/([+-]?[\d]+)$/ =~ total_n.to_s)
    
    total_n = $1.to_i
    diff = diff.to_i
    
    check_paramNew = [total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max]
    
    text = getSuccessText(*check_paramNew)
    text ||= ""
    
    if( text.empty? )
      if( signOfInequality != "" )
        debug('どれでもないけど判定するとき')
        return check_nDx(*check_param)
      end
    end
    
    return text
  end

  def getSuccessText(*check_param)
    debug('getSuccessText begin')

    dice_cnt = check_param[4]
    dice_max = check_param[5]

    debug("dice_max, dice_cnt", dice_max, dice_cnt)
    
    if((dice_max == 100) and (dice_cnt == 1))
      debug('1D100判定')
      return check_1D100(*check_param)
    end
    
    if((dice_max == 20) and (dice_cnt == 1))
      debug('1d20判定')
      return check_1D20(*check_param)
    end
    
    if(dice_max == 10)
      debug('d10ベース判定')
      return check_nD10(*check_param)
    end
    
    if(dice_max == 6)
      if(dice_cnt == 2)
        debug('2d6判定')
        result = check_2D6(*check_param)
        return result unless( result.empty? )
      end
      
      debug('xD6判定')
      return check_nD6(*check_param)
    end
    
    return ""
  end

  def check_2D6(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)  # ゲーム別成功度判定(2D6)
    ''
  end
  
  def check_nD6(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max) # ゲーム別成功度判定(nD6)
    ''
  end
  
  def check_nD10(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)# ゲーム別成功度判定(nD10)
    ''
  end
  
  def check_1D100(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)    # ゲーム別成功度判定(1d100)
    ''
  end

  def check_1D20(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)     # ゲーム別成功度判定(1d20)
    ''
  end

  def check_nDx(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)  # ゲーム別成功度判定(ダイスごちゃ混ぜ系)
    debug('check_nDx begin diff', diff)
    success = check_hit(total_n, signOfInequality, diff)
    debug('check_nDx success', success)
    
    if(success >= 1)
      return " ＞ 成功"
    end
    
    return " ＞ 失敗"
  end

  def parren_killer(string)
    debug("parren_killer input", string)
    
    while( /^(.*?)\[(\d+[Dd]\d+)\](.*)/ =~ string )
      str_before = ""
      str_after = ""
      dice_cmd = $2
      str_before = $1 if($1)
      str_after = $3 if($3)
      rolled, = rollDiceAddingUp(dice_cmd)
      string = "#{str_before}#{rolled}#{str_after}"
    end
    
    string = changeRangeTextToNumberText(string)
    
    while(/^(.*?)(\([\d\/*+-]+?\))(.*)/ =~ string)
      debug("while string", string)
      
      str_a = $3
      str_a ||= ""
      
      str_b = $1
      str_b ||= ""
      debug("str_b", str_b)
      
      par_i = $2
      
      debug("par_i", par_i)
      par_o = paren_k(par_i)
      debug("par_o", par_o)
      
      if(par_o != 0)
        if(par_o < 0)
          if(/(.+?)(\+)$/ =~ str_b)
            str_b = $1
          elsif(/(.+?)(-)$/ =~ str_b)
            str_b = "#{$1}+"
            par_o = par_o * -1
          end
        end
        string = "#{str_b}#{par_o}#{str_a}"
      else
        if(/^([DBRUdbru][\d]+)(.*)/ =~ str_a)
          str_a = $2
        end
        string = "#{str_b}0#{str_a}"
      end
    end
    
    debug("diceBot.changeText(string) begin", string)
    string = changeText(string)
    debug("diceBot.changeText(string) end", string)
    
    #string = string.gsub(/([\d]+[dD])([^\d]|$)/) {"#{$1}6#{$2}"}
    
    debug("parren_killer output", string)
    
    return string
  end
  

  def changeRangeTextToNumberText(string)
    debug('[st...ed] before string', string)
    
    while(/^(.*?)\[(\d+)[.]{3}(\d+)\](.*)/ =~ string )
      beforeText = $1
      beforeText ||= ""
      
      rangeBegin = $2.to_i
      rangeEnd = $3.to_i
      
      afterText = $4
      afterText ||= ""
      
      if(rangeBegin < rangeEnd)
        range = (rangeEnd - rangeBegin + 1)
        debug('range', range)
        
        rolledNumber, = roll(1, range)
        resultNumber = rangeBegin - 1 + rolledNumber
        string = "#{beforeText}#{resultNumber}#{afterText}"
      end
    end
    
    debug('[st...ed] after string', string)
    
    return string
  end
  
  def paren_k(string)
    result = 0
    
    return result unless (/([\d\/*+-]+)/ =~ string)
    
    string = $1
    
    #ex: --X => +X
    string.gsub!(/\-\-/, '+')
    
    debug("paren_k string", string )
    list = split_plus_minus(string)
    debug("paren_k list", list)
    
    result = 0
    
    list.each do |text|
      result += paren_k_loop(text)
    end
    
    return result
  end
  

  def split_plus_minus(string)
    
    list = string.scan(/[\+\-]?[^\+\-]+/)
    
    debug('split_plus_minus list', list)
    
    result = []
    
    list.length.times do |i|
      unless result.empty?
        if /(\*|\/)$/ === result.last
          result.last << list[i]
          next
        end
      end
      
      result << list[i] 
    end
    
    debug('split_plus_minus result', result)
    return result
  end
  
  def paren_k_loop(string)
    debug("paren_k_plus Begin", string)
    
    result = paren_k_calculate_multiple_divide_text(string)
    debug("paren_k_plus End result", result)
    
    return result
  end
  
  def paren_k_calculate_multiple_divide_text(string)
    multi = 1
    divide = 1
    
    #ex: X*Y(...) => X(...) & multi(=*Y)
    string, multi = paren_k_multi(string)
    
    #ex: X/Y(...) => X(...) & divide(=/Y)
    string, divide = paren_k_devide(string)
    
    # 掛け算・割り算
    result = calculate_multiple_divide(string, multi, divide)
    return result
  end
  

  #ex: X*Y(...) => X(...) & multi(=*Y)
  def paren_k_multi(string)
    debug("paren_k_multi Begin string", string)
    multi = 1
    
    while(/(.*?)(\*[-\d]+)(.*)/ =~ string)
      before = $1
      after = $3
      calculate_text = $2
      string = "#{before}#{after}"
      if(/([-\d]+)/ =~ calculate_text)
        multi = multi * $1.to_i
      end
    end
    
    debug("paren_k_multi End multi", multi)
    debug("paren_k_multi End", string)
    
    return string, multi
  end
  
  
  #ex: X/Y(...) => X(...) & divide(=/Y)
  def paren_k_devide(string)
    divide = 1
    
    while(/(.*?)(\/[-\d]+)(.*)/ =~ string)
      before = $1
      after = $3
      calculate_text = $2
      string = "#{before}#{after}"
      if(/([-\d]+)/ =~ calculate_text)
        divide = divide * $1.to_i
      end
    end
    
    return string, divide
  end
  
  def calculate_multiple_divide(string, multi, divide)
    
    result = 0
    
    return result if( divide == 0 )
    return result unless(/([-\d]+)/ =~ string)
    
    work = ($1.to_i) * multi
    
    case @fractionType
    when "roundUp"  # 端数切り上げ
      result = (work / divide).ceil
    when "roundOff" # 四捨五入
      result = (work / divide).round
    else #切り捨て
      result = (work / divide).truncate
    end
    
    return result
  end

  def getGrichText(numberSpot1, dice_cnt_total, suc)
    ''
  end

  def marshalSignOfInequality(text)
    #不等号の整形
    /((=)([<>]?)|([<>])(=?)|(<>))/ =~ text
    return [$3,$4,$2,$5,$6].join("")
  end
  
  

  def removeDiceCommandMessage(command)
    # "2d6 Atack" のAtackのようなメッセージ部分をここで除去
    command.sub(/[\s　].+/, '')
  end


  def rollDiceCommandCatched(string)
    
    debug('dice_command Begin string', string)
    secret_flg = false

    unless self.class.prefixesPattern =~ string
      debug('not match in prefixes')
      return '1', secret_flg 
    end

    secretMarker = $2
    command = $3

    output_msg, secret_flg = rollDiceCommand(command)
    secret_flg ||= false

    if( secretMarker )   # 隠しロール
      secret_flg = true if(output_msg != '1')
    end

    return output_msg, secret_flg
  end

  def rollDiceCommand(command)
    nil
  end


  def getTableDataResult(command)
    if(@TableDatas[command])
      table = @TableDatas[command]
      if(/(\d+)[Dd](\d+)/ =~ table.dice)
        result, diceinfo = roll($1, $2)
        diceinfo = "#{result}[#{diceinfo}]"
      elsif(/D66(N|S)?/ =~ table.dice)
        case($1)
        when 'N'
          result = getD66(false).to_s
          diceinfo = result+"["+result.split("").join(",")+"]"
        when 'S'
          result = getD66(true).to_s
          diceinfo = result+"["+result.split("").join(",")+"]"
        else
          result = getD66(@d66Type>1).to_s
          diceinfo = result+"["+result.split("").join(",")+"]"
        end
      else
        result = getD66(@d66Type>1).to_s
        diceinfo = result+"["+result.split("").join(",")+"]"
      end

      
        return "#{table.title}(#{diceinfo}) ＞ #{rollTableMessageDiceText(get_table_by_key(result,table.table)[0])}", false
    end

    return '1', false
  end

  def rollTableMessageDiceText(text)
    message = text.gsub(/(\d+)D(\d+)/) do
      diceCount = $1
      diceMax = $2
      value, = roll(diceCount, diceMax)
      "#{$1}D#{$2}(=>#{value})"
    end
    
    return message
  end

  def rand(max)
    Thread.current[:RandResults] = [] if(Thread.current[:RandResults] == nil)

    result = Kernel.rand(max)

    Thread.current[:RandResults] << [result + 1, max]
    return result
  end

  # D66 ロール用（スワップ、たとえば出目が【６，４】なら「６４」ではなく「４６」とする
  def get_table_by_d66_swap(table)
    number = getD66(true)
    return get_table_by_number(number, table), number
  end
  
  # D66 ロール用
  def get_table_by_d66(table)
    number = getD66(false).to_s
    result, = get_table_by_index(number[0].to_i * 6 + number[1].to_i - 7, table)
    return result, number
  end


  def get_table_by_2d6(table)
    get_table_by_nDx(table, 2, 6)
  end
  
  def get_table_by_1d6(table)
    get_table_by_nDx(table, 1, 6)
  end
  
  def get_table_by_1d3(table)
    get_table_by_nDx([table[0], table[0], table[1], table[1], table[2], table[2]], 1, 6)
  end

  def get_table_by_nD6(table, count)
    get_table_by_nDx(table, count, 6)
  end
  
  def get_table_by_nDx(table, count, diceType)
    num, = roll(count, diceType)
    
    result, = get_table_by_index(num - count, table)
    return result, num
  end
  
  def get_table_by_number(number, table, default = '1')
    table.each do |item|
      num = item[0]
      number = number.first if(number.is_a?(Array))
      if (num >= number)
        return getTableValue( item[1] )
      end
    end
    return default
  end


  def get_table_by_key(number, table, default = '1')
    text = table.find{|item| item.first == number.to_i}
    text = text[1] if(text.is_a?(Array))
    return default, 0  if( text.nil? )
    return getTableValue(text), number
  end
  
  def get_table_by_index(number, table, default = '1')
    text = getTableValue( table[number] )
    return default, 0  if( text.nil? )
    return text, number
  end

  def getTableValue(data)
    if( data.kind_of?( Proc ) )
      return data.call()
    end
    return data
  end
  
  #ダイスロールによるポイント等の取得処理用（T&T悪意、ナイトメアハンター・ディープ宿命、特命転校生エクストラパワーポイントなど）
  def getDiceRolledAdditionalText(n1, n_max, dice_max)
    ''
  end
  
  #ダイス目による補正処理（現状ナイトメアハンターディープ専用）
  def getDiceRevision(n_max, dice_max, total_n)
    return '', 0
  end
  
  #ダイス目文字列からダイス値を変更する場合の処理（現状クトゥルフ・テック専用）
  def changeDiceValueByDiceText(dice_now, dice_str, isCheckSuccess, dice_max)
    dice_now
  end
  
  #SW専用
  def setRatingTable(nick_e, tnick, channel_to_list)
    '1'
  end

  def changeText(string)
    debug("DiceBot.parren_killer_add called")
    string
  end


  def getDiceList
    getDiceListFromDiceText(getValue(:diceText))
  end
  
  def getDiceListFromDiceText(diceText)
    debug("getDiceList diceText", diceText)
    
    diceList = []
    
    if( /\[([\d,]+)\]/ =~ diceText )
      diceText = $1
    end
    
    return diceList unless( /([\d,]+)/ =~ diceText )
    
    diceString = $1
    diceList = diceString.split(/,/).collect{|i| i.to_i}
    
    debug("diceList", diceList)
    
    return diceList
  end

  def dice_command_xRn(string, nick_e)
    ''
  end

  def rerollNumber
    @rerollNumber
  end

  def isGetOriginalMessage
    false
  end

  def getOriginalMessage
    getValue(:originalMessage)
  end

  def analyzeDiceCommandResultMethod(command)
    
    # get～DiceCommandResultという名前のメソッドを集めて実行、
    # 結果がnil以外の場合それを返して終了。
    methodList = public_methods(false).select do |method|
      /^get.+DiceCommandResult$/ === method.to_s
    end
    
    methodList.each do |method|
      result = send(method, command)
      return result unless result.nil?
    end
    
    return nil
  end

  def defaultSuccessTarget
    @defaultSuccessTarget
  end

  def check2dCritical(*arg)
  end

  def setValue(key, value)
    Thread.current[key] = value
  end
  def getValue(key)
    Thread.current[key]
  end

end
