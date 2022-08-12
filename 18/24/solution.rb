
Group = Struct.new(
  :index,
  :type,
  :units,
  :hp,
  :weaknesses,
  :immunities,
  :attack,
  :attack_type,
  :initiative,
)
class Group
  attr_reader :target

  def effective_power
    units * attack
  end

  def select_target(targets, output)
    return @target = nil if targets.empty?

    # todo tie breaker
    @target = targets.sort_by { |target|
      [-damage_to(target), -target.effective_power, -target.initiative]
    }

    targets.each { |t|
      output.puts("#{type == :infection ? "Infection" : "Immune System"} group #{index + 1} would deal defending group #{t.index + 1} #{damage_to(t)} damage")
    }
    
    @target = @target.first
    targets.delete(@target)
  end

  def damage_to(target = nil)
    target ||= @target
    if target.weaknesses.include?(attack_type)
      effective_power * 2
    elsif target.immunities.include?(attack_type)
      0
    else
      effective_power
    end
  end

  def perform_attack
    @target.units -= damage_to / @target.hp
  end
end

class Battle
  def initialize(immune_system, infection, output)
    @immune_system = immune_system
    @infection = infection
    @output = output
  end

  def battle
    until defeat?
      fight
    end
    status

    [@immune_system, @infection].flat_map { |groups| groups.map(&:units) }.sum
  end

  def fight
    status
    @output.puts

    select_targets
    @output.puts

    attack
  end

  def select_targets
    # Sort by also makes a copy
    inf_targets = @immune_system.sort_by(&:index)
    is_targets = @infection.sort_by(&:index)

    inf_groups.each_with_index { |group|
      group.select_target(inf_targets, @output)
    }
    is_groups.each_with_index { |group|
      group.select_target(is_targets, @output)
    }
  end

  def attack
    all_groups.sort_by { |group| -group.initiative }.each { |group|
      attack_for(group)
    }
  end

  def attack_for(group)
    # Group might have been defeated since we started attacking
    return unless all_groups.include?(group)
    return unless group.target

    print_attack(group)
    group.perform_attack

    return if group.target.units > 0

    defeat(group.target)
  end

  def print_attack(group)
    killed = [group.damage_to / group.target.hp, group.target.units].min
    @output.puts(
      (group.type == :infection ? "Infection" : "Immune System") +
      " group #{group.index + 1} attacks defending " + 
      "group #{group.target.index + 1}, killing " +
      "#{killed} unit" +
      (killed == 1 ? "" : "s")
    )
  end

  def defeat(target)
    # Will only be in one of these, doesn't matter which
    @immune_system.delete(target)
    @infection.delete(target)
  end

  def inf_groups
    sort_group(@infection)
  end

  def is_groups
    sort_group(@immune_system)
  end

  def all_groups
    @immune_system + @infection
  end

  def sort_group(group)
    group.sort_by { |group|
      [-group.effective_power, -group.initiative]
    }
  end

  def status
    @output.puts("Immune System:")

    if @immune_system.empty?
      @output.puts("No groups remain.")
    end

    @immune_system.each_with_index { |group|
      @output.puts("Group #{group.index + 1} contains #{group.units} units")
    }

    if @infection.empty?
      @output.puts("No groups remain.")
    end

    @output.puts("Infection:")
    @infection.each_with_index { |group|
      @output.puts("Group #{group.index + 1} contains #{group.units} units")
    }
  end

  def defeat?
    @immune_system.empty? || @infection.empty?
  end

  def self.parse(text, output = $stdout)
    immune, infection = text.split("\n\n")
      .map { |block| [block.split("\n").first[...-1].downcase.to_sym, block.split("\n").drop(1)] }
      .map { |type, block| block.each_with_index.map { |line, idx| parse_group(type, line, idx) }}
    
    new(immune, infection, output)
  end

  def self.parse_group(type, text, index)
    units = text.match(/(\d+) units/).captures.first.to_i
    hp = text.match(/(\d+) hit points/).captures.first.to_i

    weaknesses = properties(text, "weak to")
    immunities = properties(text, "immune to")

    attack, attack_type = text.match(/does (\d+) (\w+) damage/).captures
    attack = attack.to_i
    attack_type = attack_type.to_sym

    initiative = text.match(/initiative (\d+)/).captures.first.to_i

    Group.new(index, type, units, hp, weaknesses, immunities, attack, attack_type, initiative)
  end

  def self.properties(text, split_on)
    match = text.match(/#{split_on} (\w+)(, (\w+))*/)

    return [] unless match

    match.match(0)
      .split("#{split_on} ")
      .last
      .split(", ")
      .map(&:to_sym)
  end
end

def test
  os_stream = File.open("mine.txt", 'w')
  answer = Battle.parse(@example_input, os_stream).battle
  os_stream.close

  File.write('theirs.txt', @example_output)

  puts File.read('mine.txt') == @example_output ? "PASS" : "FAIL"
  puts answer
end

def solve
  puts Battle.parse(@input).battle
end

@example_input = <<~input
Immune System:
17 units each with 5390 hit points (weak to radiation, bludgeoning) with an attack that does 4507 fire damage at initiative 2
989 units each with 1274 hit points (immune to fire; weak to bludgeoning, slashing) with an attack that does 25 slashing damage at initiative 3

Infection:
801 units each with 4706 hit points (weak to radiation) with an attack that does 116 bludgeoning damage at initiative 1
4485 units each with 2961 hit points (immune to radiation; weak to fire, cold) with an attack that does 12 slashing damage at initiative 4
input

@input = <<~input.strip
Immune System:
698 units each with 10286 hit points with an attack that does 133 fire damage at initiative 9
6846 units each with 2773 hit points (weak to slashing, cold) with an attack that does 4 slashing damage at initiative 14
105 units each with 6988 hit points (weak to bludgeoning; immune to radiation) with an attack that does 616 radiation damage at initiative 17
5615 units each with 7914 hit points (weak to bludgeoning) with an attack that does 13 radiation damage at initiative 20
1021 units each with 10433 hit points (weak to cold; immune to slashing, bludgeoning) with an attack that does 86 bludgeoning damage at initiative 12
6099 units each with 11578 hit points with an attack that does 15 bludgeoning damage at initiative 13
82 units each with 1930 hit points (weak to bludgeoning; immune to cold) with an attack that does 179 bludgeoning damage at initiative 5
2223 units each with 9442 hit points (immune to bludgeoning) with an attack that does 38 cold damage at initiative 19
140 units each with 7594 hit points (weak to radiation) with an attack that does 452 fire damage at initiative 8
3057 units each with 3871 hit points (weak to bludgeoning) with an attack that does 11 radiation damage at initiative 16

Infection:
263 units each with 48098 hit points (immune to radiation; weak to slashing) with an attack that does 293 bludgeoning damage at initiative 2
111 units each with 9893 hit points (immune to slashing) with an attack that does 171 fire damage at initiative 18
2790 units each with 36205 hit points with an attack that does 25 cold damage at initiative 4
3325 units each with 46479 hit points (weak to slashing) with an attack that does 27 radiation damage at initiative 1
3593 units each with 6461 hit points (weak to fire, slashing) with an attack that does 3 radiation damage at initiative 15
2925 units each with 13553 hit points (weak to cold, bludgeoning; immune to fire) with an attack that does 8 cold damage at initiative 10
262 units each with 43260 hit points (weak to cold) with an attack that does 327 radiation damage at initiative 6
4228 units each with 24924 hit points (weak to radiation, fire; immune to cold, bludgeoning) with an attack that does 11 cold damage at initiative 11
689 units each with 42315 hit points (weak to cold, slashing) with an attack that does 116 fire damage at initiative 7
2649 units each with 37977 hit points (weak to radiation) with an attack that does 24 cold damage at initiative 3
input

@example_output = <<~output
Immune System:
Group 1 contains 17 units
Group 2 contains 989 units
Infection:
Group 1 contains 801 units
Group 2 contains 4485 units

Infection group 1 would deal defending group 1 185832 damage
Infection group 1 would deal defending group 2 185832 damage
Infection group 2 would deal defending group 2 107640 damage
Immune System group 1 would deal defending group 1 76619 damage
Immune System group 1 would deal defending group 2 153238 damage
Immune System group 2 would deal defending group 1 24725 damage

Infection group 2 attacks defending group 2, killing 84 units
Immune System group 2 attacks defending group 1, killing 4 units
Immune System group 1 attacks defending group 2, killing 51 units
Infection group 1 attacks defending group 1, killing 17 units
Immune System:
Group 2 contains 905 units
Infection:
Group 1 contains 797 units
Group 2 contains 4434 units

Infection group 1 would deal defending group 2 184904 damage
Immune System group 2 would deal defending group 1 22625 damage
Immune System group 2 would deal defending group 2 22625 damage

Immune System group 2 attacks defending group 1, killing 4 units
Infection group 1 attacks defending group 2, killing 144 units
Immune System:
Group 2 contains 761 units
Infection:
Group 1 contains 793 units
Group 2 contains 4434 units

Infection group 1 would deal defending group 2 183976 damage
Immune System group 2 would deal defending group 1 19025 damage
Immune System group 2 would deal defending group 2 19025 damage

Immune System group 2 attacks defending group 1, killing 4 units
Infection group 1 attacks defending group 2, killing 143 units
Immune System:
Group 2 contains 618 units
Infection:
Group 1 contains 789 units
Group 2 contains 4434 units

Infection group 1 would deal defending group 2 183048 damage
Immune System group 2 would deal defending group 1 15450 damage
Immune System group 2 would deal defending group 2 15450 damage

Immune System group 2 attacks defending group 1, killing 3 units
Infection group 1 attacks defending group 2, killing 143 units
Immune System:
Group 2 contains 475 units
Infection:
Group 1 contains 786 units
Group 2 contains 4434 units

Infection group 1 would deal defending group 2 182352 damage
Immune System group 2 would deal defending group 1 11875 damage
Immune System group 2 would deal defending group 2 11875 damage

Immune System group 2 attacks defending group 1, killing 2 units
Infection group 1 attacks defending group 2, killing 142 units
Immune System:
Group 2 contains 333 units
Infection:
Group 1 contains 784 units
Group 2 contains 4434 units

Infection group 1 would deal defending group 2 181888 damage
Immune System group 2 would deal defending group 1 8325 damage
Immune System group 2 would deal defending group 2 8325 damage

Immune System group 2 attacks defending group 1, killing 1 unit
Infection group 1 attacks defending group 2, killing 142 units
Immune System:
Group 2 contains 191 units
Infection:
Group 1 contains 783 units
Group 2 contains 4434 units

Infection group 1 would deal defending group 2 181656 damage
Immune System group 2 would deal defending group 1 4775 damage
Immune System group 2 would deal defending group 2 4775 damage

Immune System group 2 attacks defending group 1, killing 1 unit
Infection group 1 attacks defending group 2, killing 142 units
Immune System:
Group 2 contains 49 units
Infection:
Group 1 contains 782 units
Group 2 contains 4434 units

Infection group 1 would deal defending group 2 181424 damage
Immune System group 2 would deal defending group 1 1225 damage
Immune System group 2 would deal defending group 2 1225 damage

Immune System group 2 attacks defending group 1, killing 0 units
Infection group 1 attacks defending group 2, killing 49 units
Immune System:
No groups remain.
Infection:
Group 1 contains 782 units
Group 2 contains 4434 units
output