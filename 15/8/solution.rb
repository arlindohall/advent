
require 'debug'
require 'pry'

########################################################
#################### IMPLEMENTATION ####################
########################################################

class StringList < Struct.new(:full_input)
  def parse_string
    self.full_input = full_input.lines
    output = full_input.map { |line|
      RawString.new(line.strip)
    }.map { |parser|
      parser.parse_line
    }

    StringPairs.new(full_input, output)
  end
end

class StringPairs < Struct.new(:input, :output)
  def difference
    output.map{ |parsed_line|
      parsed_line.difference
    }.sum
  end
end

class RawString < Struct.new(:text)
  def parse_line
    parsed_line = StringRepresentation.new(text, [])
    @start = 1
    @end = 2

    while @end < text.length
      parsed_line.memory << parse_cluster
    end

    parsed_line.memory = parsed_line.memory.join
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
    case text[@start]
    when '\\'
      parse_escape
    else
      text[@start]
    end
  end

  def parse_escape
    @start += 1
    case text[@start]
    when 'x'
      @start += 1
      @end += 3
      [text[@start...@end].to_i(16)].pack("U")
    when '"'
      @end += 1
      '"'
    when '\\'
      @end += 1
      '\\'
    else
      throw "Unexpected character: #{text[@index]} at index=#{@index}"
    end
  end
end

class StringRepresentation < Struct.new(:code, :memory)
  def difference
    code.length - memory.length
  end
end

##################################################
#################### SOLUTION ####################
##################################################

@example = Pathname.new(__FILE__).parent.join('test.txt').read
# @example = Pathname.new(__FILE__).parent.join('input.txt').read

@parsed = StringList.new(@example).parse_string

pp @parsed
puts @parsed.difference
