require 'bundler/setup'
require 'em-websocket'
require 'chat_core'
require 'json'
require 'time'

class WSFront
  def initialize chat_core, args
    @core = chat_core
    @host = args[:host]
    @port = args[:port]
    p args[:host]
    p args[:port]
    @clients = []
    @events = []
  end

  def addEventHandler event
    @events << event
  end

  def broadcast ctx_id, text
    dests = @clients.select{|c| c[:user][:ctx_id] == ctx_id}
    dests.each{|c| c[:conn].send(text)}
  end

  def multicast ctx_id, names, text
    dests0 = @clients.select{|c| c[:user][:ctx_id] == ctx_id}
    dests1 = dests0.select{|c| names.include? c[:user][:name]}
    dests1.each {|c| c[:conn].send(text)}
  end

  def loopback client, text
    client[:conn].send(text)
  end

  def start
    EM::WebSocket.start({host: @host, port: @port}) do |conn|
      client = {conn: conn}

      conn.onopen do
        @clients << client
      end

      conn.onclose do
        # broadcast {}
        @clients.delete conn
      end

      conn.onmessage do |message|
        begin
          d = JSON.parse(message, {symbolize_names: true})
          case d[:dest]
          when 'users/join'
            client[:user] = @core.join d[:ctx_id], d[:name]
            p @clients
            # broadcast
          when 'users/info'
          when 'users/list'
          when 'users/leave'
          when 'statuses/load'
            # d[:start] should be like '2016-10-05 00:50:30 +0900'
            t0 = Time.parse(d[:start]).utc
            t1 = Time.parse(d[:end]).utc
            statuses = @core.load_statuses client[:user][:ctx_id], t0, t1
            # bug in the case of duplicated name
            loopback client, JSON.unparse(statuses)
          when 'statuses/add'
            res = @core.send client[:user][:ctx_id], d[:text]
            broadcast client[:user][:ctx_id], JSON.unparse(res[:data])
          when 'contexts/info'
          else
            puts 'wrong type'
          end
        rescue
          puts 'invalid JSON format'
        end
      end
    end
  end
end
