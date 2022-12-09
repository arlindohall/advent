
require_relative '../intcode'

class Network
  Packet = Struct.new(:destination, :x, :y)
  SIZE = 50

  def initialize(opts = {})
    @computers = opts[:computers] || Network.parse(input, SIZE)
    @read_buffer = opts[:read_buffer] || {}
    @write_buffer = opts[:write_buffer] || {}
    @nat = opts[:nat] || Nat.new
  end

  def run_nat
    startup
    catch(:nat) do ; loop do
      send_waiting if deadlocked?

      @computers.each_with_index { |c, i| continue!(c, i) }
    end ; end

    return @nat.memory.last
  end

  def run
    startup
    loop do
      send_waiting if deadlocked?

      @computers.each_with_index { |c, i| continue!(c, i) }
      return @nat.memory.last unless @nat.memory.empty?
    end
  end

  def idle?
    @computers.all? { _1.reading? }
  end

  def deadlocked?
    return false unless idle?
    return true if @write_buffer.all? { |_, v| v.empty? }

    false
  end

  def startup
    @computers.each { _1.start! }
    @computers.each_with_index { |c, i| c.send_signal(i) }
    @computers.each { _1.send_signal(-1) }
    @computers.each { _1.continue! }
    @computers.each { _1.continue! }
  end

  def send_waiting
    if @nat.memory.empty?
      puts "Skipping NAT because not memory"
      raise "Ending because deadlocked"
    end

    @nat.wake_up(@computers[0])
    @computers.each_with_index { |c, i| continue!(c, i) }
  end

  def continue!(computer, number)
    if computer.reading?
      read_in(computer, number)
    elsif computer.writing?
      write_out(computer, number)
    elsif computer.done?
      raise "I don't think the computers should finish early"
    else
      raise "Computer not done, reading, or writing... (state=#{computer})"
    end
    computer.continue!
  end

  def read_in(computer, number)
    @write_buffer[number] ||= []
    return if @write_buffer[number].empty?

    @write_buffer[number].shift.then do |x,y|
      computer.send_signal(x)
      computer.send_signal(y)
    end
  end

  def write_out(computer, number)
    while computer.writing?
      computer.continue!
    end

    signals = computer.receive_signals
    raise "Not multiple of three" unless signals.size % 3 == 0

    @read_buffer[number] ||= []
    signals.each do |s|
      @read_buffer[number] << s
    end

    @read_buffer[number].each_slice(3) do |slice|
      dest, x, y = slice
      if dest == 255
        @nat.receive([x, y])
        next
      end

      raise "Invalid address" if dest > 50
      @write_buffer[dest] ||= []
      @write_buffer[dest] << [x,y]
    end

    @read_buffer[number] = []
  end

  class << self
    def parse(text, size)
      program = IntcodeProgram.parse(text)
      size.times.map { program.dup }
    end
  end
end

class Nat
  def initialize(memory = [])
    @memory = memory
  end

  # 21458 too low
  def wake_up(computer)
    x, y = @memory
    raise "Invalid packet (#{{x:, y:}})" unless x && y

    puts "Waiting, engage NAT, memory/#{{x:, y:}}"
    throw(:nat) if @last_y == y
    @last_y = y

    computer.send_signal(x)
    computer.send_signal(y)
  end

  def memory
    @memory
  end

  def receive(packet)
    @memory = packet
  end
end

def solve
  [
    Network.new.run,
    Network.new.run_nat
  ]
end

