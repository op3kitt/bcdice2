#--*-coding:utf-8-*--

module HttpInterface
  def open
    srv = WEBrick::HTTPServer.new({
      :Port => AppConfig.Http.port,
      :DocumentRoot => "c:\\ruby\\bcdice2\\class\\API"
    })
    srv.mount_proc('/') {|request, response|
      case(request.path)
      when "/"
        response.content_type = "text/plain;charset=UTF-8"
        response.body = "Hello. This is BCDice-API."
      else
        notFound(response)
      end
    }
    srv.mount_proc('/v1') {|request, response|
      begin
        case(request.path)
        when "/v1/version"
          response.content_type = "application/json;charset=UTF-8"
          response.body = JSON::dump(API_v1::version)
        when "/v1/systems"
          response.content_type = "application/json;charset=UTF-8"
          response.body = JSON::dump(API_v1::systems)
        when /\/v1\/systeminfo/
          response.content_type = "application/json;charset=UTF-8"
          response.body = JSON::dump(API_v1::systeminfo(request.query))
        when /\/v1\/diceroll/
          response.content_type = "application/json;charset=UTF-8"
          response.body = JSON::dump(API_v1::diceroll(request.query))
        else
          notFound(response)
        end
      rescue => e
        notFound(response, e)
      end
    }
    srv.mount_proc('/DodontoF') {|request, response|
      begin
        case(request.path)
        when "/DodontoF/getDiceBotInfos"
          response.content_type = "application/json;charset=UTF-8"
          response.body = JSON::dump(API_DodontoF::getDiceBotInfos)
        when /\/DodontoF\/sendDiceBotChatMessage/
          response.content_type = "application/json;charset=UTF-8"
          response.body += JSON::dump(API_DodontoF::sendDiceBotChatMessage(request.query))
        else
          notFound(response)
        end
      rescue => e
        notFound(response, e)
      end
    }
    Signal.trap(:INT){ srv.shutdown }
    srv.start
  end

  def notFound(response, reason = "not found")
    response.status = 404
    response.content_type = "application/json;charset=UTF-8"
    response.body = JSON::dump({:ok => false,:reason => reason})
  end
end