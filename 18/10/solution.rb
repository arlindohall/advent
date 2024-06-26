
Star = Struct.new(:location, :velocity)

class Star
  def self.from(x, y, dx, dy)
    new([x, y], [dx, dy])
  end
end

class Message
  attr_reader :stars, :locations
  def initialize(stars)
    @stars = stars
    @locations = reset_locations
  end

  def self.of(text)
    new(
      text.split("\n")
        .map { |line| line.match(/position=<(.*),(.*)> velocity=<(.*),(.*)>/) }
        .map(&:captures)
        .map { |cap| cap.map(&:to_i) }
        .map { |x, y, dx, dy| Star.from(x, y, dx, dy) }
    )
  end

  def reset_locations
    @locations = @stars.group_by(&:location)
  end

  def closest_point
    ct = closest_time
    reset_locations
    update_locations(ct)
    puts ct
    puts "#{show_all}"
  end

  def closest_time
    return @closest_time if @closest_time

    @closest_time = 0
    @spread = spread

    until spread > @spread
      @closest_time += 1
      p [@closest_time, @spread] if @closest_time % 100 == 0
      @spread = spread
      update_locations
    end

    @closest_time - 1
  end

  def spread
    minx, maxx, miny, maxy = minmax

    (maxy - miny)
  end

  def minmax
    minx, maxx = @locations.values.flatten.map(&:location).map(&:first).minmax
    miny, maxy = @locations.values.flatten.map(&:location).map(&:last).minmax

    [minx, maxx, miny, maxy]
  end

  def show_all
    minx, maxx, miny, maxy = minmax
    miny.upto(maxy).map { |y|
      minx.upto(maxx).map { |x|
        @locations.include?([x, y]) ? '#' : '.'
      }.join
    }.join("\n")
  end

  def update_locations(factor = 1)
    @locations = @locations.values.flat_map { |overlap|
      overlap.map { |st|
        x, y, dx, dy = [st.location, st.velocity].flatten
        Star.from(x+factor*dx, y+factor*dy, dx, dy)
      }
    }.group_by(&:location)
  end
end

@example = <<-stars
position=< 9,  1> velocity=< 0,  2>
position=< 7,  0> velocity=<-1,  0>
position=< 3, -2> velocity=<-1,  1>
position=< 6, 10> velocity=<-2, -1>
position=< 2, -4> velocity=< 2,  2>
position=<-6, 10> velocity=< 2, -2>
position=< 1,  8> velocity=< 1, -1>
position=< 1,  7> velocity=< 1,  0>
position=<-3, 11> velocity=< 1, -2>
position=< 7,  6> velocity=<-1, -1>
position=<-2,  3> velocity=< 1,  0>
position=<-4,  3> velocity=< 2,  0>
position=<10, -3> velocity=<-1,  1>
position=< 5, 11> velocity=< 1, -2>
position=< 4,  7> velocity=< 0, -1>
position=< 8, -2> velocity=< 0,  1>
position=<15,  0> velocity=<-2,  0>
position=< 1,  6> velocity=< 1,  0>
position=< 8,  9> velocity=< 0, -1>
position=< 3,  3> velocity=<-1,  1>
position=< 0,  5> velocity=< 0, -1>
position=<-2,  2> velocity=< 2,  0>
position=< 5, -2> velocity=< 1,  2>
position=< 1,  4> velocity=< 2,  1>
position=<-2,  7> velocity=< 2, -2>
position=< 3,  6> velocity=<-1, -1>
position=< 5,  0> velocity=< 1,  0>
position=<-6,  0> velocity=< 2,  0>
position=< 5,  9> velocity=< 1, -2>
position=<14,  7> velocity=<-2,  0>
position=<-3,  6> velocity=< 2, -1>
stars

