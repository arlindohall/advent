class Polymer
  attr_reader :template, :rules
  def initialize(template, rules)
    @template = template
    @rules = rules
  end

  def most_minus_least
    it = self
    10.times { it = it.insert }
    frequencies = it.template.count_values

    frequencies.values.max - frequencies.values.min
  end

  def insert
    Polymer.new(update_template, rules)
  end

  def update_template
    updated = []
    template.size.times do |idx|
      updated << template[idx]
      if rules.include?([template[idx], template[idx + 1]])
        updated << rules[[template[idx], template[idx + 1]]]
      end
    end

    updated
  end

  def self.parse(text)
    template, rules = text.split("\n\n")

    new(
      template.chars,
      rules
        .split("\n")
        .map { |rl| rl.split(" -> ") }
        .to_h
        .transform_keys(&:chars)
    )
  end
end