def input = "3,62,1001,62,11,10,109,2235,105,1,0,866,1686,1593,1717,633,767,1783,1150,1872,666,938,1418,1014,1119,2142,571,1841,1552,1653,1387,1981,1812,829,1748,1451,1909,2113,1282,1181,907,2014,602,977,1622,1317,2084,1940,1247,1515,1482,1216,2173,736,1045,2043,1082,703,798,1352,2204,0,0,0,0,0,0,0,0,0,0,0,0,3,64,1008,64,-1,62,1006,62,88,1006,61,170,1105,1,73,3,65,21001,64,0,1,20101,0,66,2,21102,1,105,0,1105,1,436,1201,1,-1,64,1007,64,0,62,1005,62,73,7,64,67,62,1006,62,73,1002,64,2,133,1,133,68,133,101,0,0,62,1001,133,1,140,8,0,65,63,2,63,62,62,1005,62,73,1002,64,2,161,1,161,68,161,1101,1,0,0,1001,161,1,169,1002,65,1,0,1102,1,1,61,1101,0,0,63,7,63,67,62,1006,62,203,1002,63,2,194,1,68,194,194,1006,0,73,1001,63,1,63,1106,0,178,21102,1,210,0,105,1,69,2102,1,1,70,1102,1,0,63,7,63,71,62,1006,62,250,1002,63,2,234,1,72,234,234,4,0,101,1,234,240,4,0,4,70,1001,63,1,63,1105,1,218,1106,0,73,109,4,21101,0,0,-3,21101,0,0,-2,20207,-2,67,-1,1206,-1,293,1202,-2,2,283,101,1,283,283,1,68,283,283,22001,0,-3,-3,21201,-2,1,-2,1106,0,263,21202,-3,1,-3,109,-4,2106,0,0,109,4,21101,1,0,-3,21102,0,1,-2,20207,-2,67,-1,1206,-1,342,1202,-2,2,332,101,1,332,332,1,68,332,332,22002,0,-3,-3,21201,-2,1,-2,1106,0,312,21201,-3,0,-3,109,-4,2105,1,0,109,1,101,1,68,359,20101,0,0,1,101,3,68,366,21002,0,1,2,21101,0,376,0,1105,1,436,21201,1,0,0,109,-1,2105,1,0,1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768,65536,131072,262144,524288,1048576,2097152,4194304,8388608,16777216,33554432,67108864,134217728,268435456,536870912,1073741824,2147483648,4294967296,8589934592,17179869184,34359738368,68719476736,137438953472,274877906944,549755813888,1099511627776,2199023255552,4398046511104,8796093022208,17592186044416,35184372088832,70368744177664,140737488355328,281474976710656,562949953421312,1125899906842624,109,8,21202,-6,10,-5,22207,-7,-5,-5,1205,-5,521,21101,0,0,-4,21102,0,1,-3,21102,51,1,-2,21201,-2,-1,-2,1201,-2,385,470,21001,0,0,-1,21202,-3,2,-3,22207,-7,-1,-5,1205,-5,496,21201,-3,1,-3,22102,-1,-1,-5,22201,-7,-5,-7,22207,-3,-6,-5,1205,-5,515,22102,-1,-6,-5,22201,-3,-5,-3,22201,-1,-4,-4,1205,-2,461,1106,0,547,21102,1,-1,-4,21202,-6,-1,-6,21207,-7,0,-5,1205,-5,547,22201,-7,-6,-7,21201,-4,1,-4,1106,0,529,22101,0,-4,-7,109,-8,2105,1,0,109,1,101,1,68,564,20101,0,0,0,109,-1,2106,0,0,1102,43577,1,66,1101,1,0,67,1101,0,598,68,1101,0,556,69,1101,0,1,71,1101,600,0,72,1105,1,73,1,421,9,27718,1101,0,27697,66,1101,0,1,67,1101,629,0,68,1102,556,1,69,1102,1,1,71,1102,631,1,72,1105,1,73,1,-494360,10,30367,1101,92083,0,66,1102,1,2,67,1101,660,0,68,1101,351,0,69,1102,1,1,71,1101,664,0,72,1105,1,73,0,0,0,0,255,102059,1102,1,13859,66,1102,1,4,67,1102,1,693,68,1102,302,1,69,1101,1,0,71,1102,1,701,72,1105,1,73,0,0,0,0,0,0,0,0,46,11306,1102,5653,1,66,1102,2,1,67,1101,730,0,68,1101,302,0,69,1102,1,1,71,1102,1,734,72,1105,1,73,0,0,0,0,45,45789,1102,1,14753,66,1102,1,1,67,1101,0,763,68,1102,1,556,69,1101,0,1,71,1102,765,1,72,1105,1,73,1,11,32,178378,1101,0,57487,66,1102,1,1,67,1101,794,0,68,1102,556,1,69,1102,1,1,71,1102,1,796,72,1106,0,73,1,125,22,93871,1102,1,28279,66,1102,1,1,67,1102,1,825,68,1102,556,1,69,1101,1,0,71,1101,827,0,72,1106,0,73,1,-40,28,200366,1102,1,93871,66,1101,0,4,67,1102,1,856,68,1101,0,302,69,1101,1,0,71,1101,864,0,72,1105,1,73,0,0,0,0,0,0,0,0,36,197495,1101,0,102059,66,1101,0,1,67,1102,1,893,68,1101,0,556,69,1102,6,1,71,1101,0,895,72,1105,1,73,1,28727,46,5653,27,89599,27,268797,37,101963,37,203926,37,305889,1102,19069,1,66,1101,1,0,67,1102,1,934,68,1101,556,0,69,1102,1,1,71,1102,936,1,72,1105,1,73,1,160,36,236994,1101,30367,0,66,1101,0,5,67,1102,1,965,68,1102,1,253,69,1101,0,1,71,1102,975,1,72,1106,0,73,0,0,0,0,0,0,0,0,0,0,8,108753,1101,0,89189,66,1102,1,4,67,1102,1004,1,68,1102,302,1,69,1102,1,1,71,1102,1012,1,72,1106,0,73,0,0,0,0,0,0,0,0,45,15263,1101,0,19571,66,1102,1,1,67,1101,1041,0,68,1102,556,1,69,1101,1,0,71,1102,1043,1,72,1106,0,73,1,23593,23,57089,1101,0,76369,66,1101,0,4,67,1101,0,1072,68,1101,302,0,69,1101,1,0,71,1102,1080,1,72,1106,0,73,0,0,0,0,0,0,0,0,27,179198,1102,1,15263,66,1102,1,4,67,1102,1109,1,68,1101,0,253,69,1101,1,0,71,1102,1117,1,72,1105,1,73,0,0,0,0,0,0,0,0,4,92083,1102,102197,1,66,1102,1,1,67,1102,1146,1,68,1101,556,0,69,1101,1,0,71,1102,1,1148,72,1106,0,73,1,-17,23,171267,1102,26371,1,66,1102,1,1,67,1102,1,1177,68,1102,1,556,69,1102,1,1,71,1102,1179,1,72,1105,1,73,1,531210,10,151835,1102,100183,1,66,1102,3,1,67,1101,1208,0,68,1102,302,1,69,1101,1,0,71,1101,0,1214,72,1105,1,73,0,0,0,0,0,0,8,36251,1102,48799,1,66,1102,1,1,67,1101,1243,0,68,1101,556,0,69,1101,1,0,71,1102,1245,1,72,1106,0,73,1,31,38,364396,1101,0,101963,66,1102,3,1,67,1101,1274,0,68,1102,1,302,69,1101,0,1,71,1102,1,1280,72,1106,0,73,0,0,0,0,0,0,45,30526,1102,89599,1,66,1101,0,3,67,1101,1309,0,68,1102,1,302,69,1102,1,1,71,1102,1,1315,72,1106,0,73,0,0,0,0,0,0,45,61052,1102,1,40867,66,1102,1,3,67,1102,1344,1,68,1101,0,302,69,1101,0,1,71,1102,1,1350,72,1105,1,73,0,0,0,0,0,0,9,55436,1102,571,1,66,1101,1,0,67,1101,1379,0,68,1102,1,556,69,1101,3,0,71,1101,0,1381,72,1105,1,73,1,5,22,281613,22,375484,36,118497,1101,27073,0,66,1102,1,1,67,1101,0,1414,68,1101,556,0,69,1101,1,0,71,1102,1416,1,72,1106,0,73,1,3,43,305476,1101,0,61967,66,1101,2,0,67,1101,1445,0,68,1101,0,302,69,1101,1,0,71,1101,1449,0,72,1106,0,73,0,0,0,0,18,95261,1102,1,74287,66,1102,1,1,67,1101,1478,0,68,1101,0,556,69,1101,1,0,71,1101,1480,0,72,1106,0,73,1,25,38,273297,1102,69761,1,66,1102,1,1,67,1101,0,1509,68,1102,1,556,69,1101,2,0,71,1101,0,1511,72,1106,0,73,1,10,22,187742,36,78998,1101,91099,0,66,1102,4,1,67,1101,1542,0,68,1102,302,1,69,1102,1,1,71,1102,1550,1,72,1105,1,73,0,0,0,0,0,0,0,0,8,145004,1102,1,20959,66,1101,1,0,67,1102,1,1579,68,1101,0,556,69,1102,6,1,71,1101,0,1581,72,1106,0,73,1,2,11,123934,18,190522,32,356756,43,152738,36,39499,36,157996,1101,0,41051,66,1102,1,1,67,1101,1620,0,68,1102,1,556,69,1102,1,0,71,1102,1622,1,72,1106,0,73,1,1124,1101,0,64667,66,1101,0,1,67,1101,1649,0,68,1101,0,556,69,1102,1,1,71,1101,1651,0,72,1106,0,73,1,14419,28,100183,1101,95261,0,66,1102,1,2,67,1101,1680,0,68,1102,302,1,69,1101,0,1,71,1101,1684,0,72,1106,0,73,0,0,0,0,32,89189,1102,1499,1,66,1101,0,1,67,1101,0,1713,68,1102,1,556,69,1101,1,0,71,1101,0,1715,72,1105,1,73,1,584586,10,121468,1101,0,51071,66,1101,1,0,67,1101,1744,0,68,1102,1,556,69,1102,1,1,71,1101,0,1746,72,1106,0,73,1,747,38,91099,1101,0,57089,66,1101,3,0,67,1102,1,1775,68,1101,0,302,69,1101,0,1,71,1101,0,1781,72,1106,0,73,0,0,0,0,0,0,8,72502,1101,0,53693,66,1101,1,0,67,1101,1810,0,68,1102,556,1,69,1102,1,0,71,1102,1812,1,72,1105,1,73,1,1468,1102,78787,1,66,1101,0,1,67,1102,1,1839,68,1102,556,1,69,1101,0,0,71,1101,0,1841,72,1106,0,73,1,1513,1102,64187,1,66,1101,0,1,67,1101,0,1868,68,1102,556,1,69,1101,0,1,71,1101,1870,0,72,1105,1,73,1,109,9,41577,1101,36251,0,66,1101,4,0,67,1101,1899,0,68,1102,1,253,69,1101,0,1,71,1102,1,1907,72,1105,1,73,0,0,0,0,0,0,0,0,11,61967,1101,48871,0,66,1101,1,0,67,1102,1936,1,68,1101,0,556,69,1101,1,0,71,1102,1,1938,72,1106,0,73,1,1033006,10,91101,1102,1,39499,66,1101,0,6,67,1101,1967,0,68,1102,302,1,69,1101,1,0,71,1101,1979,0,72,1106,0,73,0,0,0,0,0,0,0,0,0,0,0,0,4,184166,1101,6359,0,66,1101,1,0,67,1102,2008,1,68,1102,1,556,69,1102,1,2,71,1101,0,2010,72,1105,1,73,1,-9749,32,267567,43,229107,1101,0,37663,66,1101,0,1,67,1101,2041,0,68,1101,0,556,69,1101,0,0,71,1102,1,2043,72,1105,1,73,1,1920,1101,0,80953,66,1102,1,1,67,1101,0,2070,68,1102,1,556,69,1101,0,6,71,1102,2072,1,72,1105,1,73,1,1,38,182198,23,114178,28,300549,34,40867,9,13859,43,76369,1101,44179,0,66,1102,1,1,67,1101,0,2111,68,1102,556,1,69,1101,0,0,71,1101,2113,0,72,1106,0,73,1,1102,1101,0,24977,66,1101,0,1,67,1102,2140,1,68,1101,0,556,69,1101,0,0,71,1102,1,2142,72,1105,1,73,1,1031,1101,0,15289,66,1101,0,1,67,1101,2169,0,68,1102,1,556,69,1102,1,1,71,1101,0,2171,72,1106,0,73,1,271,34,81734,1102,68597,1,66,1101,0,1,67,1102,2200,1,68,1102,556,1,69,1102,1,1,71,1101,2202,0,72,1105,1,73,1,566565,10,60734,1101,0,5683,66,1102,1,1,67,1101,0,2231,68,1101,556,0,69,1101,0,1,71,1101,0,2233,72,1105,1,73,1,148,34,122601"