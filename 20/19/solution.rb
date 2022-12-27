
class SeaMonster < Struct.new(:text)
  def matching_messages
    messages.count do |message|
      matcher.produces.include?(message)
    end
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
  attr_reader :index

  def produces
    rules[0].produces
  end

  def matches?(string)
    @index = 0
  end

  def rules
    return @rules if @rules
    @rules = {}
    definitions.map { |df| Rule.new(df, @rules) }
      .each { |rl| @rules[rl.number] = rl }

    @rules
  end

  def debug_graph
    puts "digraph {"
    rules.values.each do |rule|
      if rule.is_letter?
        puts "  #{rule.number} -> #{rule.letter}"
      else
        rule.sub_rules.each do |subrule|
          subrule_name = %("#{subrule.map(&:number)}")
          puts "  #{rule.number} -> #{subrule_name}"
          subrule.each do |individual_subrule|
            puts "  #{subrule_name} -> #{individual_subrule.number}"
          end
        end
      end
    end
    puts "}"
  end

  class Rule < Struct.new(:definition, :rule_mapping)
    def number
      definition.split(":").first.to_i
    end

    def match_part
      definition.split(": ").last
    end

    def produces
      @produces ||= build_produced_strings
    end

    def build_produced_strings
      return Set[letter] if is_letter?

      debug(sub_rules_size: sub_rules.size)
      i = 0
      sub_rules.map do |sub_rule_group|
        debug(index: i+=1)
        produces_for_group([""], sub_rule_group).to_set.tap { _1.size.plop }
      end.reduce(&:+)
    end

    def produces_for_group(produced, group)
      debug(number:, produced_size: produced.size, group_size: group.size)
      return produced if group.empty?

      produces_for_group(
        produced.flat_map { |str| group.first.produces.map { |pr| str + pr } }.to_set,
        group.drop(1)
      ).to_set
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