def solve =
  Session
    .new(terminal: read_input)
    .then { |it| [it.at_most_100k, it.smallest_deletable] }

class Session
  shape :terminal

  def at_most_100k
    sizes.values.filter { |v| v < 100_000 }.sum
  end

  def smallest_deletable
    sizes.values.filter { |v| v > space_needed }.min
  end

  # private

  def filesystem
    TerminalOutput.parse(terminal).filesystem
  end

  memoize def space_needed
    update_space - available_space
  end

  def update_space
    30_000_000
  end

  def available_space
    total_space - used_space
  end

  def total_space
    70_000_000
  end

  def used_space
    sizes["/"]
  end

  memoize def sizes
    mapping = {}
    dir_size(filesystem, mapping, "/")
    mapping
  end

  def dir_size(hash, mapping, path)
    case hash
    when Numeric
      hash
    when Hash
      mapping[path] = hash
        .map { |name, contents| dir_size(contents, mapping, "#{path}/#{name}") }
        .sum
    else
      raise "Unknown filesystem: #{hash.inspect}"
    end
  end
end

class TerminalOutput
  shape :directives

  def self.parse(text)
    new(directives: text.split("$ ").reject(&:empty?).map(&:split))
  end

  def filesystem
    browser = Browser.new
    directives.each { |directive| browser.follow(directive) }
    browser.filesystem
  end
end

class Browser
  shape :location, :filesystem, filesystem: {}, location: []

  def follow(directive)
    instruction, *args = directive
    if instruction == "cd"
      cd(*args)
    elsif instruction == "ls"
      ls(*args)
    else
      raise "Unknown directive: #{directive.inspect}"
    end
  end

  def cd(dest)
    case dest
    when ".."
      location.pop
    when "/"
      @location = []
    else
      location.push(dest)
    end
  end

  def ls(*files)
    files.each_slice(2) do |arg, file|
      arg.match(/\d+/) ? create_file(file, arg.to_i) : create_directory(file)
    end
  end

  def create_file(name, size)
    if location.empty?
      filesystem[name] = size
    else
      filesystem.dig(*location)[name] = size
    end
  end

  def create_directory(name)
    if location.empty?
      filesystem[name] ||= {}
    else
      filesystem.dig(*location)[name] ||= {}
    end
  end
end
