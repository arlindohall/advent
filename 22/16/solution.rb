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

  def move_operator(mover, stayer, state)
    moves = []
    return moves if state.time < 0

    time_spent = state.location.dig(mover, :time_left)
    pressure_opened = valves[state.location.dig(mover, :location)].rate

    new_time = state.time - time_spent
    new_pressure = state.total_pressure + (pressure_opened * state.time)

    return [] unless new_time > 0

    # _debug(
    #   "#{mover} can travel to: ",
    #   valves[state.location.dig(mover, :location)].dists.keys
    # )
    valves[state.location.dig(mover, :location)].dists.each do |tunnel, dist|
      next if state.opened.include?(tunnel)

      next_state =
        State[
          new_time,
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
          state.opened + [tunnel],
          state.trace +
            [
              "#{mover.to_s.ljust(8)}/#{state.location.dig(mover, :location)}-->#{tunnel}" \
                "(#{new_pressure.to_s.rjust(6, " ")})",
              "stay(#{stayer.to_s.ljust(8)}), pressure(#{new_pressure.to_s.ljust(4)}), " \
                "time(#{new_time.to_s.ljust(2)}), opened(#{state.opened.join(", ")})"
            ]
        ]

      # _debug(state:)
      moves << next_state
    end

    return clear_out(state) if moves.empty?

    moves
  end

  def clear_out(state)
    return [] if state.location.nil?

    elephant_time = state.location.dig(:elephant, :time_left)
    person_time = state.location.dig(:person, :time_left)

    elephant_location = state.location.dig(:elephant, :location)
    person_location = state.location.dig(:person, :location)

    elephant_pressure =
      valves[elephant_location].rate * (state.time - elephant_time)
    person_pressure = valves[person_location].rate * (state.time - person_time)

    total_pressure = state.total_pressure

    total_pressure += elephant_pressure if elephant_time < state.time
    total_pressure += person_pressure if person_time < state.time

    return [] if total_pressure == state.total_pressure

    [State[0, nil, total_pressure, state.opened, state.trace + ["cleared out"]]]
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
