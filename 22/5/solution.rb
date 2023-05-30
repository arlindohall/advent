def solve =
  read_input(strip: false).then do |it|
    [Crates.parse(it).tops, Crates.parse(it).tops_order]
  end

class Crates
  shape :configuration, :instructions

  def tops
    update! until instructions.empty?

    configuration.map(&:last).join
  end

  def tops_order
    update_order! until instructions.empty?

    configuration.map(&:last).join
  end

  def update!
    count, src, dest = instructions.shift
    src, dest = src.pred, dest.pred

    count.times { configuration[dest] << configuration[src].pop }
  end

  def update_order!
    count, src, dest = instructions.shift
    src, dest = src.pred, dest.pred

    configuration[dest] += configuration[src].pop(count)
  end

  def self.parse(text)
    crates, instructions = text.split("\n\n")
    configuration =
      crates
        .split("\n")
        .reverse
        .drop(1)
        .reverse
        .map { |row| row.chars.each_slice(4).map(&:second) }
        .transpose
        .map(&:reverse)
        .map { |column| column.reject { |ch| ch.match(/\s+/) } }

    instructions =
      instructions.scan(/move (\d+) from (\d+) to (\d+)/).sub_map(&:to_i)

    new(configuration:, instructions:)
  end
end
