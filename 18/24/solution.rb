
$debug = false

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

  def select_target(targets)
    return @target = nil if targets.empty?

    # todo tie breaker
    @target = targets.sort_by { |target|
      [-damage_to(target), -target.effective_power, -target.initiative]
    }

    print_target_selection(targets)

    @target = @target.first
    targets.delete(@target)
  end

  def damage_to(target = nil)
    target ||= @target

    return 0 if target.nil?

    if target.weaknesses.include?(attack_type)
      effective_power * 2
    elsif target.immunities.include?(attack_type)
      0
    else
      effective_power
    end
  end

  def perform_attack
    @target.units -= residual
  end

  def residual
    damage_to / (@target&.hp || 1)
  end

  def print_target_selection(targets)
    return $debug unless $debug

    targets.each { |t|
      puts("#{type == :infection ? "Infection" : "Immune System"} group #{index + 1} would deal defending group #{t.index + 1} #{damage_to(t)} damage")
    }
  end
end

class Battle
  def initialize(immune_system, infection, boost)
    @immune_system = immune_system
    @infection = infection
    @boost = boost
  end

  def deep_clone
    self.class.new(
      @immune_system.map(&:clone),
      @infection.map(&:clone),
      @boost,
    )
  end

  def boost(b)
    @boost = b
    self
  end

  def solve
    [deep_clone.battle, deep_clone.save_reindeer]
  end

  def save_reindeer
    @boost = 1

    until deep_clone.reindeer_win?
      @boost += 1
      puts "Trying boost #{@boost}"
    end

    remaining_reindeer
  end

  def reindeer_win?
    remaining_reindeer > 0
  end

  def remaining_reindeer
    boosted = deep_clone
    boosted.battle
    boosted.immune_system_units
  end

  def debug
    @immune_system.map(&:attack) + @infection.map(&:attack)
  end

  def immune_system_units
    @immune_system.map(&:units).sum
  end

  def battle
    @immune_system.each { |group| group.attack += @boost }
    until defeat?
      print_status && puts

      fight
    end

    print_status
    [@immune_system, @infection].flat_map { |groups| groups.map(&:units) }.sum
  end

  def destroy_if_deadlocked
    # If we're deadlocked just remove everythig because at least then
    # we'll end the loop and the caller will think there's no reindeer left
    if deadlocked?
      @immune_system = []
      @infection = []
    end
  end

  def deadlocked?
    all_groups.all? { |group| group.residual == 0 }
  end

  def fight
    select_targets
    puts if $debug

    destroy_if_deadlocked
    attack
  end

  def select_targets
    # Sort by also makes a copy
    inf_targets = @immune_system.sort_by(&:index)
    is_targets = @infection.sort_by(&:index)

    inf_groups.each_with_index { |group|
      group.select_target(inf_targets)
    }
    is_groups.each_with_index { |group|
      group.select_target(is_targets)
    }
  end

  def attack
    all_groups.sort_by { |group| -group.initiative }.each { |group|
      print_attack(group)
      attack_for(group)
    }
  end

  def attack_for(group)
    # Group might have been defeated since we started attacking
    return unless all_groups.include?(group)
    return unless group.target

    group.perform_attack

    return if group.target.units > 0

    defeat(group.target)
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

  def defeat?
    @immune_system.empty? || @infection.empty?
  end

  ############################################################
  # Printing
  ############################################################
  def print_attack(group)
    return $debug unless $debug
    return unless all_groups.include?(group) && all_groups.include?(group.target)

    killed = [group.damage_to / group.target.hp, group.target.units].min
    puts(
      (group.type == :infection ? "Infection" : "Immune System") +
      " group #{group.index + 1} attacks defending " +
      "group #{group.target.index + 1}, killing " +
      "#{killed} unit" +
      (killed == 1 ? "" : "s")
    )
  end


  def print_status
    return $debug unless $debug

    puts("Immune System:")
    if @immune_system.empty?
      puts("No groups remain.")
    end

    @immune_system.each_with_index { |group|
      puts("Group #{group.index + 1} contains #{group.units} units")
    }

    puts("Infection:")
    if @infection.empty?
      puts("No groups remain.")
    end
    @infection.each_with_index { |group|
      puts("Group #{group.index + 1} contains #{group.units} units")
    }
  end

  def self.parse(text)
    immune, infection = text.split("\n\n")
      .map { |block| [block.split("\n").first[...-1].downcase.to_sym, block.split("\n").drop(1)] }
      .map { |type, block| block.each_with_index.map { |line, idx| parse_group(type, line, idx) }}

    new(immune, infection, 0)
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
  # puts Battle.parse(@example_input).battle
  puts Battle.parse(@example_input).solve
end

def test_boost
  puts Battle.parse(@example_input).boost(1570).battle
end

def solve
  puts Battle.parse(@input).solve
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
