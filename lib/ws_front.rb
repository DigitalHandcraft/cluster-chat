require 'bundler/setup'
require 'em-websocket'
require 'chat_core'
require 'json'

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

  def broadcast message
    @clients.each{|c| c[:conn].send(message)}
  end

  def multicast names, message
    dests = @clients.select {|c| names.include? c[:name]}
    dests.each {|c| c[:conn].send(message)}
  end

  def start
    EM::WebSocket.start({host: @host, port: @port}) do |conn|
      client = {name: '', conn: conn}

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
            # broadcast
          when 'users/info'
          when 'users/list'
          when 'users/leave'
          when 'statuses/load'
            # d[:start] should be like '2016/10/05 00:50:30'
            t0 = d[:start]
            t1 = d[:end]
            statuses = @core.load_statuses client[:ctx_id], t0, t1
            # bug in the case of duplicated name
            multicast [client[:name]]
          when 'statuses/add'
            @core.send client[:user][:ctx_id], d[:text]
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
