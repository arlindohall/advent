
$debug = true

class Object
  def exclude?(value)
    !include?(value)
  end

  def non_arrays_caller
    caller.reject { |line| line.include?("advent/lib/arrays") }.first
  end

  def plop(prefix = "")
    return self unless $debug
    puts non_arrays_caller
    puts non_arrays_caller.gsub(/./, "-")
    print prefix
    puts self
    self
  end

  def plopp(prefix = "")
    return self unless $debug
    puts non_arrays_caller
    puts non_arrays_caller.gsub(/./, "-")
    print prefix
    p self
    self
  end

  def debug(*args, **kwargs)
    return unless $debug
    args.plopp unless args.empty?
    kwargs.plopp unless kwargs.empty?
  end

  def only!
    assert_size!.first
  end

  def assert_size!(expected = 1)
    assert!(size == expected, "Expected size #{expected} but got #{size}")
  end

  def assert!(condition, message = "")
    tap {
      raise message unless condition
    }
  end
end

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

  def second  ; self[1] ; end
  def third   ; self[2] ; end
  def fourth  ; self[3] ; end
  def fifth   ; self[4] ; end
  def sixth   ; self[5] ; end

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

  def count_values
    group_by(&:itself).transform_values(&:count)
  end

  def shape
    return "#{size}x#{first.shape}" if first.is_a? Array

    size.to_s
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

class String
  def darken_squares
    gsub("#", "█").gsub(".", " ")
  end
end