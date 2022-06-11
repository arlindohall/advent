
class Hasher
  def initialize(input)
    @input = input
    @index = 0
    @chars = []
  end

  def index
    @index
  end

  def reset
    @chars = []
    @index = 0
  end

  def password
    while @chars.length < 8
      next_character
    end

    @chars.join
  end

  def stronger_password
    @chars = 8.times.map{nil}.to_a
    while !@chars.all?
      next_secure_character
    end

    @chars.join
  end

  def password_so_far
    @chars.join
  end

  private

    def valid_index?
      index = get_password_index

      not_set?(index) && in_bounds?(index) && index.to_i
    end

    def not_set?(index)
      @chars[index.to_i].nil?
    end

    def in_bounds?(index)
      %w(0 1 2 3 4 5 6 7).include?(index)
    end

    def next_character
      while !first_five_zeros? do
        if @index % 100000 == 0
          puts "Hashing: #{@index}"
        end
        @index += 1
      end
      puts "Interesting has at index #{@index}, #{hash}"

      ch = get_password_char
      @chars << ch

      @index += 1
    end

    def next_secure_character
      while !first_five_zeros? do
        if @index % 100000 == 0
          puts "Hashing: #{@index}"
        end
        @index += 1
      end
      puts "Interesting has at index #{@index}, #{hash}"

      if index = valid_index?
        @chars[index] = get_password_secure_char
      end

      @index += 1
    end

    def hash
      Digest::MD5.hexdigest("#{@input}#{@index}")
    end

    def first_five_zeros?
      hash.start_with?("00000")
    end

    def get_password_char
      hash.chars[5]
    end

    def get_password_index
      hash.chars[5]
    end

    def get_password_secure_char
      hash.chars[6]
    end
end

@hasher = Hasher.new('abc')