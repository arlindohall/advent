

Password = Struct.new(:string)
class Password
  def digits
    @digits ||= Digits.new(string.chars)
  end

  def next
    @next ||= find_next
  end

  def find_next
    pass = digits.increment.to_password
    until pass.digits.allowed?
      pass = pass.digits.increment.to_password
    end
    pass
  end
end

Digits = Struct.new(:digits)
class Digits
  BANNED_CHARS = %w(i l o)
  CHARS_BEFORE_BANNED_CHARS = %w(h k n)

  def increment
    if disallowed?
      corrected
    else
      safe_increment
    end
  end

  def safe_increment
    dig = digits.clone
    index = dig.length-1
    carry = false

    while index >= 0
      inc, carry = self.next(dig[index])
      dig[index] = inc

      if !carry
        break
      end

      index -= 1
    end

    if carry
      dig = dig.shift('a')
    end

    Digits.new(dig)
  end

  def to_password
    Password.new(digits.join)
  end

  def numbers
    @numbers ||= digits.map{|d| d.unpack('U').first}
  end

  def allowed?
    contains_pairs? && contains_run?
  end

  def contains_pairs?
    first_pair && Digits.new(digits[(first_pair+2)..]).first_pair
  end

  def first_pair
    for i in 0..(digits.length-2)
      if digits[i] == digits[i+1]
        return @first_pair ||= i
      end
    end
    false
  end

  def contains_run?
    for i in 0..(digits.length-3)
      if numbers[i+1] == numbers[i] + 1 &&
          numbers[i+2] == numbers[i] + 2
        return true
      end
    end

    false
  end

  def disallowed?
    digits.map do |d|
      BANNED_CHARS.include? d
    end.any?
  end

  def corrected
    one_digit, _ = self.next(digits[highest_banned])
    Digits.new(
      valid_head + [one_digit] + corrected_tail
    )
  end

  def corrected_tail
    (digits.size - highest_banned - 1).times.map{'a'}
  end

  def valid_head
    digits[0...highest_banned]
  end

  def highest_banned
    @highest_banned ||= BANNED_CHARS.map do |ch|
      digits.index(ch)
    end.filter{|x| x}.min
  end

  def next char
    if CHARS_BEFORE_BANNED_CHARS.include? char
      [[char.unpack('U').first + 2].pack('U'), false]
    elsif char == 'z'
      ['a', true]
    else
      [[char.unpack('U').first + 1].pack('U'), false]
    end
  end
end
