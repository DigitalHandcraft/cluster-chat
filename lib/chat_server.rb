require 'bundler/setup'
require 'em-websocket'
require 'pp'
require 'json'

class ChatServer

  def initialize host, port
    @clients = []
    @host = host
    @port = port
  end

  def broadcast message
    @clients.each{|c| c[:conn].send(message) }
  end

  def start
    EM::WebSocket.start({:host => @host, :port => @port}) do |ws_conn|
      client = {name:'', conn:ws_conn}
      ws_conn.onopen do
        @clients << client
      end

      ws_conn.onclose do
        broadcast "#{client[:name]} disconnected."
        @clients.delete ws_conn
      end

      ws_conn.onmessage do |message|
        begin
          d = JSON.parse(message)
          pp d
          case d['type']
          when 'join' then
            client[:name] = d['name']
            message = {from:'system', content:"#{client[:name]} joined the room!!"}
            broadcast JSON.unparse(message)
          when 'public' then
            message = {from:client[:name], content:d['content']}
            broadcast JSON.unparse(message)
          else
            puts "wrong type"
          end
        rescue
          puts 'invalid JSON format'
        end
      end
    end
  end

end