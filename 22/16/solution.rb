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

  def best_with_elephant
    best_pressure(26, Set[], ["AA", 0], ["AA", 0])
  end

  memoize def best_pressure(time, visited, mover, stayer)
    return -1 if time < mover.second || time < stayer.second

    @i ||= 0
    @i += 1
    if @i % 10_000 == 0
      _debug(
        "working with memo size",
        memo_size: @__memo[:best_pressure].size,
        time:,
        visited:,
        mover:,
        stayer:
      )
    end
    # _debug(time:, visited:, mover:, stayer:) if @i < 100

    mover_loc, mover_time = mover
    stayer_loc, stayer_time = stayer

    moves = valves[mover_loc].dists.keys - visited.to_a

    if moves.empty?
      r = remaining(time, visited - [stayer_loc, mover_loc])

      r += valves[stayer_loc].rate * (time - stayer_time)
      r += valves[mover_loc].rate * (time - mover_time)

      return r
    end

    new_stayer_time = stayer_time - mover_time
    max = 0

    moves.each do |tunnel|
      dist = valves[mover_loc].dists[tunnel]
      new_mover_loc = tunnel
      new_mover_time = dist

      mv = [new_mover_loc, new_mover_time]
      st = [stayer_loc, new_stayer_time]
      mv, st = st, mv if new_mover_time > new_stayer_time

      pressure = best_pressure(time - mover_time, visited + [tunnel], mv, st)

      mover_rate = valves[mover_loc].rate
      time_to_next_move = mv.second
      pressure += time_to_next_move * mover_rate

      max = pressure if pressure > max
    end

    max
  end

  def remaining(time, visited)
    visited.map { |v| valves[v].rate * time }.sum
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
