require 'bundler/setup'
require 'em-websocket'
require 'pp'
require 'json'

class WSFront
  def initialize chat, d
    @core = chat
    @host = d[:host]
    @port = d[:port]
    @clients = []
    @events = []
  end

  def addReceiveEvent ev
    @events << ev
  end

  def broadcast message
    @clients.each{|c| c[:conn].send(message) }
  end

  def multicast names, message
    dests = @clients.select {|c| names.include? c[:name] }
    dests.each {|c| c[:conn].send(message) }
  end

  def send_without names, message
    dests = @clients.select {|c| !names.include? c[:name] }
    dests.each {|c| c[:conn].send(message) }
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
          d = JSON.parse(message, {:symbolize_names => true})
          case d[:type]
          when 'join' then
            client[:name] = d[:name]
            broadcast message
            # send_without [client[:name]], JSON.unparse(message)
          when 'public' then
            d[:name] = client[:name]
            broadcast JSON.unparse(d)
          when 'whisper' then
            d[:from] = client[:name]
            multicast [d[:from], d[:to]], JSON.unparse(d)
          else
            puts "wrong type"
          end
          @events.each {|e| e.call d, client }
        rescue
          puts 'invalid JSON format'
        end
      end
    end
  end

end
