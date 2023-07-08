def solve(input = nil)
  input ||= read_input
  [Caves.parse(input).best_pressure, Caves.parse(input).best_with_elephant].map(
    &:total_pressure
  )
end

class Caves
  shape :valves

  PATTERN =
    /Valve (\w+) has flow rate=(\d+); tunnels? leads? to valves? ((\w+(, )?)*)/

  def best_pressure
    states = [State[30, "AA", 0, Set[], []]]
    states = possible_moves_from(states) until states.empty?

    best_state
  end

  def best_with_elephant
    states = [
      State[
        26,
        {
          elephant: {
            location: "AA",
            time_left: 0
          },
          person: {
            location: "AA",
            time_left: 0
          }
        },
        0,
        Set[],
        []
      ]
    ]
    states = possible_elephants_from(states) until states.empty?

    best_state
  end

  attr_reader :best_state
  def possible_moves_from(states)
    _debug(size: states.size, best_state:)
    states
      .flat_map { |state| moves_from_state(state) }
      .each do |state|
        @best_state ||= state
        @best_state = state if state.total_pressure > @best_state.total_pressure
      end
  end

  def possible_elephants_from(states)
    _debug(size: states.size, best_state:)
    states
      .flat_map { |state| elephants_from_state(state) }
      .each do |state|
        @best_state ||= state
        @best_state = state if state.total_pressure > @best_state.total_pressure
      end
  end

  def moves_from_state(state)
    moves = []
    return moves if state.time < 0

    # _debug("can travel to: ", valves[state.location].dists.keys)
    valves[state.location].dists.each do |tunnel, dist|
      new_time = state.time - dist
      new_pressure = state.total_pressure + (valves[tunnel].rate * new_time)

      next unless new_time > 0
      next if state.opened.include?(tunnel)

      next_state =
        State[
          new_time,
          tunnel,
          new_pressure,
          state.opened + [tunnel],
          state.trace + ["-->#{tunnel}(#{new_pressure.to_s.rjust(6, " ")})"]
        ]

      # _debug(state:)
      moves << next_state
    end

    moves
  end

  def elephants_from_state(state)
    return [] if state.location.nil?

    elephant_time_left = state.location.dig(:elephant, :time_left)
    person_time_left = state.location.dig(:person, :time_left)

    if elephant_time_left > state.time && person_time_left > state.time
      return []
    elsif elephant_time_left < person_time_left
      move_elephant(state)
    else
      move_person(state)
    end
  end

  def move_person(state)
    move_operator(:person, :elephant, state)
  end

  def move_elephant(state)
    move_operator(:elephant, :person, state)
  end

  # todo: use a memoized recursive solution that solves for location and visited
  # and adds the time to the remaining time times all unvisited.
  # something like def fastest_move(time, visited, mover, stayer) then mover moves
  # and if it is still less time than stayer moves again or else stayer becomes mover
  # but either way it's a recursive call and hopefully there is some use of the memo
  def move_operator(mover, stayer, state)
    moves = []
    return moves if state.time < 0

    time_spent = state.location.dig(mover, :time_left)
    time_of_move = state.time - time_spent

    return [] unless time_of_move > 0

    valves[state.location.dig(mover, :location)].dists.each do |tunnel, dist|
      next if state.opened.include?(tunnel)

      pressure_opened = valves[tunnel].rate
      time_of_open = time_of_move - dist
      new_pressure = state.total_pressure + (pressure_opened * time_of_open)

      next if time_of_open < 0
      if best_state &&
           possible_pressure(new_pressure, time_of_open, tunnel, state.opened) <
             best_state.total_pressure
        next
      end

      next_state =
        State[
          time_of_move,
          state.location.merge(
            { mover => { location: tunnel, time_left: dist } },
            {
              stayer => {
                location: state.location.dig(stayer, :location),
                time_left: state.location.dig(stayer, :time_left) - time_spent
              }
            }
          ),
          new_pressure,
          state.opened + [tunnel]
          # state.trace +
          #   [
          #     "#{mover.to_s.ljust(8)}/#{state.location.dig(mover, :location)}-->#{tunnel}" \
          #       "(#{new_pressure.to_s.rjust(6, " ")})",
          #     "stay(#{stayer.to_s.ljust(8)}), pressure(#{new_pressure.to_s.ljust(4)}), " \
          #       "time(#{time_of_move.to_s.ljust(2)}/#{time_of_open.to_s.ljust(2)}), opened(#{state.opened.join(", ")})"
          #   ]
        ]

      # _debug(state:)
      moves << next_state
    end

    moves
  end

  def possible_pressure(total_pressure, time, moving_to, opened)
    leftover_pressures =
      valves
        .filter { |name, _v| !opened.include?(name) && name != moving_to }
        .map(&:second)
        .map(&:rate)
        .sum

    total_pressure + (leftover_pressures * time)
  end

  class << self
    def parse(text)
      valves =
        text
          .scan(PATTERN)
          .map do |name, rate, valves, *_rest|
            Valve.new(name: name, rate: rate.to_i, tunnels: valves.split(", "))
          end
          .hash_by(&:name)

      valves.values.each { |it| it.dists(valves) }
      new(valves:)
    end
  end

  class Valve
    shape :name, :rate, :tunnels

    def dist_to_tunnel(tunnel)
      dists[tunnel]
    end

    def dists(tunnel_map = nil)
      return @dists if @dists
      raise "No tunnel map" unless tunnel_map

      cursors = [name]
      dists = {}
      dist = 0

      until cursors.empty?
        dist += 1
        cursors =
          cursors.flat_map do |cursor|
            dists[cursor] = dist
            tunnel_map[cursor].tunnels.reject { |it| dists[it] }
          end
      end

      @dists =
        dists
          .reject { |k, _v| tunnel_map[k].rate.zero? }
          .reject { |k, _v| k == name }
    end
  end

  State = Struct.new(:time, :location, :total_pressure, :opened, :trace)
end
