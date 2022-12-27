$debug = false

class SeaMonster < Struct.new(:text)
  def matching_messages
    messages.count { |msg| matcher.matches?(msg) }
  end

  def updated!
    matcher.rules[8] = Matcher::Rule.new("8: 42 | 42 8", matcher.rules)
    matcher.rules[11] = Matcher::Rule.new("11: 42 31 | 42 11 31", matcher.rules)
    self
  end

  def matcher
    @matcher ||= Matcher.new(definitions)
  end

  def definitions
    text.split("\n\n").first
      .split("\n")
  end

  def messages
    text.split("\n\n").second.split("\n")
  end
end

class Matcher < Struct.new(:definitions)
  def matches?(string)
    rules[0].matches?(string, 0)
  end

  def rules
    return @rules if @rules
    @rules = {}
    definitions.map { |df| Rule.new(df, @rules) }
      .each { |rl| @rules[rl.number] = rl }

    @rules
  end

  class Rule < Struct.new(:definition, :rule_mapping)
    def matches?(string, index)
      matches_at(string, index).include?(string.size)
    end

    def matches_at(string, index)
      debug(message: "Matching string at index", number:, string:, index:)
      return [] if index >= string.size
      return match_letter(string, index) if is_letter?

      sub_rules.flat_map do |sub_rule_group|
        sub_group_matches(string, index, sub_rule_group)
      end.uniq.plop
    end

    def match_letter(string, index)
      string[index] == letter ? [index + 1] : []
    end

    def sub_group_matches(string, index, sub_rule_group)
      raise "Need some rule to match" if sub_rule_group.empty?
      matches = sub_rule_group.first.matches_at(string, index)

      return matches unless sub_rule_group.size > 1

      matches.flat_map do |match_index|
        sub_group_matches(string, match_index, sub_rule_group.drop(1))
      end
    end

    def number
      definition.split(":").first.to_i
    end

    def match_part
      definition.split(": ").last
    end

    def sub_rules
      sub_rule_indices
        .sub_map { |ri| rule_mapping[ri] }
    end

    def sub_rule_indices
      match_part.split("|").map(&:split)
        .map { |sr| sr.map(&:to_i) }
    end

    def is_letter?
      match_part.match?(/"[a-z]"/)
    end

    def letter
      match_part.match(/[a-z]/).to_a.first
    end
  end
end

def solve
  [
    SeaMonster.new(read_input).matching_messages,
    SeaMonster.new(read_input).updated!.matching_messages,
  ]
end