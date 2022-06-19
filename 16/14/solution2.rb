
require 'digest'

Key = Struct.new(:key, :index, :fiver_key, :fiver_index)

class KeyGenerator
  def initialize(source)
    @source = source
    @hash_number = 0
    @last_thousand_hashes = []
    @keys = []
  end

  def key_number(n)
    until confirmed_hash_location?(n-1)
      add_keys
      puts "hash_number=#{@hash_number}"
    end
    @keys[n-1]
  end

  def confirmed_hash_location?(n)
    @keys.size > n && @keys[n].index + 1000 < @hash_number
  end

  def add_keys
    add_next_hash

    while !current_hash.key.five_in_a_row?
      add_next_hash
    end

    ch = current_hash.key.five_in_a_row?

    last_thousand_hashes.each do |hash|
      if hash_is_key?(hash, ch) && not_found_yet?(hash)
        hash.fiver_index = @hash_number-1
        hash.fiver_key = hash_of("#{@source}#{@hash_number-1}")
        @keys << hash
      end
    end

    @keys = @keys.sort_by(&:index)
  end

  def hash_is_key?(hash, character)
    hash.key.three_in_a_row? == character
  end

  def not_found_yet?(key)
    !@keys.map(&:key).map{|k| k == key}.any?
  end

  def last_thousand_hashes
    @last_thousand_hashes[...-1]
  end

  def keys
    @keys
  end

  def add_next_hash
    @last_thousand_hashes << calculate_next_hash
    if @last_thousand_hashes.size > 1001
      @last_thousand_hashes = @last_thousand_hashes.drop(1)
    end
  end

  def calculate_next_hash
    @hash_number += 1
    stretch(@hash_number-1)
  end

  def stretch(n)
    hash = hash_of("#{@source}#{n}")
    2016.times do
      hash = hash_of(hash)
    end

    Key.new(hash, n)
  end

  def hash_of(text)
    Digest::MD5.hexdigest(text)
  end

  def current_hash
    @last_thousand_hashes.last
  end
end

class String
  def n_in_a_row?(n)
    found = 0
    current = 0
    char = self.chars.first
    while current < size
      if self[current] == char
        found += 1
      else
        found = 1
      end

      return char if found == n && self[current] == char
      char = self[current]

      current += 1
    end

    false
  end

  def five_in_a_row?
    n_in_a_row?(5)
  end

  # Only count the first pair of three
  def three_in_a_row?
    n_in_a_row?(3)
  end
end

@example = KeyGenerator.new("abc")
@input = KeyGenerator.new("yjdafjpo")