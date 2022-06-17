
Configuration = Struct.new(:elevator, :microchips, :generators, :steps)
Elevator = Struct.new(:floor)
Microchip = Struct.new(:type, :floor)
Generator = Struct.new(:type, :floor)

class Configuration

  def <=>(configuration)
    # return -1 if less than, that is higher floors because higher comes first
    configuration.floors - self.floors
  end

  def floors
    microchips.map(&:floor).sum +
      generators.map(&:floor).sum
  end

  def shortest_path
    @@visited = Set.new
    @@queue = [self]
    while !@@queue.empty?
      process_configuration
    end

    @min
  end

  def possible_steps
    reachable_item_combinations
      .flat_map do |items|
        possible_floors.map do |floor|
          move_items(items, floor)
        end
      end
      .filter(&:valid?)
      .filter do |configuration|
        !visited?(configuration)
      end
  end

  def valid?
    1.upto(4).map do |floor|
      !exposed_microchips?(floor)
    end.all?
  end

  def winning?
    microchips.all?{|m| m.floor == 4} &&
      generators.all?{|g| g.floor == 4}
  end

  def better_than_winner?(step)
    return true if @min.nil?

    step.steps <= @min.steps
  end

  # private

    def process_configuration
      configuration = best_configuration

      update_winning(configuration)

      return if configuration.winning?

      configuration.possible_steps.each{|step| @@queue << step}
        # .filter{|step| better_than_winner?(step)}
    end

    def best_configuration
      @@queue.shift
    end

    def visited?(configuration)
      return true if @@visited.include?(configuration.unique_state)

      visit(configuration.unique_state)
      false
    end

    def visit(configuration)
      if @@visited.size % 10 == 0
        puts "Working with @@queue.size=#{@@queue.size}, steps=#{steps}, visited.size=#{@@visited.size}"
      end
      @@visited.add(configuration)
    end

    def unique_state
      [pairs, elevator.floor]
    end

    def pairs
      all_items.group_by(&:type)
        .values
        .map do |items|
          # Each pair's floor info only (pairs are interchangable)
          items.map(&:floor).sort
        end.sort
    end

    def all_items
      generators + microchips
    end

    def update_winning(configuration)
      return if !configuration.winning?

      puts "Winner: #{configuration}"
      @min ||= configuration
      if configuration.steps < @min.steps
        @min = configuration
      end
    end

    def exposed_microchips?(floor)
      return false if unprotected_microchips(floor).empty?

      unprotected_microchips(floor).any? && potent_generators(floor).any?
    end

    def unprotected_microchips(floor)
      @micro ||= {}
      @micro[floor] ||= microchips
        .filter{|m| m.floor == floor}
        .filter{|m| !potent_generators(floor).map(&:type).include?(m.type)}
    end

    def potent_generators(floor)
      @gen||= {}
      @gen[floor] ||= generators.filter{|m| m.floor == floor}
    end

    def reachable_item_combinations
      all_reachable_items.map{|ri| [ri]} + all_reachable_items.combination(2).to_a
    end

    def all_reachable_items
      @all_rechable_items ||= all_items_on_floor(elevator.floor)
    end

    def all_items_on_floor(floor)
      microchips.filter{|m| m.floor == floor} +
        generators.filter{|g| g.floor == floor}
    end

    def possible_floors
      case elevator.floor
      when 1
        [2]
      when 4
        [3]
      else
        [elevator.floor + 1, elevator.floor - 1]
      end
    end

    def move_items(items, floor)
      Configuration.new(
        Elevator.new(floor),
        move_microchips(items, floor),
        move_generators(items, floor),
        steps + 1,
      )
    end

    def move_generators(items, floor)
      generators - items +
        items.filter{|i| i.is_a?(Generator)}
          .map(&:clone)
          .map{|i| i.floor = floor; i}
    end

    def move_microchips(items, floor)
      microchips - items +
        items.filter{|i| i.is_a?(Microchip)}
          .map(&:clone)
          .map{|i| i.floor = floor; i}
    end
end

@example = Configuration.new(
  Elevator.new(1),
  [
    Microchip.new(:hydrogen, 1),
    Microchip.new(:lithium, 1),
  ],
  [
    Generator.new(:hydrogen, 2),
    Generator.new(:lithium, 3),
  ],
  0,
)

<<-DESCRIPTION
The first floor contains a promethium generator and a promethium-compatible microchip.
The second floor contains a cobalt generator, a curium generator, a ruthenium generator, and a plutonium generator.
The third floor contains a cobalt-compatible microchip, a curium-compatible microchip, a ruthenium-compatible microchip, and a plutonium-compatible microchip.
The fourth floor contains nothing relevant.
DESCRIPTION

@input = Configuration.new(
  Elevator.new(1),
  [
    Microchip.new(:promethium, 1),
    Microchip.new(:cobalt, 3),
    Microchip.new(:curium, 3),
    Microchip.new(:ruthenium, 3),
    Microchip.new(:plutonium, 3),
  ],
  [
    Generator.new(:promethium, 1),
    Generator.new(:cobalt, 2),
    Generator.new(:curium, 2),
    Generator.new(:ruthenium, 2),
    Generator.new(:plutonium, 2),
  ],
  0
)