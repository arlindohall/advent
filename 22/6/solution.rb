def solve =
  Stream
    .new(text: read_input)
    .then { |it| [it.start_of_packet, it.start_of_message] }

class Stream
  shape :text

  def start_of_packet
    start(4)
  end

  def start_of_message
    start(14)
  end

  def start(n)
    text.size.times do |i|
      return i + n if text[i..i + n - 1].chars.uniq.size == n
    end

    raise "No start found"
  end
end
