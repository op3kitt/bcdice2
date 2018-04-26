#--*-coding:utf-8-*--

require 'cgi'

module CGIInterface

  def open
    @cgi_request = CGI.new('html4')
    begin
      command = ENV['REQUEST_URI']?ENV['REQUEST_URI']:ARGV[0]
      case(command)
      when "/"
        print "Hello. This is BCDice-API."
      when "/v1/version"
        print JSON::dump(API_v1::version)
      when "/v1/systems"
        print JSON::dump(API_v1::systems)
      when "/v1/systeminfo"
        print JSON::dump(API_v1::systeminfo({
          :system => @cgi_request['system']
        }))
      when "/v1/diceroll"
        print JSON::dump(API_v1::diceroll({
          :system => @cgi_request['system'],
          :command => @cgi_request['command']
        }))
      else
        notFound()
      end
    rescue => e
      notFound(e)
    end
  end

  def notFound(reason = "not found")
    @cgi_request.header({:status => "NOT_FOUND"})
    print JSON::dump({:ok => false,:reason => reason})
  end
end