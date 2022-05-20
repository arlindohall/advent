
require 'debug'
require 'pry'

########################################################
#################### IMPLEMENTATION ####################
########################################################

class StringParser < Struct.new(:input)
  def parse_string
    self.input = input.lines
    output = input.map { |line|
      LineParser.new(line.strip)
    }.map { |parser|
      parser.parse_line
    }

    ParsedString.new(input, output)
  end
end

class ParsedString < Struct.new(:input, :output)
  def difference
    output.map{ |parsed_line|
      parsed_line.difference
    }.sum
  end
end

class LineParser < Struct.new(:input, :output)
  def parse_line
    parsed_line = ParsedLine.new(input, [])
    @start = 1
    @end = 2

    while @end < input.length
      parsed_line.output << parse_cluster
    end

    parsed_line.output = parsed_line.output.join
    parsed_line
  end

  def parse_cluster
    begin
      parse_char
    ensure
      @start = @end
      @end += 1
    end
  end

  def parse_char
    case input[@start]
    when '\\'
      parse_escape
    else
      input[@start]
    end
  end

  def parse_escape
    @start += 1
    case input[@start]
    when 'x'
      @start += 1
      @end += 3
      [input[@start...@end].to_i(16)].pack("U")
    when '"'
      @end += 1
      '"'
    when '\\'
      @end += 1
      '\\'
    else
      throw "Unexpected character: #{input[@index]} at index=#{@index}"
    end
  end
end

class ParsedLine < Struct.new(:input, :output)
  def difference
    input.length - output.length
  end
end

##################################################
#################### SOLUTION ####################
##################################################

# @example = Pathname.new(__FILE__).parent.join('test.txt').read
@example = Pathname.new(__FILE__).parent.join('input.txt').read

@parsed = StringParser.new(@example).parse_string

pp @parsed
puts @parsed.difference
