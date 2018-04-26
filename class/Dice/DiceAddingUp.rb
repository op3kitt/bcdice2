#--*-coding:utf-8-*--

module DiceAddingUp

  def checkAddRoll(string)
    debug("check add roll")
    
    return "1" unless( /^S?([+\-]?(\d+D\d*(@\d+)?(\/\d+[UR]?)?|\d+)([+\-*](\d+D\d*(@\d+)?(\/\d+[UR]?)?|\d+))*)(([<>=]+)(\?|\-?[\d]+))?$/i =~ string )
    string = $1
    signOfInequality = marshalSignOfInequality($10)
    diffText = $11

    isCheckSuccess = false

    if( signOfInequality )
      isCheckSuccess = true
    end

    total_n = 0
    dice_max = 0
    dice_n = 0
    output =""
    n1 = 0
    n_max = 6
    dice_cnt_total = 0
    double_check = false
    n_max_cnt = 0
    dice_nu = 0

    if( @sameDiceRerollCount != 0 ) # 振り足しありのゲームでダイスが二個以上
      if( @sameDiceRerollType <= 0 )  # 判定のみ振り足し
        debug('判定のみ振り足し')
        double_check = true unless( signOfInequality == '' )
      elsif( @sameDiceRerollType <= 1 ) # ダメージのみ振り足し
        debug('ダメージのみ振り足し')
        double_check = true if( signOfInequality == '' )
      else     # 両方振り足し
        double_check = true
      end
    end
    addUpTextList = string.gsub("-","+-").gsub("*+-","*-").split("+")

    addUpTextList.each_with_index do |addUpText, idx2|
      /(-?)(.*)/ =~ addUpText

      rate = $1=='-' ? -1 : 1
      addUpText = $2

      result_m = 0
      temp_str = ""

      multipleTextList = addUpText.split("*")

      multipleTextList.each_with_index do |multipleText, idx|
        /(-?)(.*)/ =~ multipleText

        rate_m = $1=='-' ? -1 : 1
        multipleText = $2

        case multipleText
          when /(\d+)[Dd](\d*)(@(\d+))?(\/(\d+)([UR]?))?/

            dice_now = 0
            dice_count = $1.to_i
            dice_max = $2 ? $2.to_i : 6
            dice_nu = dice_count
            slashMark = $5
            slashNum = $6
            slashRound = $7

            critical = $4.to_i
            dice_arry = []
            loop_count = 0
            dice_str = ""

            next if( (critical != 0) and (not is2dCritical) )
            return "1" if( dice_max > AppConfig.DICE_MAXNUM )

            begin
              if(dice_max == 66)
                dice_dat = rollD66_Loc(dice_count)
              else
                dice_dat = roll(dice_count, dice_max, @sortType & 1, 0, 0, '', dice_max)
              end
              dice_now_t = dice_dat[0]

              dice_cnt_total += dice_count
              n1 += dice_dat[2]
              n_max_cnt += dice_dat[6]
              if(n_max < dice_dat[4])
                n_max = dice_dat[4]
              end

              if(slashMark && slashNum != 0)
                dice_now_t =
                case slashRound
                  when 'U'
                     (dice_now_t / slashNum.to_f).ceil
                  when 'R'
                     (dice_now_t / slashNum.to_f).round
                  else
                     (dice_now_t / slashNum.to_f).floor
                end
              end

              dice_now += dice_now_t
              dice_n += dice_now_t
              dice_str += "[#{dice_dat[1]}]"

              if( double_check and (dice_count >= 2) )     # 振り足しありでダイスが二個以上
                addDiceArrayByAddDiceCount(dice_dat, n_max, dice_arry, dice_count)
              end

              check2dCritical(critical, dice_now_t, dice_arry, loop_count)

              dice_count = 0

              dice_count = dice_arry.shift if(dice_arry.count > 0)
              loop_count += 1
            end while(dice_count > 0)

            dice_now = changeDiceValueByDiceText(dice_now, dice_str, isCheckSuccess, dice_max)
    
            #next if(@sendMode == 0)

            temp_str += "*" if( idx > 0 )
            operatorText = ''
            operatorText = rate_m > 0 ? '' : '-' unless(output == "")
            temp_str += "#{operatorText}#{dice_now}#{dice_str}"
          when /(\d+)/
            temp_str += "*" if( idx > 0 )
            dice_now = $1.to_i
            if( dice_now < 0)
              temp_str += "(#{dice_now})"
            else
              temp_str += "#{dice_now}"
            end
        end

        if(idx == 0)
          result_m = dice_now * rate_m
        else
          result_m *= dice_now * rate_m
        end
      end

      if(idx2 == 0)
          operatorText = rate > 0 ? '' : '-' unless(output == "")
          output += "#{operatorText}#{temp_str}"
      else
          operatorText = rate > 0 ? '+' : '-' unless(output == "")
          output += "#{operatorText}#{temp_str}"
      end

      total_n += result_m * rate
    end

    if( signOfInequality != "" )
      string += "#{signOfInequality}#{diffText}"
    end
    
    setValue(:diceText, output)


    #ダイス目による補正処理（現状ナイトメアハンターディープ専用）
    addText, revision = getDiceRevision(n_max_cnt, n_max, total_n)
    debug('addText, revision', addText, revision)

    if( @sendMode > 0 )
      if( output =~ /[^\d\[\]]+/ )
        output = "(#{string.upcase}) ＞ #{output} ＞ #{total_n}#{addText}"
      else
        output = "(#{string.upcase}) ＞ #{total_n}#{addText}"
      end
    else
      output = "(#{string.upcase}) ＞ #{total_n}#{addText}"
    end

    setValue('diffText', diffText)

    total_n += revision

    if( signOfInequality != "" )   # 成功度判定処理
      successText = check_suc(total_n, dice_n, signOfInequality, diffText, dice_cnt_total, dice_max, n1, n_max_cnt)
      debug("check_suc successText", successText)
      output += successText
    end

    #ダイスロールによるポイント等の取得処理用（T&T悪意、ナイトメアハンター・ディープ宿命、特命転校生エクストラパワーポイントなど）
    output += getDiceRolledAdditionalText(n1, n_max_cnt, n_max)
    
    return nil if(output == '1')

    return output
  end
  
  def rollD66_Loc(count)
    
    d66List = []
    
    count.times do |i|
      d66List << getD66Value()
    end
    
    total = d66List.inject{|sum, i| sum + i}
    text = d66List.join(',')
    n1Count = d66List.collect{|i| i == 1}.length
    nMaxCount = d66List.collect{|i| i == 66}.length
    
    return [total, text, n1Count, nMaxCount, 0, 0, 0]
  end


  def addDiceArrayByAddDiceCount(dice_dat, dice_max, dice_arry, dice_wk)
    dice_num = dice_dat[1].split(/,/).collect{|s|s.to_i}
    dice_face = []
        
    dice_max.times do |i|
      dice_face.push( 0 )
    end
    
    dice_num.each do |dice_o|
      dice_face[dice_o - 1] += 1
    end

    dice_face.each do |dice_o|
      if( @sameDiceRerollCount == 1) # 全部同じ目じゃないと振り足しなし
        dice_arry.push(dice_o) if( dice_o == dice_wk )
      elsif(@sameDiceRerollCount >= 2)
        dice_arry.push( dice_o ) if( dice_o >= @sameDiceRerollCount )
      end
    end
  end
end