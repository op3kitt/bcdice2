#--*-coding:utf-8-*--

class Interface

    def initialize
      @interface =
      case AppConfig.Interface
        when "Server"
          extend ServerInterface
        when "CGI"
          extend CGIInterface
        when "IRC"
          extend IRCInterface
        when "Http"
          extend HttpInterface
        when "WebSocket"
          extend WebSocketInterface
        else
          raise "Missing Interface named " << AppConfig.Interface
      end
      $logger.debug("Interface", @interface)

      open
    end

    def write(*arg)
      raise NotImplementedError
    end

    def open(*arg)
      raise NotImplementedError
    end
end