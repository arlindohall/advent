class Ratings
  def initialize(text)
    @text = text
  end

  memoize def workflows
    @text
      .split("\n\n")
      .first
      .split
      .map { |line| Workflow.parse(line) }
      .hash_by { |wf| wf.name }
  end

  memoize def parts
    @text.split("\n\n").last.split.map { |line| Part.parse(line) }
  end

  def part1
    parts
      .filter { |part| accept?("in", part) }
      .each { |part| _debug("Found part", part) }
      .map { |part| part.values.sum }
  end

  def accept?(workflow, part)
    workflows[workflow]
      .steps
      .find { |wf| wf.applies?(part) }
      .tap { |wf| _debug("Matching workflow", wf) }
      .accept?(part, workflows)
  end

  Part =
    Struct.new(:x, :m, :a, :s) do
      def self.parse(line)
        Part[*line.scan(/[xmas]=(\d+)/).flatten.map(&:to_i)]
      end
    end

  Workflow =
    Struct.new(:name, :steps) do
      def self.parse(line)
        Workflow[
          line.chars.take_while { |ch| ch != "{" }.join,
          line.match(/{(.*)}/)[1].split(",").map { |chunk| Step.parse(chunk) }
        ]
      end
    end

  Route =
    Struct.new(:destination) do
      def applies?(part) = true

      def accept?(part, other_workflows)
        return true if destination == "A"
        return false if destination == "R"

        other_workflows[destination].steps.any? { |wf| wf.applies?(part) }
      end
    end
  Comparison =
    Struct.new(:name, :operator, :value, :destination) do
      def applies?(part)
        binding.pry
        part.send(name).send(operator, value)
      end

      def accept?(part, other_workflows)
        return true if destination == "A"
        return false if destination == "R"

        other_workflows[destination].steps.any? { |wf| wf.applies?(part) }
      end
    end

  class Step
    def self.parse(chunk)
      return Route.new(chunk) unless chunk.include?(":")

      Comparison[
        chunk.split(/[<>]/).first,
        chunk.match(/[<>]/)[0],
        chunk.split(/[<>]/).last.split(":").first.to_i,
        chunk.split(":").last
      ]
    end
  end
end
