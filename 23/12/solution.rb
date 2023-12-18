$_debug = false

def solve(input = read_input) =
  SpringRecord
    .new(input)
    .then { |sr| [sr.arrangements, sr.unfolded_arrangements] }

class SpringRecord
  def initialize(text)
    @text = text
  end

  def arrangements
    spring_rows.map { |row| row.configurations }.sum
  end

  def unfolded_arrangements
    unfolded_spring_rows.map { |row| row.configurations }.sum
  end

  def spring_rows
    @text.split("\n").map { |row| SpringRow.new(row) }
  end

  def unfolded_spring_rows
    @text.split("\n").map { |row| FiveFoldRow.new(row) }
  end
end

class SpringRow
  def initialize(line)
    @line = line
  end

  def record
    @line.split.first
  end

  def groups
    @line.split.second.split(",").map { |number| number.to_i }
  end

  def configurations
    ConfigurationCount.new(record.chars, groups).call
  end
end

class FiveFoldRow
  def initialize(line)
    @line = line
  end

  def record
    ([@line.split.first] * 5).join("?")
  end

  def groups
    @line.split.second.split(",").map { |number| number.to_i } * 5
  end

  def configurations
    ConfigurationCount.new(record.chars, groups).call
  end
end

class Memo
  def self.has?(r, g)
    @memo ||= {}
    @memo[[r, g]]
  end

  def self.recall(r, g)
    @memo[[r, g]]
  end

  def self.store(r, g, v)
    @memo[[r, g]] = v
  end
end

class ConfigurationCount
  def initialize(record, groups)
    @record = record
    @groups = groups
  end

  def call
    return Memo.recall(@record, @groups) if Memo.has?(@record, @groups)

    count_groups
      .tap { |count| Memo.store(@record, @groups, count) }
      .tap do |count|
        # _debug("calling configuration", record: @record, groups: @groups, count:)
      end
  end

  def count_groups
    return 1 if @record.empty? && @groups.empty?
    return 0 if @record.empty?
    return 0 if impossible?

    ways_to_build_group + ways_to_build_gap
  end

  def ways_to_build_group
    return 0 unless can_make_group?

    count(minus_group, @groups.drop(1))
  end

  def ways_to_build_gap
    return 0 unless can_make_gap?

    count(minus_gap, @groups)
  end

  def minus_gap
    @record.drop(1).drop_while { |char| char == "." }
  end

  def minus_group
    @record.drop(@groups.first + 1) # Also drop the space after
  end

  def can_make_group?
    return false if @groups.empty?
    return false if @groups.first > @record.size
    return false if @record[@groups.first] == "#"

    @record.first(@groups.first).all? { |ch| ch == "?" || ch == "#" }
  end

  def impossible?
    @groups.sum > @record.size
  end

  def can_make_gap?
    first != "#"
  end

  def first
    @record[0]
  end

  def count(record, groups)
    ConfigurationCount.new(record, groups).call
  end
end
