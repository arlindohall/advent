
Presents = Struct.new(:weights)
class Presents
  def min_quantum_entangle
    smallest_group_1s.map do |grouping|
      quantum_entanglement(grouping)
    end.min
  end

  def quantum_entanglement(grouping)
    grouping.reduce(&:*)
  end

  def smallest_group_1s
    possible_first_groups.group_by do |grouping|
      grouping.size
    end[possible_first_groups.map(&:size).min]
  end

  def possible_first_groups
    @possible_groups ||= groups(weights, weight, [], [])
  end

  def weight
    @weight ||= weights.sum / 4
  end

  def groups(subgroup, desired_weight, found, rejected)
    return [found] if desired_weight == 0 #&& exists_two_groups?(subgroup + rejected, [], weight)
    return [] if subgroup.empty?
    return groups(subgroup.tail, desired_weight, found, rejected + [subgroup.first]) if subgroup.first > desired_weight

    groups(subgroup.tail, desired_weight - subgroup.first, found + [subgroup.first], rejected) +
      groups(subgroup.tail, desired_weight, found, rejected + [subgroup.first])
  end

  # def exists_two_groups?(subgroup, rejected, desired_weight)
  #   return true if desired_weight == 0 && exists_group?(rejected + subgroup.tail, weight)
  #   return false if subgroup.empty?
  #   return exists_two_groups?(
  #     subgroup.tail,
  #     rejected + [subgroup.first],
  #     desired_weight
  #   ) if subgroup.first > desired_weight

  #   return exists_two_groups?(
  #     subgroup.tail,
  #     rejected + [subgroup.first],
  #     desired_weight
  #   ) || exists_two_groups?(
  #     subgroup.tail,
  #     rejected,
  #     desired_weight - subgroup.first
  #   )
  # end

  # def exists_group?(subgroup, desired_weight)
  #   return true if desired_weight == 0
  #   return false if subgroup.empty?
  #   return exists_group?(subgroup.tail, desired_weight) if subgroup.first > desired_weight

  #   exists_group?(subgroup.tail, desired_weight - subgroup.first) || exists_group?(subgroup.tail, desired_weight)
  # end
end

class Array
  def tail
    self.drop(1)
  end
end

@input = %Q(
  1
  3
  5
  11
  13
  17
  19
  23
  29
  31
  41
  43
  47
  53
  59
  61
  67
  71
  73
  79
  83
  89
  97
  101
  103
  107
  109
  113
).strip.split.map(&:to_i)

@presents = Presents.new(@input)
@first_groups = @presents.possible_first_groups

# Took really long when calculating whether two additional groups exist...
# Is there some theorem which says the reamining numbers must add to
# three groups of the same value?? I'm not sure...