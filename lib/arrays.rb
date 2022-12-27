
$debug = true

class Object
  def exclude?(value)
    !include?(value)
  end

  def non_arrays_caller
    caller.reject { |line| line.include?("advent/lib/arrays") }.first
  end

  def plop
    return self unless $debug
    puts non_arrays_caller
    puts self
    self
  end

  def plopp
    return self unless $debug
    puts non_arrays_caller
    p self
    self
  end

  def debug(*args, **kwargs)
    return unless $debug
    args.plopp unless args.empty?
    kwargs.plopp unless kwargs.empty?
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

  def sub_map
    map { |item| item.map { |sub_item| yield(sub_item) } }
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