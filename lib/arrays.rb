
class Object
  def exclude?(value)
    !include?(value)
  end

  def plop
    puts self
    self
  end

  def plopp
    p self
    self
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