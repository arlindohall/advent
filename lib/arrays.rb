
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