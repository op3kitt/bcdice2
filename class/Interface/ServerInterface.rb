#--*-coding:utf-8-*--

require "socket"

module ServerInterface
  def open
    $logger.debug("Server is open.", AppConfig.TCP)
    @server = TCPServer.open(AppConfig.TCP.port)
    while(true)
      Thread.start(@server.accept) do |s|
        begin
          case(s.gets.chomp)
          when "version"
            s.write JSON::dump(API_v1::version)
          when "systems"
            s.write JSON::dump(API_v1::systems)
          when "systeminfo"
            s.write JSON::dump(API_v1::systeminfo({
              :system => s.gets.chomp
            }))
          when "diceroll"
            s.write JSON::dump(API_v1::diceroll({
              :system => s.gets.chomp,
              :command => s.gets.chomp
            }))
          else
            s.write "Hello. This is BCDice-API."
          end
        rescue => e
          s.write JSON::dump({:ok => false,:reason => e})
        end
        s.close
      end
    end
  end
end