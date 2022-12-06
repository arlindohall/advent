
require_relative '../intcode'

class Computer
  ITEMS = [
    "monolith",
    "bowl of rice",
    "ornament",
    "shell",
    "astrolabe",
    "planetoid",
    "cake",
  ].freeze

  attr_reader :intcode
  def initialize(intcode, stdin = $stdin)
    @intcode = intcode
    @stdin = stdin
  end

  def manual
    @intcode.start!
    loop do
      clear_already_read
      print_output
      read_line(gets)
    end
  end

  def solve
    @intcode.start!
    clear_already_read
    print_output
    shortest_path
    clear_already_read
    print_output
    read_line("north\n", false)
    read_line("north\n")
  rescue
    print_output
  end

  # def solve
  #   @intcode.start!
  #   clear_already_read
  #   print_output
  #   read_input
  #   try_all_combinations
  #   nil
  # end

  def try_all_combinations
    combinations.each do |combo|
      drop_all
      take(combo)
      inventory
      north
      print_output_for_door
    end
  end

  def print_output_for_door
    clear_already_read
    @intcode.receive_signals.pack('c*').then do |output|
      print output
      unless output.include?("Alert")
        puts "BANANA->"
      end
    end
  end

  def drop_all
    ITEMS.each do |item|
      read_line("drop #{item}\n")
    end
  end

  def take(combo)
    combo.each do |item|
      read_line("take #{item}\n")
    end
  end

  def inventory
    read_line("inv\n")
  end

  def north
    read_line("north\n", false)
  end

  def combinations
    1.upto(7).flat_map { ITEMS.combination(_1).to_a }
  end

  def signal
    s = @stdin.gets
    s.bytes.each { @intcode.send_signal(_1) }
  end

  def clear_already_read
    @intcode.continue! until @intcode.inputs.empty? && @intcode.reading?
  end

  def print_output
    @intcode.receive_signals.pack('c*').then { print _1 }
  end

  def shortest_path
    <<~starter.lines.each { |line| read_line(line) }
    east
    east
    south
    take monolith
    north
    west
    north
    north
    take planetoid
    west
    south
    south
    take fuel cell
    north
    north
    east
    east
    south
    west
    north
    take astrolabe
    west
    starter
  end

  def read_input
    <<~starter.lines.each { |line| read_line(line) }
    east
    east
    east
    take shell
    west
    south
    take monolith
    north
    west
    north
    west
    take bowl of rice
    east
    north
    take planetoid
    west
    take ornament
    south
    south
    take fuel cell
    north
    north
    east
    east
    take cake
    south
    west
    north
    take astrolabe
    west
    starter
  end

  def read_line(line, show_output = true)
    line.bytes.each do |ch|
      @intcode.send_signal(ch)
    end
    print line

    if show_output
      clear_already_read
      print_output
    end
  end

  def self.parse(text)
    new(IntcodeProgram.parse(text).dup)
  end
end



def solve
  Computer.parse(@input).solve
end

@input = File.new(Pathname.new(__FILE__).parent.join('input').to_s).read