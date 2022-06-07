
Grouping = Struct.new(:group1, :group2, :group3)
Presents = Struct.new(:weights)
class Presents
  def min_quantum_entangle
    smallest_group_1s.map do |grouping|
      quantum_entanglement(grouping.group1)
    end.min
  end

  def quantum_entanglement(grouping)
    grouping.reduce(&:*)
  end

  def smallest_group_1s
    possible_groups.group_by do |grouping|
      grouping.group1.size
    end[possible_groups.map(&:group1).map(&:size).min]
  end

  def possible_groups
    @possible_groups ||= groups(weights).flat_map do |group1|
      groups(weights - group1).flat_map do |group2|
        group3 = (weights - group1 - group2)
        Grouping.new(group1, group2, group3)
      end
    end
  end

  def weight
    @weight ||= weights.sum / 3
  end

  def groups(subgroup)
    1.upto(subgroup.size).flat_map do |size|
      subgroup.combination(size).filter do |group|
        group.sum == weight
      end
    end
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