$_debug = false

def solve =
  ReactorRobot.parse(read_input).then { |rr| [rr.only_50.size, rr.all.size] }

class ReactorRobot
  attr_reader :instructions
  def initialize(instructions)
    @instructions = instructions
  end

  def self.parse(text)
    new(instructions(text))
  end

  def self.instructions(text)
    text
      .split("\n")
      .map { |line| line.split(" ") }
      .map do |inst, area|
        Instruction.new(
          on?: inst == "on",
          area:
            area
              .split(",")
              .map { |axis| axis.split("=").last }
              .map { |axis| axis.split("..").map(&:to_i) }
        )
      end
  end

  def take(n)
    self.class.new(instructions.take(n))
  end

  def only_50
    box_group = BoxGroup.new
    instructions
      .filter { |ins| ins.in_50? }
      .each_with_index do |ins, idx|
        box_group = box_group.apply(ins)
        _debug(
          "Applying box",
          index: idx,
          count: box_group.count,
          size: box_group.size,
          total: instructions.size
        )
      end
    box_group
  end

  def all
    box_group = BoxGroup.new
    instructions.each_with_index do |ins, idx|
      box_group = box_group.apply(ins)
      _debug(
        "Applying box",
        index: idx,
        count: box_group.count,
        size: box_group.size,
        total: instructions.size
      )
    end
    box_group
  end
end

class Instruction
  attr_reader :on, :area
  alias_method :on?, :on
  def initialize(**params)
    @on = params[:on?]
    @area = params[:area]
  end

  def in_50?
    area.all? { |coord| coord.all? { |c| (-50..50).include?(c) } }
  end

  def to_box
    Box.new(x: area.first, y: area.second, z: area.third)
  end
end

class BoxGroup
  shape :boxes, boxes: []

  def apply(instruction)
    instruction.on? ? self + instruction.to_box : self - instruction.to_box
  end

  def size
    boxes.map(&:size).sum
  end

  def count
    boxes.count
  end

  def sort
    construct!(boxes.map(&:to_a).sort.map { |a| Box.from_a(a) })
  end

  def -(box)
    construct!(boxes.flat_map { |b| b - box })
  end

  def +(box)
    construct!(boxes.flat_map { |b| b - box } + [box])
  end

  def construct!(boxes)
    # raise "Invalid boxes" if boxes.any? { |b| intersect?(b, boxes.without(b)) }
    BoxGroup.new(boxes:)
  end

  def intersect?(box, boxes)
    boxes
      .filter { |b| box.intersect?(b) }
      .tap { |boxes| puts "Intersected: #{box.inspect}" if boxes.any? }
      .each { |b| puts "Intersecting boxes: #{b.inspect}" }
      .any?
  end
end

class Box
  shape :x, :y, :z

  def size
    (xmax - xmin + 1) * (ymax - ymin + 1) * (zmax - zmin + 1)
  end

  def -(box)
    intersect?(box) ? full_subtract(box) : [self]
  end

  def full_subtract(box)
    [
      [bot(:x, box), bot(:y, box), bot(:z, box)],
      [bot(:x, box), bot(:y, box), mid(:z, box)],
      [bot(:x, box), bot(:y, box), top(:z, box)],
      [bot(:x, box), mid(:y, box), bot(:z, box)],
      [bot(:x, box), mid(:y, box), mid(:z, box)],
      [bot(:x, box), mid(:y, box), top(:z, box)],
      [bot(:x, box), top(:y, box), bot(:z, box)],
      [bot(:x, box), top(:y, box), mid(:z, box)],
      [bot(:x, box), top(:y, box), top(:z, box)],
      [mid(:x, box), bot(:y, box), bot(:z, box)],
      [mid(:x, box), bot(:y, box), mid(:z, box)],
      [mid(:x, box), bot(:y, box), top(:z, box)],
      [mid(:x, box), mid(:y, box), bot(:z, box)],
      [mid(:x, box), mid(:y, box), top(:z, box)],
      [mid(:x, box), top(:y, box), bot(:z, box)],
      [mid(:x, box), top(:y, box), mid(:z, box)],
      [mid(:x, box), top(:y, box), top(:z, box)],
      [top(:x, box), bot(:y, box), bot(:z, box)],
      [top(:x, box), bot(:y, box), mid(:z, box)],
      [top(:x, box), bot(:y, box), top(:z, box)],
      [top(:x, box), mid(:y, box), bot(:z, box)],
      [top(:x, box), mid(:y, box), mid(:z, box)],
      [top(:x, box), mid(:y, box), top(:z, box)],
      [top(:x, box), top(:y, box), bot(:z, box)],
      [top(:x, box), top(:y, box), mid(:z, box)],
      [top(:x, box), top(:y, box), top(:z, box)]
    ].map { |list| Box.from_a(list) }.filter { |box| box.valid? }
  end

  def bot(axis, box)
    [send("#{axis}min"), [box.send("#{axis}min") - 1, send("#{axis}max")].min]
  end

  def mid(axis, box)
    [
      [send("#{axis}min"), box.send("#{axis}min")].max,
      [send("#{axis}max"), box.send("#{axis}max")].min
    ]
  end

  def top(axis, box)
    [[box.send("#{axis}max") + 1, send("#{axis}min")].max, send("#{axis}max")]
  end

  def ==(box)
    to_a == box.to_a
  end

  def intersect?(box)
    (intersect_x?(box) || box.intersect_x?(self)) &&
      (intersect_y?(box) || box.intersect_y?(self)) &&
      (intersect_z?(box) || box.intersect_z?(self))
  end

  def intersect_x?(box)
    xmin.between?(box.xmin, box.xmax) || xmax.between?(box.xmin, box.xmax)
  end

  def intersect_y?(box)
    ymin.between?(box.ymin, box.ymax) || ymax.between?(box.ymin, box.ymax)
  end

  def intersect_z?(box)
    zmin.between?(box.zmin, box.zmax) || zmax.between?(box.zmin, box.zmax)
  end

  def valid?
    xmin <= xmax && ymin <= ymax && zmin <= zmax
  end

  %i[x y z].each do |axis|
    define_method("#{axis}min") { send(axis).first }
    define_method("#{axis}max") { send(axis).second }
  end

  def to_a
    [x.dup, y.dup, z.dup]
  end

  def self.from_a(array)
    Box.new(x: array.first, y: array.second, z: array.third)
  end
end
