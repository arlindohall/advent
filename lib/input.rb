
require_relative './helpers'

def read_input
  @input ||= Problem.current.input_file.read.strip
end

def read_example
  @example ||= Problem.current.example_file.read.strip
end