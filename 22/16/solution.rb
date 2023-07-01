def solve =
  [
    Caves.parse(read_example).best_pressure,
    Caves.parse(read_example).best_with_elephant
  ]

class Caves
  shape :valves

  PATTERN =
    /Valve (\w+) has flow rate=(\d+); tunnels? leads? to valves? ((\w+(, )?)*)/

  def best_pressure
    states = [State[30, "AA", 0, Set[], []]]
    states = possible_moves_from(states) until states.empty?

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
