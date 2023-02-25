def solve =
  [
    Passages.parse(read_input).count_paths,
    DoublePassages.parse(read_input).count_paths
  ]

class Passages
  attr_reader :graph
  def initialize(graph)
    @graph = graph
  end

  def count_paths
    paths.count
  end

  def show_paths
    paths.each { |p| puts p.join(",") }
  end

  def paths
    intermediates = [["start"]]
    result = []
    while intermediates.any?
      follow(intermediates.shift).each do |pth|
        if pth.last == "end"
          result << pth
          next
        end

        intermediates << pth
      end
    end
    result
  end

  def follow(path)
    graph[path.last]
      .reject { |nxt| nxt == "start" }
      .reject { |nxt| unvisitable?(path, nxt) }
      .map { |nxt| path + [nxt] }
  end

  def unvisitable?(path, nxt)
    nxt.downcase == nxt && path.include?(nxt)
  end

  def self.parse(text)
    graph = {}
    text.split.each do |line|
      n1, n2 = line.split("-")
      graph[n1] ||= []
      graph[n2] ||= []
      graph[n1] << n2
      graph[n2] << n1
    end
    new(graph)
  end
end

class DoublePassages < Passages
  def unvisitable?(path, nxt)
    !visitable?(path, nxt)
  end

  def visitable?(path, nxt)
    return true if nxt.upcase == nxt
    return true if no_repeats?(path)
    return false if nxt == "start"

    path.count(nxt) == 0
  end

  def no_repeats?(path)
    dc = path.filter { |node| node.downcase == node }
    dc.uniq.count == dc.count
  end
end
