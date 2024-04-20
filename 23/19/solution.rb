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
      sum += values_if_accepts(wf, 0, part)
    end

    sum
  end

  def values_if_accepts(wf, step_index, part)
    step = wf.steps[step_index]

    return values_if_accepts(wf, step_index + 1, part) unless step.fits?(part)

    return part.values.sum if step.destination == "A"
    return 0 if step.destination == "R"
    wf = workflows[step.destination]
    values_if_accepts(wf, 0, part)
  end

  def part2
    max_accepts("in", 0, Constraints.new)
  end

  memoize def max_accepts(wf_name, step_index, constraints)
    return 0 if wf_name == "R"
    return constraints.size if wf_name == "A"

    wf = workflows[wf_name]
    raise "impossible state, must have found step" if wf.nil?

    step = wf.steps[step_index]
    return 0 if step.nil?

    if step.fits_constraints?(constraints)
      max_accepts(step.destination, 0, constraints.with(step)) +
        max_accepts(wf_name, step_index + 1, constraints.without(step))
    else
      max_accepts(wf_name, step_index + 1, constraints)
    end
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
      def terminal?() = true
      def fits?(step) = true
      def fits_constraints?(_) = true
    end
  Comparison =
    Struct.new(:name, :operator, :value, :destination) do
      def terminal?() = false
      def fits?(step)
        step.send(name).send(operator, value)
      end

      def fits_constraints?(constraints)
        case name
        when "x"
          constraints.xmin <= value && constraints.xmax >= value
        when "m"
          constraints.mmin <= value && constraints.mmax >= value
        when "a"
          constraints.amin <= value && constraints.amax >= value
        when "s"
          constraints.smin <= value && constraints.smax >= value
        else
          raise "impossible constraint matching"
        end
      end
    end

  Constraints =
    Struct.new(:xmin, :xmax, :mmin, :mmax, :amin, :amax, :smin, :smax) do
      def initialize(
        xmin = 1,
        xmax = 4000,
        mmin = 1,
        mmax = 4000,
        amin = 1,
        amax = 4000,
        smin = 1,
        smax = 4000
      )
        super
      end

      def greater_than_max(step, compare_name, compare_value)
        if step.name == compare_name && step.operator == ">"
          [step.value, compare_value].max
        else
          compare_value
        end
      end

      def less_than_max(step, compare_name, compare_value)
        if step.name == compare_name && step.operator == "<"
          [step.value, compare_value].min
        else
          compare_value
        end
      end

      def with(step)
        return self if step.terminal?
        Constraints[
          greater_than_max(step, "x", xmin),
          less_than_max(step, "x", xmax),
          greater_than_max(step, "m", mmin),
          less_than_max(step, "m", mmax),
          greater_than_max(step, "a", amin),
          less_than_max(step, "a", amax),
          greater_than_max(step, "s", smin),
          less_than_max(step, "s", smax)
        ].enforce_valid
      end

      def greater_than_min(step, compare_name, compare_value)
        if step.name == compare_name && step.operator == ">"
          [step.value, compare_value].min
        else
          compare_value
        end
      end

      def less_than_max(step, compare_name, compare_value)
        if step.name == compare_name && step.operator == "<"
          [step.value, compare_value].max
        else
          compare_value
        end
      end

      def without(step)
        return self if step.terminal?
        Constraints[
          greater_than_min(step, "x", xmin),
          less_than_max(step, "x", xmax),
          greater_than_min(step, "m", mmin),
          less_than_max(step, "m", mmax),
          greater_than_min(step, "a", amin),
          less_than_max(step, "a", amax),
          greater_than_min(step, "s", smin),
          less_than_max(step, "s", smax)
        ]
      end

      def size
        raise "impossible interval #{self}" unless values.all?
        return 0 if diffs.any? { |diff| diff < 0 }

        diffs.product
      end

      def diffs
        [xmax - xmin, mmax - mmin, amax - amin, smax - smin]
      end

      def enforce_valid
        raise "impossible interval" if diffs.any? { |diff| diff < 0 }
        self
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
