require 'pp'

class Indicator
  def show m, c
    case m['type']
    when 'join'
      puts "[[SYSTEM]] #{m['name']} has joined the room!!"
    when 'public'
      puts "[[#{c[:name]}]] #{m['content']}"
    else
      pp m
    end
  end
end