@input = <<-stars
position=<-50310,  10306> velocity=< 5, -1>
position=<-20029,  -9902> velocity=< 2,  1>
position=< 10277, -30099> velocity=<-1,  3>
position=<-20031, -30096> velocity=< 2,  3>
position=< 30495, -40196> velocity=<-3,  4>
position=< 30494,  40607> velocity=<-3, -4>
position=< 20375,  10300> velocity=<-2, -1>
position=<-30084,  30507> velocity=< 3, -3>
position=< 30506, -30097> velocity=<-3,  3>
position=< 40620, -50305> velocity=<-4,  5>
position=< -9890, -50300> velocity=< 1,  5>
position=<-50305,  20404> velocity=< 5, -2>
position=<-50334,  30505> velocity=< 5, -3>
position=<-19983, -30096> velocity=< 2,  3>
position=<-40229, -19995> velocity=< 4,  2>
position=< 40584,  10304> velocity=<-4, -1>
position=<-30092, -30095> velocity=< 3,  3>
position=< 30479,  20406> velocity=<-3, -2>
position=< 20373, -20002> velocity=<-2,  2>
position=<-30076, -30096> velocity=< 3,  3>
position=<-50314,  40603> velocity=< 5, -4>
position=< 30514, -19996> velocity=<-3,  2>
position=< 10307,  30506> velocity=<-1, -3>
position=<-50286,  50704> velocity=< 5, -5>
position=< 20384, -50306> velocity=<-2,  5>
position=< 30490,  10305> velocity=<-3, -1>
position=<-30084, -20002> velocity=< 3,  2>
position=< 30519, -40203> velocity=<-3,  4>
position=< 10324, -30100> velocity=<-1,  3>
position=< 20426, -20003> velocity=<-2,  2>
position=< 10280, -30102> velocity=<-1,  3>
position=< 20381,  -9893> velocity=<-2,  1>
position=< 10297, -30104> velocity=<-1,  3>
position=< 10321, -40196> velocity=<-1,  4>
position=< -9927, -19998> velocity=< 1,  2>
position=< 50679,  50704> velocity=<-5, -5>
position=<-50310, -50304> velocity=< 5,  5>
position=<-50300,  50708> velocity=< 5, -5>
position=<-40232, -50306> velocity=< 4,  5>
position=< 30482,  50704> velocity=<-3, -5>
position=<-30127, -20002> velocity=< 3,  2>
position=< 50681, -19996> velocity=<-5,  2>
position=< 50687, -50306> velocity=<-5,  5>
position=< 20397,  20405> velocity=<-2, -2>
position=<-50317,  10309> velocity=< 5, -1>
position=< 30482,  -9896> velocity=<-3,  1>
position=<-40216,  40607> velocity=< 4, -4>
position=< 50684, -19998> velocity=<-5,  2>
position=<-50302,  30507> velocity=< 5, -3>
position=< -9870, -50299> velocity=< 1,  5>
position=< -9917,  -9899> velocity=< 1,  1>
position=< 20386, -30102> velocity=<-2,  3>
position=< 40624,  20401> velocity=<-4, -2>
position=< 50708,  -9899> velocity=<-5,  1>
position=<-20023, -40201> velocity=< 2,  4>
position=< 10309, -50305> velocity=<-1,  5>
position=< -9882, -40205> velocity=< 1,  4>
position=<-30107,  50704> velocity=< 3, -5>
position=<-50318,  50713> velocity=< 5, -5>
position=< 20426, -40196> velocity=<-2,  4>
position=< -9914, -30101> velocity=< 1,  3>
position=<-50316,  10300> velocity=< 5, -1>
position=< -9922,  50710> velocity=< 1, -5>
position=< 30483,  20401> velocity=<-3, -2>
position=<-50286,  50707> velocity=< 5, -5>
position=< 20415, -50306> velocity=<-2,  5>
position=<-40220,  -9901> velocity=< 4,  1>
position=<-30127, -30098> velocity=< 3,  3>
position=<-19996, -40205> velocity=< 2,  4>
position=<-50315, -20003> velocity=< 5,  2>
position=< 40587,  50704> velocity=<-4, -5>
position=<-30100, -40201> velocity=< 3,  4>
position=<-50273,  30502> velocity=< 5, -3>
position=< 30487, -50304> velocity=<-3,  5>
position=< 30522, -19998> velocity=<-3,  2>
position=< 50677,  10309> velocity=<-5, -1>
position=<-30104, -19999> velocity=< 3,  2>
position=< 30523,  30506> velocity=<-3, -3>
position=<-40233,  -9895> velocity=< 4,  1>
position=<-30116,  10302> velocity=< 3, -1>
position=<-30108, -30095> velocity=< 3,  3>
position=< -9898, -19995> velocity=< 1,  2>
position=<-40217, -19994> velocity=< 4,  2>
position=< 40635, -19998> velocity=<-4,  2>
position=< 10316,  30502> velocity=<-1, -3>
position=<-40206,  -9898> velocity=< 4,  1>
position=< 10272, -30096> velocity=<-1,  3>
position=< 20397,  20409> velocity=<-2, -2>
position=<-50326, -19994> velocity=< 5,  2>
position=< 40594,  10309> velocity=<-4, -1>
position=<-50334,  -9899> velocity=< 5,  1>
position=<-50294, -30098> velocity=< 5,  3>
position=< 10304,  30508> velocity=<-1, -3>
position=< 10280,  10303> velocity=<-1, -1>
position=<-50330,  10305> velocity=< 5, -1>
position=<-30084, -40199> velocity=< 3,  4>
position=< 20389,  20402> velocity=<-2, -2>
position=< -9910, -40205> velocity=< 1,  4>
position=<-50334,  30509> velocity=< 5, -3>
position=< -9870,  20409> velocity=< 1, -2>
position=< 10289,  20401> velocity=<-1, -2>
position=< 10285,  10303> velocity=<-1, -1>
position=<-50297,  20404> velocity=< 5, -2>
position=< 10283, -30100> velocity=<-1,  3>
position=< 30500,  20401> velocity=<-3, -2>
position=< -9893,  20402> velocity=< 1, -2>
position=<-50275,  50713> velocity=< 5, -5>
position=<-50294,  -9900> velocity=< 5,  1>
position=<-19983,  50713> velocity=< 2, -5>
position=<-40221,  10304> velocity=< 4, -1>
position=<-50302,  40606> velocity=< 5, -4>
position=< 40615, -50302> velocity=<-4,  5>
position=<-40197, -30104> velocity=< 4,  3>
position=<-50330, -20003> velocity=< 5,  2>
position=< 50689,  30504> velocity=<-5, -3>
position=<-40173, -20002> velocity=< 4,  2>
position=<-20029,  40603> velocity=< 2, -4>
position=< 20410, -40202> velocity=<-2,  4>
position=< 40631,  40610> velocity=<-4, -4>
position=< 40611,  -9902> velocity=<-4,  1>
position=< 40583, -50298> velocity=<-4,  5>
position=<-40212,  40612> velocity=< 4, -4>
position=<-50283,  -9893> velocity=< 5,  1>
position=< 40607, -30098> velocity=<-4,  3>
position=< 40575, -40204> velocity=<-4,  4>
position=< 20373, -19999> velocity=<-2,  2>
position=< 30490, -50298> velocity=<-3,  5>
position=<-30105,  -9902> velocity=< 3,  1>
position=<-40183,  30511> velocity=< 4, -3>
position=< 40583,  10302> velocity=<-4, -1>
position=<-30108,  50712> velocity=< 3, -5>
position=< 30494, -19994> velocity=<-3,  2>
position=<-50294, -30101> velocity=< 5,  3>
position=< 40583,  30508> velocity=<-4, -3>
position=<-40233, -50302> velocity=< 4,  5>
position=< 50681, -40197> velocity=<-5,  4>
position=<-20015, -50306> velocity=< 2,  5>
position=< 50736,  30502> velocity=<-5, -3>
position=<-20013,  40612> velocity=< 2, -4>
position=< 50735,  -9902> velocity=<-5,  1>
position=< 30490,  40606> velocity=<-3, -4>
position=<-19973,  30511> velocity=< 2, -3>
position=<-50310, -40201> velocity=< 5,  4>
position=< 10312, -40196> velocity=<-1,  4>
position=< -9874, -40198> velocity=< 1,  4>
position=< 40593,  50708> velocity=<-4, -5>
position=<-40188, -40203> velocity=< 4,  4>
position=< 50736, -20000> velocity=<-5,  2>
position=< 20400, -40205> velocity=<-2,  4>
position=< 30475,  30511> velocity=<-3, -3>
position=<-50294, -20000> velocity=< 5,  2>
position=<-30100, -30095> velocity=< 3,  3>
position=< 20373,  10305> velocity=<-2, -1>
position=<-50274,  50709> velocity=< 5, -5>
position=< 30507,  50704> velocity=<-3, -5>
position=<-30088, -20003> velocity=< 3,  2>
position=<-19999,  50709> velocity=< 2, -5>
position=< -9885,  10303> velocity=< 1, -1>
position=< 40616,  10304> velocity=<-4, -1>
position=< 20433,  -9902> velocity=<-2,  1>
position=< 40615, -40203> velocity=<-4,  4>
position=<-40198, -20003> velocity=< 4,  2>
position=< 10320, -19997> velocity=<-1,  2>
position=< 40607,  20402> velocity=<-4, -2>
position=<-20015,  10307> velocity=< 2, -1>
position=<-50290,  20401> velocity=< 5, -2>
position=< 40591, -30104> velocity=<-4,  3>
position=<-50289,  30504> velocity=< 5, -3>
position=< 30474,  20403> velocity=<-3, -2>
position=<-40196, -20001> velocity=< 4,  2>
position=<-30108,  40606> velocity=< 3, -4>
position=< 10280,  50707> velocity=<-1, -5>
position=< 40580, -50305> velocity=<-4,  5>
position=< 10274,  50713> velocity=<-1, -5>
position=< 20413,  50706> velocity=<-2, -5>
position=<-40175,  50713> velocity=< 4, -5>
position=< 10316,  40607> velocity=<-1, -4>
position=< 50712, -30104> velocity=<-5,  3>
position=<-50333, -20003> velocity=< 5,  2>
position=< 50700,  20401> velocity=<-5, -2>
position=<-40191,  40607> velocity=< 4, -4>
position=<-40222,  10300> velocity=< 4, -1>
position=<-19979, -20003> velocity=< 2,  2>
position=< 10301, -30103> velocity=<-1,  3>
position=<-50274, -30098> velocity=< 5,  3>
position=< 20416, -20003> velocity=<-2,  2>
position=< -9906, -40202> velocity=< 1,  4>
position=<-20015, -50298> velocity=< 2,  5>
position=<-50286,  30505> velocity=< 5, -3>
position=<-40217,  30509> velocity=< 4, -3>
position=< 10280, -40198> velocity=<-1,  4>
position=< 20378, -50297> velocity=<-2,  5>
position=< 30483,  30506> velocity=<-3, -3>
position=< 50692,  30505> velocity=<-5, -3>
position=< -9887, -19999> velocity=< 1,  2>
position=<-40205,  -9902> velocity=< 4,  1>
position=<-20019,  -9898> velocity=< 2,  1>
position=< -9872,  -9893> velocity=< 1,  1>
position=< 30498,  50713> velocity=<-3, -5>
position=<-40233,  40604> velocity=< 4, -4>
position=< 20383,  30506> velocity=<-2, -3>
position=< 10306,  10300> velocity=<-1, -1>
position=<-50326,  20402> velocity=< 5, -2>
position=< 40634,  20401> velocity=<-4, -2>
position=< 50726, -50302> velocity=<-5,  5>
position=<-50274,  30510> velocity=< 5, -3>
position=< -9910,  -9893> velocity=< 1,  1>
position=< 30478, -19998> velocity=<-3,  2>
position=< 20424,  10309> velocity=<-2, -1>
position=<-30087, -30101> velocity=< 3,  3>
position=< 50681, -50299> velocity=<-5,  5>
position=< 50694,  10304> velocity=<-5, -1>
position=< 10305,  30502> velocity=<-1, -3>
position=< 50724,  10301> velocity=<-5, -1>
position=<-30080, -19994> velocity=< 3,  2>
position=<-50318,  40605> velocity=< 5, -4>
position=< 10296,  20401> velocity=<-1, -2>
position=<-40173, -50306> velocity=< 4,  5>
position=< 40585,  50708> velocity=<-4, -5>
position=< 40578, -30095> velocity=<-4,  3>
position=< 10307, -19999> velocity=<-1,  2>
position=<-30106,  50708> velocity=< 3, -5>
position=< 10296,  20402> velocity=<-1, -2>
position=< -9922,  50708> velocity=< 1, -5>
position=<-40209, -50297> velocity=< 4,  5>
position=<-40201,  40611> velocity=< 4, -4>
position=<-40206,  10304> velocity=< 4, -1>
position=< 30503,  30505> velocity=<-3, -3>
position=< 10296, -50301> velocity=<-1,  5>
position=<-20007,  40608> velocity=< 2, -4>
position=< 50724,  30503> velocity=<-5, -3>
position=< 20383, -40201> velocity=<-2,  4>
position=< 30503,  20403> velocity=<-3, -2>
position=< 50718,  20401> velocity=<-5, -2>
position=< 30498, -30098> velocity=<-3,  3>
position=<-50326,  50708> velocity=< 5, -5>
position=< 50676, -19996> velocity=<-5,  2>
position=< 40591, -40201> velocity=<-4,  4>
position=<-20015, -40201> velocity=< 2,  4>
position=<-40233,  10302> velocity=< 4, -1>
position=<-40217,  40607> velocity=< 4, -4>
position=< -9870,  40609> velocity=< 1, -4>
position=< 10312, -40196> velocity=<-1,  4>
position=<-30129,  30511> velocity=< 3, -3>
position=< 30526,  30511> velocity=<-3, -3>
position=< 30534,  -9898> velocity=<-3,  1>
position=< -9870,  30505> velocity=< 1, -3>
position=< 50732,  -9894> velocity=<-5,  1>
position=<-50281, -19994> velocity=< 5,  2>
position=<-20031, -30099> velocity=< 2,  3>
position=< 50677,  30511> velocity=<-5, -3>
position=< 20405, -50306> velocity=<-2,  5>
position=<-50318,  10306> velocity=< 5, -1>
position=< 50727, -19999> velocity=<-5,  2>
position=<-30080, -30104> velocity=< 3,  3>
position=<-30081,  30511> velocity=< 3, -3>
position=< 50736,  30510> velocity=<-5, -3>
position=< -9914, -30097> velocity=< 1,  3>
position=<-30100,  20402> velocity=< 3, -2>
position=< 40634,  10300> velocity=<-4, -1>
position=< 30477,  40603> velocity=<-3, -4>
position=<-50274, -40200> velocity=< 5,  4>
position=< 50708, -40198> velocity=<-5,  4>
position=<-19999,  -9896> velocity=< 2,  1>
position=<-50294,  10306> velocity=< 5, -1>
position=< 30522,  40608> velocity=<-3, -4>
position=< 40623, -50298> velocity=<-4,  5>
position=<-50334,  50712> velocity=< 5, -5>
position=<-40215, -19994> velocity=< 4,  2>
position=< 40623, -40199> velocity=<-4,  4>
position=< -9882,  40605> velocity=< 1, -4>
position=<-30132, -19997> velocity=< 3,  2>
position=< 30478, -30104> velocity=<-3,  3>
position=<-20021,  30502> velocity=< 2, -3>
position=< 10320, -40198> velocity=<-1,  4>
position=< 40583, -30099> velocity=<-4,  3>
position=< 50692, -20002> velocity=<-5,  2>
position=< 40615,  10308> velocity=<-4, -1>
position=<-40192, -40201> velocity=< 4,  4>
position=< 30498,  30504> velocity=<-3, -3>
position=< 10296, -40204> velocity=<-1,  4>
position=<-20012,  10309> velocity=< 2, -1>
position=<-40229,  -9902> velocity=< 4,  1>
position=< -9890, -30104> velocity=< 1,  3>
position=< 50676, -30102> velocity=<-5,  3>
position=< 50724, -19999> velocity=<-5,  2>
position=<-30095,  30505> velocity=< 3, -3>
position=< 30530, -50299> velocity=<-3,  5>
position=< 40599,  10302> velocity=<-4, -1>
position=<-30113,  30506> velocity=< 3, -3>
position=<-50309,  50704> velocity=< 5, -5>
position=< 40625,  30506> velocity=<-4, -3>
position=< -9869, -40205> velocity=< 1,  4>
position=< 50708,  40605> velocity=<-5, -4>
position=<-30115,  30502> velocity=< 3, -3>
position=<-20010,  50713> velocity=< 2, -5>
position=< 10280,  40611> velocity=<-1, -4>
position=<-19983, -20003> velocity=< 2,  2>
position=< 20386,  50707> velocity=<-2, -5>
position=<-50314, -19999> velocity=< 5,  2>
position=< 40624,  10300> velocity=<-4, -1>
position=< -9887,  10304> velocity=< 1, -1>
position=< 30498,  10300> velocity=<-3, -1>
position=<-19971,  20403> velocity=< 2, -2>
position=< 50725,  30506> velocity=<-5, -3>
position=<-40199, -50306> velocity=< 4,  5>
position=<-30075,  40612> velocity=< 3, -4>
position=< -9910, -50306> velocity=< 1,  5>
position=<-40233, -40199> velocity=< 4,  4>
position=< -9922,  10308> velocity=< 1, -1>
position=<-30116, -30095> velocity=< 3,  3>
position=< 30523,  20405> velocity=<-3, -2>
position=< 50700, -30097> velocity=<-5,  3>
position=<-30092,  20406> velocity=< 3, -2>
position=<-19999,  10301> velocity=< 2, -1>
position=<-20026,  30507> velocity=< 2, -3>
position=<-30129,  30511> velocity=< 3, -3>
position=< 50684,  20402> velocity=<-5, -2>
position=< 40615, -20002> velocity=<-4,  2>
position=<-50309,  40607> velocity=< 5, -4>
position=<-30096,  40607> velocity=< 3, -4>
position=< -9879, -30104> velocity=< 1,  3>
position=< 20433, -50299> velocity=<-2,  5>
position=<-50326,  10303> velocity=< 5, -1>
position=<-40193, -50306> velocity=< 4,  5>
position=< 30478, -19995> velocity=<-3,  2>
position=< 30483, -40205> velocity=<-3,  4>
position=< 20421,  -9898> velocity=<-2,  1>
position=<-30084,  -9900> velocity=< 3,  1>
position=<-50284,  40603> velocity=< 5, -4>
position=<-40200,  30506> velocity=< 4, -3>
position=< 50721, -20000> velocity=<-5,  2>
position=< 50684,  40610> velocity=<-5, -4>
position=< -9911, -30104> velocity=< 1,  3>
position=< 40607, -19998> velocity=<-4,  2>
position=< 20402,  30503> velocity=<-2, -3>
position=<-30092,  10307> velocity=< 3, -1>
position=< 30522, -30100> velocity=<-3,  3>
position=< 40627,  10309> velocity=<-4, -1>
position=<-50313, -20003> velocity=< 5,  2>
position=<-19988,  40603> velocity=< 2, -4>
position=< 50684,  10307> velocity=<-5, -1>
position=< 20405, -50306> velocity=<-2,  5>
position=<-19995,  -9898> velocity=< 2,  1>
position=<-50297, -50305> velocity=< 5,  5>
position=< 50700,  30506> velocity=<-5, -3>
position=< -9901, -30102> velocity=< 1,  3>
position=< 30515, -20003> velocity=<-3,  2>
stars