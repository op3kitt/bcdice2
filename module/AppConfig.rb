#--*-coding:utf-8-*--

require 'hashie'

module AppConfig
  extend self

  def load(file)
    # default
    config = Hashie::Mash.new
    config.log = {
      level: Logger::ERROR,
      path: 'log/log.txt'
    }
    config.cachedir = "cache"
    config.tabledir = "extratables"
    config.allGameTypes = FileList['diceBot/*.rb']
      .map{|botfile|File.basename(botfile, ".rb")}
      .exclude(/^(_Template)$/)
      .to_a
    config.DICE_MAXNUM = 1000
    config.DICE_MAXCNT = 200
    config.SEND_STR_MAX = 500
    config.Interface = "Server"
    config.TCP = {
      port: 15535,
    }
    config.Http = {
      port: 8080
    }
    config.WebSocket = {
      host: "0.0.0.0",
      port: 8888
    }

    # overwirte
    instance_eval(file)

    config.each do |key, value|
      attr_accessor key
      send("#{key}=", value)
    end
    config.allGameTypes.map(&:freeze)
  end

  AppConfig.load(File.read(File.expand_path('config/.config.rb')))

end