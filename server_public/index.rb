#! /bin/ruby

require "socket"
require "cgi"

cgi_request = CGI::new("html4")

port = 15535
server = "localhost"

s = TCPSocket.open(server, port)

command = ENV['REQUEST_URI']?ENV['REQUEST_URI']:ARGV[0]

case(command)
  when '/v1/version'
    s.write "version\n"
  when '/v1/systems'
    s.write "systems\n"
  when '/v1/systeminfo'
    s.write "systeminfo\n"
    s.write "#{cgi_request['system']}\n"
  when '/v1/diceroll'
    s.write "diceroll\n"
    s.write "#{cgi_request['system']}\n"
    s.write "#{cgi_request['command']}\n"
  else
    s.write "HELO\n"
end

while str = s.gets
  print str
end

s.close