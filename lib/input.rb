require_relative "./helpers"

def read_input(strip: true)
  @input ||= Problem.current.input_file.read.strip if strip
  @input ||= Problem.current.input_file.read unless strip
end

def read_example(n = nil, strip: true)
  @examples ||= {}

  @examples[n] ||= Problem.current.example_file(n).read.strip if strip
  @examples[n] ||= Problem.current.example_file(n).read unless strip
end
