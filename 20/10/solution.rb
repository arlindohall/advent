
class Chain < Struct.new(:text)
  def voltages
    @voltages ||= text.strip.split.map(&:to_i).sort
  end

  def voltages_incl
    [0] + voltages + [voltages.max + 3]
  end

  # Stolen from https://www.reddit.com/r/adventofcode/comments/ka8z8x/comment/ghbc7np/?utm_source=share&utm_medium=web2x&context=3
  # I knew it had to be some kind of dynamic programming solution, and I figured
  # it would involve a memo of the inputs, but I wasn't sure what the relation to
  # F(N) -> F(N+1) would be...
  #
  # I guess the answer is "ways to get from N to SOL" is "ways to get from the things you can get to from N to SOL"
  #
  # Rather than think about removing values, think about including them.
  def possible_configurations
    depth_first(0)
  end

  def dag
    @dag ||= voltages_incl.map { |vlt| [vlt, (vlt+1..vlt+3).filter{ voltages_incl.include?(_1) }]}.to_h
  end

  def memo
    @memo ||= []
  end

  def depth_first(n)
    return memo[n] if memo[n]
    return 1 if dag[n].empty?

    memo[n] = dag[n].map { |vlt| depth_first(vlt) }.sum
  end
  
  def answer
    diff3 * diff1
  end

  def diff1
    jumps[1]
  end

  def diff3
    jumps[3]
  end

  def jumps
    @jumps ||= voltages
      .each_with_index.map do |vlt, idx|
        next if idx == voltages.size-1 # skip last
        voltages[idx+1] - vlt
      end.compact
      .then { |jumps| jumps << 3 ; jumps << 1 } # last adapter plus first (all contain '1')
      .group_by(&:itself)
      .transform_values(&:count)
  end
end

def example1
  %q-16 10 15 5 1 11 7 19 6 12 4-
end

def solve
  [Chain.new(read_input).answer, Chain.new(read_input).possible_configurations]
end