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
    sum = 0
    parts.each do |part|
      wf = workflows["in"]

      catch :found_accepts do
        loop do
          catch :found_workflow do
            wf.steps.each do |step|
              if step.terminal? && step.destination == "A"
                sum += part.values.sum
                throw :found_accepts
              elsif step.terminal? && step.destination == "R"
                throw :found_accepts
              elsif step.terminal?
                wf = workflows[step.destination]
                throw :found_workflow
              end

              next unless part.send(step.name).send(step.operator, step.value)

              if step.destination == "A"
                sum += part.values.sum
                throw :found_accepts
              elsif step.destination == "R"
                throw :found_accepts
              end
              wf = workflows[step.destination]
              throw :found_workflow
            end
          end
        end
      end
    end

    sum
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

  Route = Struct.new(:destination) { def terminal? = true }
  Comparison =
    Struct.new(:name, :operator, :value, :destination) { def terminal? = false }

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
