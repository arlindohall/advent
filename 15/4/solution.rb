
require 'digest'

class AdventCoin
  def initialize(key)
    @key = key
  end

  def answer
    @number = 1
    until found_hash?
      increment
    end

    @number
  end

  def part2
    @number = 1
    until found_part2?
      increment
    end

    @number
  end

  def found_hash?
    Digest::MD5.hexdigest("#{@key}#{@number}").start_with?('00000')
  end

  def found_part2?
    Digest::MD5.hexdigest("#{@key}#{@number}").start_with?('000000')
  end

  def increment
    @number += 1
  end
end