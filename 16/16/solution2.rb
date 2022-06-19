

class Data
  def initialize(text, fill)
    @text = text
    @fill = fill
  end

  <<-DOC
  To solve this there must be a way to calculate checksum without
  building the whole string. So we can find the number of times we
  need to double and then transform the existing checksum that many
  times
  
  The checksum of "1" is "1" and of "0" is "0", because odd
  
  If we doulbe "1", we get "100", whose checksum is still odd and "100"
  
  So it's important that we only care about the first "size" of
  the input to get its checksum.
  
  So it's important that the checksum of the "1" shows up in "100"
  
  Also, we notice that if we want to checksum "111111" vs "111111".fill(8)
  we would start with the checksum of "111111" which is "111", since all the
  same, and if we fill(8) we get "1111110000000", whose checksum is "111" then
  some transform, which in this case is "1"s for the rest of the string.

  I wrote an example function to predict the checksum length, it's just the
  first odd number you get when successive divisions by 2. Interestingly,
  I think there's a way to also predict the checksum by the checksum of n/2
  as well, not just the checksum length.

  def div_by_2(i)
    while i.even?
      i = i / 2
    end
  end

  def checksum_length(i)
    return i if i.odd?
    return checksum_length(i/2)
  end

  This latter recursive definition is much more interesting, because I think we
  can get a recursive definition of the checksum itself.

  The checksum of length n is the first n characters of the fully expanded if it's
  degree-0 even (or odd). If it's degree-1 even (divisible by 2 once), it's the first
  n/2 characters of the 1st checksum. Etc. So the degree of the checksum used is the
  number of times div by 2 the number is. So...

  def oddly(i)
    times = 0
    while i.even?
      times += 1
      i = i/2
    end
    times
  end

  So the characters of the checksum are the same for all checksums of degree N. So the
  characters of the checksum for 12 are six characters of degree 2, while for 4 it's 1
  character of degree 2.

  Then the answer we're looking for is the first 17 digits of the 21st degree checksum.
  We know the 17 digits of the 1st degree checksum. 

  ## Solution?

  So the first digit of the Nth degree checksum is 1 if the number of 1s in the first
  2^n digits of the fully expanded data is even, 0 if odd.

  ## Solution, try 2
  def sum
    1.upto(desired_length).map{|i|i-1}.map do |i|
      get_digit(i)
    end
  end

  def degree
    if @degree.nil?
      @degree, @desired_length = oddly(@data.size)
    end
    @degree
  end

  def desired_length
    if @desired_length.nil?
      @degree, @desired_length = oddly(@data.size)
    end
    @desired_length
  end

  def get_digit(ith)
    sum = 0
    for i in word_size*ith...(word_size+1)*ith
      if @data[i] == "1"
        sum += 1
      end
    end

    sum.even? ? "1" : "0"
  end

  ## Solution, try 3

  So the number of 1s in the first N digits of the original expanded string are:

  If N < size_of_source
    ones_in(N, source)

  If N < size_of_source * 2
    ones_in(source) +
      0 + # <-- no ones in the middle padded zero
      zeros_in(source[...N-1-size_of_source]) # <-- flipped zeros are ones
  
  If N < size_of_source * 4
    ones_in_doubled(source) +
      0 +
      zeros_in(doubled[...N-1-size_of_doubled])

  ...
  ones_in_doubled(source) = ones_in(source) + zeros_in(source)

  zeros_in(source) = size - ones_in(source)
  DOC
  def checksum
    calculate_checksum_size

    (0...@checksum_size).map do |i|
      checksum_entry(i)
    end.join
  end

  def checksum_entry(i)
    count_ones(i*@word_size, (i+1)*@word_size-1).even? ? "1" : "0"
  end

  def count_ones(start, finish) # Inclusive
    # We're further down the recursion tree but only want to know about the
    # zeros on the right half, so ignore this
    return 0 if start > finish

    scale, midpoint = calculate_scale(finish)
    if midpoint.nil?
      # We are at the bottom of the recursion tree and can directly count
      # We may not know this until after we've calculated the scale
      return @text[start..finish].chars.filter{|ch| ch=="1"}.count
    end
    puts "Counting ones in [#{start},#{finish}] scale=#{scale} midpoint=#{midpoint}"

    count_ones(start, midpoint-1) + count_zeros(midpoint+1, finish)
  end

  def count_zeros(start, finish) # Inclusive
    puts "Counting zeros in [#{start}, #{finish}]"
    return 0 if start > finish
    count_ones(0, finish-start)
  end

  def calculate_scale(size)
    scale = @text.size
    midpoint = nil
    until scale >= size
      midpoint = scale + 1
      scale = scale * 2 + 1
    end
    [scale, midpoint]
  end

  def calculate_checksum_size
    checksum_size, word_size = @fill, 1
    until checksum_size.odd?
      checksum_size, word_size = checksum_size/2, word_size*2
    end
    @checksum_size, @word_size = checksum_size, word_size
  end
end

@example = Data.new("10000", 20)
@input = Data.new("11100010111110100", 272)

@part2 = Data.new("11100010111110100", 35651584)