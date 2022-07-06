
class MemoryBank
  def initialize(banks)
    @banks = banks.clone
  end

  def find_cycle
    @history = {}
    while !seen_before?
      record_current_config
      redistribute
    end

    [@history.size, @history.size - @history[@banks]]
  end

  def seen_before?
    @history.include?(@banks)
  end

  def record_current_config
    @history[@banks.clone] = @history.size
  end

  def redistribute
    spread(@banks.index(@banks.max))
  end

  def spread(largest)
    to_spread, i, @banks[largest] = @banks[largest], largest, 0
    to_spread.times do
      i += 1
      i %= @banks.length
      @banks[i] += 1
      to_spread -= 1
    end
  end
end

@example = [0, 2, 7, 0]
@input = %w(14 0 15 12 11 11 3 5 1 6 8 4 9 1 8 4).map(&:to_i)