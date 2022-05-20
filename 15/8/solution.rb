
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

  def encode_string
    self.full_input = full_input.lines
    output = full_input.map { |line|
      RawString.new(line.strip)
    }.map { |parser|
      parser.encode_line
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
  def encode_line
    new_line = text.chars.map{ |char|
      case char
      when '"'
        '\\"'
      when '\\'
        '\\\\'
      else
        char
      end
    }

    new_line = "\"#{new_line.join}\""
    StringRepresentation.new(text, new_line)
  end

  def parse_line
    memory = []
    @start = 1
    @end = 2

    while @end < text.length
      memory << parse_cluster
    end

    StringRepresentation.new(text, memory)
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

# @example = Pathname.new(__FILE__).parent.join('test.txt').read
@example = Pathname.new(__FILE__).parent.join('input.txt').read

@parsed = StringList.new(@example).parse_string

pp @parsed
puts @parsed.difference

@encoded = StringList.new(@example).encode_string
pp @encoded
puts -@encoded.difference
