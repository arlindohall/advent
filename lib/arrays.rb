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

  def second
    self[1]
  end
  def third
    self[2]
  end
  def fourth
    self[3]
  end
  def fifth
    self[4]
  end
  def sixth
    self[5]
  end

  def product
    reduce(&:*)
  end

  def hash_by
    collect { |v| [yield(v), v] }.to_h
  end

  def hash_by_value
    collect { |v| [v, yield(v)] }.to_h
  end

  def sub_map
    map { |item| item.map { |sub_item| yield(sub_item) } }
  end

  def matrix_rotate(times = 1)
    return self if times % 4 == 0

    transpose.map { |row| row.reverse }.matrix_rotate(times - 1)
  end

  def matrix_multiply(other)
    self.rows.map { |r| other.columns.map { |c| r.zip(c).map(&:product).sum } }
  end

  def dim
    return [size] unless first.is_a?(Array)

    raise "Not a matrix" unless all? { |row| row.size == first.size }

    first.dim.with(size)
  end

  def rows
    self.dup
  end

  def columns
    transpose
  end

  def to_vector
    map { |i| [i] }
  end

  def to_linked_list
    CyclicalLinkedList.new(self)
  end

  def count_by(&block)
    group_by(&block).transform_values(&:size)
  end

  def count_values
    group_by(&:itself).transform_values(&:count)
  end

  def shape
    dim.join("x").to_s
  end

  def median
    sort[size / 2]
  end

  def determinant
    if dim == [2, 2]
      self[0][0] * self[1][1] - self[0][1] * self[1][0]
    elsif dim == [3, 3]
      self[0][0] * (self[1][1] * self[2][2] - self[1][2] * self[2][1]) -
        self[0][1] * (self[1][0] * self[2][2] - self[1][2] * self[2][0]) +
        self[0][2] * (self[1][0] * self[2][1] - self[1][1] * self[2][0])
    else
      raise "Don't know how to take det of #{shape} matrix"
    end
  end
end

class CyclicalLinkedList
  class InfiniteLoop < StandardError
  end

  attr_reader :size

  def initialize(list = nil)
    list = [] if list.nil?
    @head = nil
    @size = 0
    list.each { |it| insert(it) }
  end

  def insert(item)
    @size += 1

    if @head.nil?
      @head = Node[item]
      @head.next_node = @head
      @head.prev_node = @head
      return
    end

    node = Node[item, @head.next_node]

    before, after = @head, @head.next_node

    before.next_node = node
    node.prev_node = before
    node.next_node = after
    after.prev_node = node

    @head = node
  end

  def remove(item)
    @size -= 1

    start = @head

    until @head.item == item
      @head = @head.next_node
      riase InfiniteLoop, "Item not found" if @head == start
    end

    before = @head.prev_node
    after = @head.next_node

    before.next_node = after
    after.prev_node = before

    @head = before

    item
  end

  def scan(item = nil, &block)
    matcher = block_given? ? block : ->(x) { x == item }

    start = @head

    until block.call(@head.item)
      @head = @head.next_node
      raise InfiniteLoop, "Item not found" if @head == start
    end

    @head.item
  end

  def skip(n)
    (n % @size).times { @head = @head.next_node }

    @head.item
  end

  def each(&block)
    return self if @head.nil?

    guard = 0

    tap do
      cursor = @head
      loop do
        yield cursor.item
        cursor = cursor.next_node
        break if cursor == @head
        raise InfiniteLoop, "More items than list size" if (guard += 1) > size
      end
    end
  end

  def to_s
    "(#{to_a.join("; ")})"
  end

  def inspect
    "LinkedList<#{to_s}>"
  end

  def to_a
    a = []
    each { |item| a << item }
    a
  end

  class Node
    shape :item, :next_node, :prev_node
    attr_accessor :item, :next_node, :prev_node

    class << self
      def [](item, next_node = nil)
        new(item:, next_node:)
      end
    end
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

class Vector
  def self.[](*ary)
    ary.to_vector
  end
end

class PriorityQueue
  def initialize(&block)
    @key = block
    @hash = Hash.new { |h, k| h[k] = [] }
  end

  def push(item)
    key = @key.call(item)
    @max ||= key
    @max = key if key > @max

    @hash[key] << item
  end

  # Destructive so be careful
  def +(items)
    items.each { |it| push(it) }
    self
  end

  def shift
    value = @hash[@max].shift

    if @hash[@max].empty?
      @hash.delete(@max)
      @max = @hash.keys.max
    end

    value
  end

  def pop
    value = @hash[@max].pop

    if @hash[@max].empty?
      @hash.delete(@max)
      @max = @hash.keys.max
    end

    value
  end

  def empty?
    @hash.empty?
  end

  def size
    @hash.values.map(&:size).sum
  end
end
