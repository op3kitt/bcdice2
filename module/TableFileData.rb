#--*-coding:utf-8-*--

class TableFileData
  def fileName
    @fileName
  end
  
  def title
    @title
  end
  
  def command
    @command
  end
  
  def gameType
    @gameType
  end
  
  def dice
    @dice
  end
  
  def table
    @table
  end
  
  def initialize(filename, gameType)
    @filename = filename
    @gameType = gameType
    lines = File.read("#{AppConfig.tabledir}/#{filename}.txt").toutf8.lines.map(&:chomp)
    header = lines.shift.split(":")
    @table = []
    @command = $2 if(/^(.+)_(.+)$/ =~ filename)
    lines.each do |l|
      l = l.toutf8.chomp
      if(/^[\s　]*([^:：]+)[\s　]*[:：][\s　]*(.+)/ =~ l)
        @table.push [$1.to_i, $2.gsub(/\\n/, "\n")]
      end
    end
    @title = header[1]
    @dice = header[0]
  end

end