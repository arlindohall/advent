require_relative "./helpers"

def read_input(strip: true)
  if strip
    @input ||= Problem.current.input_file.read.strip
  else
    @input ||= Problem.current.input_file.read
  end
end

def read_example(n = nil, strip: true)
  @examples ||= {}

  if strip
    @examples[n] ||= Problem.current.example_file(n).read.strip
  else
    @examples[n] ||= Problem.current.example_file(n).read
  end
end
