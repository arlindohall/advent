
require_relative './helpers'

def read_input
  @input ||= Problem.current.input_file.read.strip
end

def read_example(n = nil)
  @examples ||= {}
  @examples[n] ||= Problem.current.example_file(n).read.strip
end