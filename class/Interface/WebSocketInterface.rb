#--*-coding:utf-8-*--

require 'em-websocket'

module WebSocketInterface
  def open
    $logger.debug("Server is open.", AppConfig.WebSocket)
    @connections = []

    EM::WebSocket.start({:host => AppConfig.WebSocket.host, :port => AppConfig.WebSocket.port}) do |ws_conn|

      ws_conn.onopen do
        @connections << ws_conn
      end

      ws_conn.onmessage do |message|
        begin
          message = message.split(/[\s\n]/)
          case(message.shift.chomp)
          when "version"
            write JSON::dump(API_v1::version)
          when "systems"
            write JSON::dump(API_v1::systems)
          when "systeminfo"
            write JSON::dump(API_v1::systeminfo({
              :system => message.shift.chomp
            }))
          when "diceroll"
            write JSON::dump(API_v1::diceroll({
              :system => message.shift.chomp,
              :command => message.shift.chomp
            }))
          else
            write "Hello. This is BCDice-API."
          end
        rescue => e
          write JSON::dump({:ok => false,:reason => e})
        end
      end
    end
  end

  def write(message)
    $logger.debug(message)
    @connections.each{|conn| conn.send(message) }
  end
end