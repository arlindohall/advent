class Array
  def without(x)
    reject { |v| v == x }
  end

  def without!(x)
    delete(x)
    self
  end

  def with(x)
    self + [x]
  end

  def second
    self[1]
  end
  def third
    self[2]
  end
  def fourth
    self[3]
  end
  def fifth
    self[4]
  end
  def sixth
    self[5]
  end

  def product
    reduce(&:*)
  end

  def hash_by
    collect { |v| [yield(v), v] }.to_h
  end

  def hash_by_value
    collect { |v| [v, yield(v)] }.to_h
  end

  def sub_map
    map { |item| item.map { |sub_item| yield(sub_item) } }
  end

  def matrix_rotate(times = 1)
    return self if times % 4 == 0

    transpose.map { |row| row.reverse }.matrix_rotate(times - 1)
  end

  def matrix_multiply(other)
    self.rows.map { |r| other.columns.map { |c| r.zip(c).map(&:product).sum } }
  end

  def dim
    return [size] unless first.is_a?(Array)

    raise "Not a matrix" unless all? { |row| row.size == first.size }

    first.dim.with(size)
  end

  def rows
    self.dup
  end

  def columns
    transpose
  end

  def to_vector
    map { |i| [i] }
  end

  def count_values
    group_by(&:itself).transform_values(&:count)
  end

  def shape
    dim.join("x").to_s
  end

  def median
    sort[size / 2]
  end
end

class Hash
  def without(x)
    reject { |k, v| k == x }.to_h
  end

  def without!(x)
    delete(x)
    self
  end
end

class Vector
  def self.[](*ary)
    ary.to_vector
  end
end
