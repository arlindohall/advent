
class Array
  def exclude?(value)
    !include?(value)
  end
end

class Hash
  def exclude?(key)
    !include?(key)
  end
end