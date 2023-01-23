def solve
  SubmarineScan
    .new(read_input)
    .then { |scan| [scan.num_increases, scan.num_triplet_increases] }
end

class SubmarineScan < Struct.new(:text)
  def num_increases
    increases.count
  end

  def num_triplet_increases
    triplet_increases.count
  end

  private

  def triplet_increases
    triplets.filter { |first, second| first.sum < second.sum }
  end

  def increases
    pairs.filter { |first, second| first < second }
  end

  def pairs
    numbers.each_cons(2)
  end

  def triplets
    windows.each_cons(2)
  end

  def numbers
    text.split.map(&:to_i)
  end

  def windows
    @windows ||= numbers.each_cons(3)
  end
end
