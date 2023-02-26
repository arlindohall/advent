def solve =
  Polymer
    .parse(read_input)
    .then { |it| [it.most_minus_least, it.most_minus_least(40)] }

class Polymer
  attr_reader :template, :rules
  def initialize(template, rules)
    @template = template
    @rules = rules
  end

  def most_minus_least(n = 10)
    it = self
    n.times { it = it.insert }
    frequencies =
      it
        .template
        .group_by { |name, _count| name[0] }
        .transform_values { |counts| counts.map(&:last).sum }

    frequencies.values.max - frequencies.values.min
  end

  def insert
    Polymer.new(update_template, rules)
  end

  def update_template
    template
      .flat_map do |word, count|
        if rules[word]
          rules[word].map { |produce| [produce, count] }
        else
          [[word, count]]
        end
      end
      .group_by(&:first)
      .transform_values { |produced| produced.map(&:last).sum }
  end

  def self.parse(text)
    template, rules = text.split("\n\n")

    new(
      template.size.times.map { |idx| template[idx..idx + 1] }.count_values,
      rules
        .split("\n")
        .map { |rl| rl.split(" -> ") }
        .map do |word, produces|
          [word, [word[0] + produces, produces + word[1]]]
        end
        .to_h
    )
  end
end
