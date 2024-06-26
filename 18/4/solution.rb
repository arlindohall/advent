
class Event
  attr_reader :date, :hour, :minute, :type, :guard
  def initialize(date, hour, minute, type, guard=nil)
    @date, @hour, @minute, @type, @guard = date, hour, minute, type, guard
  end

  def self.of(line)
    month, day, hour, minute = /\[1518-(\d+)-(\d+) (\d+):(\d+)\]/.match(line).captures.map(&:to_i)
    action = line.split("] ").last
    guard = /\#(\d+)/.match(line) && $1.to_i

    new(
      hour > 8 ? next_day(month, day) : "#{month}-#{day}",
      hour,
      minute,
      action,
      guard
    )
  end

  def self.next_day(month, day)
    case month
    when 9, 4, 6, 11
      return "#{month + 1}-1" if day == 30
    when 2
      return "#{month + 1}-1" if day == 28
    else
      return "#{month + 1}-1" if day == 31
    end

    "#{month}-#{day + 1}"
  end
end

class Shift
  attr_reader :guard, :date, :sleeps
  def initialize(guard, date, sleeps)
    @guard, @date, @sleeps = guard, date, sleeps
  end

  def self.of(events)
    assert_valid(events)

    new(
      events.first.guard,
      events.first.date,
      parse(events.drop(1))
    )
  end

  def self.parse(sleeps)
    sleeps.each_slice(2).map do |sleeps, wake|
      assert_sleep(sleeps, wake)

      [sleeps.minute, wake.minute]
    end
  end

  def self.assert_sleep(sleeps, wake)
    if sleeps.type != "falls asleep"
      raise "First event must be a sleep"
    end

    if wake.type != "wakes up"
      raise "Last event must be a wake"
    end
  end

  def self.assert_valid(events)
    if events.filter(&:guard).size != 1
      raise "More than one guard per shift: #{events}"
    end

    if events.first.guard.nil?
      raise "No guard on first event: #{events}"
    end

    if events.map(&:date).uniq.size != 1
      raise "More than one date per shift: #{events}"
    end
  end

  def to_s
    "#{date.ljust(7)}\##{guard.to_s.ljust(4)}" \
      "#{0.upto(59).map{|m| asleep?(m) ? "#" : "." }.join}"
  end

  def asleep?(minute)
    @sleeps.any?{|sl| sl.first <= minute && minute < sl.last}
  end

  def minutes_asleep
    0.upto(59).filter{|m| asleep?(m)}.size
  end
end

class Schedule
  def initialize(shifts)
    @shifts = shifts
  end

  def self.of(text)
    new(parse(text.split("\n").sort))
  end

  def self.parse(events)
    partition(events).values.map { |events|
      Shift.of(events)
    }
  end

  def self.partition(events)
    events.map{|e| Event.of(e)}.group_by(&:date)
  end

  def show
    puts "#{"Date".ljust(7)}#{"ID".ljust(5)}Minute"
    puts (" " * 12) + 0.upto(5).map{|i| 10.times.map{i.to_s}}.join
    puts (" " * 12) + 6.times.map{0.upto(9).map{|i| i.to_s}}.join

    @shifts.each{|s| puts s.to_s}

    nil
  end

  def solve
    [strategy1, strategy2]
  end

  def strategy1
    id, shifts = sleepiest_guard
    minute, times = sleepiest_minute(shifts)
    id * minute
  end

  def sleepiest_guard
    guards.max_by{|id, shifts| shifts.map(&:minutes_asleep).flatten.sum}
  end

  def guards
    @guards ||= @shifts.group_by(&:guard)
  end

  def sleepiest_minute(shifts)
    times_asleep(shifts).max_by{|_minute, times| times}
  end

  def times_asleep(shifts)
    0.upto(50).map {|m|
      [m, times_asleep_at_minute(shifts, m)]
    }
  end

  def strategy2
    guard, _times, minute = 0.upto(59).map{|m| sleepiest_guard_at_time(m)}
      .max_by{|_guard, times, _minute| times}
    
    p [guard, minute]
    guard * minute
  end

  def sleepiest_guard_at_time(minute)
    guards.map{|id, shifts| [id, times_asleep_at_minute(shifts, minute), minute]}
      .max_by{|_guard, times, _minute| times}
  end

  def times_asleep_at_minute(shifts, minute)
    shifts.map{|s| s.asleep?(minute) ? 1 : 0}.sum
  end
end

@input = <<-shifts
[1518-08-08 00:45] falls asleep
[1518-05-02 00:52] falls asleep
[1518-05-07 00:56] wakes up
[1518-08-18 00:06] falls asleep
[1518-11-11 00:04] Guard #2179 begins shift
[1518-09-15 00:38] wakes up
[1518-10-19 00:22] wakes up
[1518-08-14 00:45] falls asleep
[1518-10-16 00:47] falls asleep
[1518-10-27 00:02] Guard #3181 begins shift
[1518-03-23 00:23] falls asleep
[1518-04-01 00:53] wakes up
[1518-05-08 00:57] wakes up
[1518-07-08 00:29] falls asleep
[1518-05-21 23:58] Guard #2879 begins shift
[1518-10-13 00:53] wakes up
[1518-09-04 00:56] falls asleep
[1518-08-30 00:01] falls asleep
[1518-03-24 00:48] wakes up
[1518-11-09 00:00] Guard #89 begins shift
[1518-09-13 23:52] Guard #3251 begins shift
[1518-10-13 00:25] falls asleep
[1518-04-26 00:33] falls asleep
[1518-08-23 00:04] Guard #1021 begins shift
[1518-10-25 00:50] wakes up
[1518-08-28 00:38] falls asleep
[1518-03-31 00:58] wakes up
[1518-04-16 00:56] wakes up
[1518-09-27 23:59] Guard #2179 begins shift
[1518-10-22 00:58] wakes up
[1518-11-07 00:29] wakes up
[1518-02-12 00:03] Guard #983 begins shift
[1518-10-31 00:39] wakes up
[1518-09-28 00:24] falls asleep
[1518-06-05 23:56] Guard #2843 begins shift
[1518-04-21 00:51] falls asleep
[1518-03-22 00:56] wakes up
[1518-04-30 00:03] Guard #3433 begins shift
[1518-08-20 00:53] wakes up
[1518-06-24 00:04] Guard #2179 begins shift
[1518-10-25 00:24] falls asleep
[1518-06-05 00:51] falls asleep
[1518-06-08 00:37] wakes up
[1518-04-11 00:07] falls asleep
[1518-09-19 00:03] falls asleep
[1518-06-23 00:45] wakes up
[1518-02-26 00:00] Guard #631 begins shift
[1518-05-05 00:30] falls asleep
[1518-08-26 00:58] wakes up
[1518-02-23 00:35] falls asleep
[1518-07-10 00:04] Guard #89 begins shift
[1518-07-08 00:38] falls asleep
[1518-04-26 00:47] wakes up
[1518-08-10 00:00] Guard #2843 begins shift
[1518-11-18 00:52] wakes up
[1518-09-01 00:54] falls asleep
[1518-09-24 00:52] wakes up
[1518-09-04 00:59] wakes up
[1518-10-03 00:29] falls asleep
[1518-08-18 00:03] Guard #631 begins shift
[1518-07-29 23:58] Guard #2801 begins shift
[1518-06-08 00:13] falls asleep
[1518-09-14 23:56] Guard #3251 begins shift
[1518-04-08 00:54] wakes up
[1518-08-21 23:47] Guard #631 begins shift
[1518-07-24 00:36] wakes up
[1518-03-27 00:51] falls asleep
[1518-04-03 00:55] wakes up
[1518-06-17 00:54] falls asleep
[1518-07-11 00:49] wakes up
[1518-04-04 00:30] falls asleep
[1518-09-28 23:59] Guard #2801 begins shift
[1518-05-02 00:31] wakes up
[1518-04-21 00:01] Guard #3433 begins shift
[1518-06-07 00:38] wakes up
[1518-06-09 23:59] Guard #1579 begins shift
[1518-10-29 00:51] wakes up
[1518-02-16 00:54] falls asleep
[1518-08-11 00:52] falls asleep
[1518-03-21 00:58] wakes up
[1518-09-20 00:58] wakes up
[1518-04-15 00:30] falls asleep
[1518-08-28 23:59] Guard #2879 begins shift
[1518-07-27 00:44] wakes up
[1518-10-20 00:55] wakes up
[1518-06-02 00:42] wakes up
[1518-08-26 00:43] wakes up
[1518-07-12 00:39] wakes up
[1518-09-25 00:00] Guard #2801 begins shift
[1518-03-14 00:41] falls asleep
[1518-06-23 00:59] wakes up
[1518-05-15 00:59] wakes up
[1518-02-23 00:41] wakes up
[1518-07-19 00:59] wakes up
[1518-04-23 00:32] falls asleep
[1518-02-22 00:57] wakes up
[1518-04-17 00:07] falls asleep
[1518-07-28 00:16] falls asleep
[1518-02-22 23:49] Guard #2971 begins shift
[1518-05-24 23:59] Guard #1579 begins shift
[1518-08-19 00:43] wakes up
[1518-07-05 00:16] falls asleep
[1518-06-01 23:56] Guard #2801 begins shift
[1518-06-10 00:53] wakes up
[1518-05-05 00:48] wakes up
[1518-11-01 23:58] Guard #89 begins shift
[1518-08-11 00:03] Guard #587 begins shift
[1518-09-27 00:49] wakes up
[1518-11-05 00:12] wakes up
[1518-06-27 23:58] Guard #1021 begins shift
[1518-07-01 00:53] falls asleep
[1518-02-25 00:02] Guard #89 begins shift
[1518-08-11 00:48] wakes up
[1518-06-22 23:57] Guard #3331 begins shift
[1518-03-18 00:52] wakes up
[1518-06-09 00:43] falls asleep
[1518-03-13 00:56] wakes up
[1518-03-30 00:49] wakes up
[1518-02-24 00:01] Guard #587 begins shift
[1518-10-27 00:10] falls asleep
[1518-10-02 00:28] falls asleep
[1518-02-15 00:03] Guard #1579 begins shift
[1518-11-17 00:41] wakes up
[1518-07-09 00:00] Guard #3181 begins shift
[1518-03-28 00:24] falls asleep
[1518-03-23 00:03] Guard #2971 begins shift
[1518-06-10 00:07] falls asleep
[1518-06-10 00:34] wakes up
[1518-06-28 00:51] wakes up
[1518-09-19 23:59] Guard #2179 begins shift
[1518-05-30 00:02] Guard #3331 begins shift
[1518-06-10 00:39] falls asleep
[1518-03-01 23:53] Guard #1069 begins shift
[1518-04-03 00:00] falls asleep
[1518-05-28 00:01] Guard #631 begins shift
[1518-03-24 00:54] falls asleep
[1518-08-03 23:59] Guard #2843 begins shift
[1518-10-17 23:59] Guard #2179 begins shift
[1518-03-06 00:16] wakes up
[1518-03-26 00:53] wakes up
[1518-04-15 23:58] Guard #1021 begins shift
[1518-04-28 00:03] Guard #2879 begins shift
[1518-09-04 00:42] falls asleep
[1518-03-25 00:01] Guard #983 begins shift
[1518-04-09 00:59] wakes up
[1518-03-19 00:31] falls asleep
[1518-09-25 00:26] falls asleep
[1518-02-23 00:28] wakes up
[1518-07-18 00:41] wakes up
[1518-11-15 00:38] falls asleep
[1518-07-16 00:42] wakes up
[1518-06-23 00:54] falls asleep
[1518-03-04 00:22] falls asleep
[1518-07-02 00:42] falls asleep
[1518-08-24 23:58] Guard #631 begins shift
[1518-06-03 00:02] falls asleep
[1518-08-29 00:56] wakes up
[1518-04-19 00:19] wakes up
[1518-08-24 00:09] falls asleep
[1518-08-24 00:35] wakes up
[1518-11-22 00:53] wakes up
[1518-07-26 00:26] falls asleep
[1518-10-08 00:48] falls asleep
[1518-04-11 00:00] Guard #2179 begins shift
[1518-09-30 00:50] wakes up
[1518-05-09 00:26] wakes up
[1518-08-18 00:24] falls asleep
[1518-06-01 00:54] wakes up
[1518-02-24 00:12] falls asleep
[1518-03-15 00:14] falls asleep
[1518-04-04 00:58] wakes up
[1518-10-01 00:50] wakes up
[1518-06-18 00:14] falls asleep
[1518-06-03 00:47] wakes up
[1518-07-31 00:51] wakes up
[1518-05-29 00:53] falls asleep
[1518-02-14 00:54] wakes up
[1518-06-16 00:59] wakes up
[1518-04-19 00:29] falls asleep
[1518-04-24 00:04] Guard #631 begins shift
[1518-10-05 00:50] wakes up
[1518-06-26 00:54] wakes up
[1518-11-13 00:37] wakes up
[1518-08-25 23:58] Guard #3181 begins shift
[1518-07-29 00:24] falls asleep
[1518-02-28 00:35] falls asleep
[1518-07-08 00:04] Guard #3181 begins shift
[1518-11-13 00:13] falls asleep
[1518-11-21 23:48] Guard #3181 begins shift
[1518-10-11 00:14] falls asleep
[1518-10-19 00:03] Guard #983 begins shift
[1518-09-06 00:46] falls asleep
[1518-08-27 00:54] wakes up
[1518-04-19 00:36] wakes up
[1518-10-06 00:01] Guard #3433 begins shift
[1518-09-14 00:05] falls asleep
[1518-10-10 00:12] falls asleep
[1518-03-19 23:54] Guard #3331 begins shift
[1518-06-20 00:12] wakes up
[1518-04-05 23:56] Guard #3251 begins shift
[1518-10-04 23:57] Guard #3433 begins shift
[1518-08-07 23:50] Guard #2671 begins shift
[1518-08-21 00:36] falls asleep
[1518-09-04 23:53] Guard #631 begins shift
[1518-05-19 00:20] wakes up
[1518-03-25 00:52] wakes up
[1518-03-06 00:25] wakes up
[1518-07-16 00:48] falls asleep
[1518-08-16 00:50] wakes up
[1518-07-10 00:23] falls asleep
[1518-04-26 00:06] falls asleep
[1518-11-06 00:57] wakes up
[1518-03-08 00:51] wakes up
[1518-08-19 00:52] wakes up
[1518-07-21 00:59] wakes up
[1518-02-16 00:03] Guard #2179 begins shift
[1518-11-14 00:16] falls asleep
[1518-06-18 23:49] Guard #2671 begins shift
[1518-09-21 00:53] falls asleep
[1518-11-05 23:58] Guard #89 begins shift
[1518-03-26 00:43] falls asleep
[1518-09-14 00:37] wakes up
[1518-06-12 23:58] Guard #2179 begins shift
[1518-06-05 00:53] wakes up
[1518-08-06 00:57] wakes up
[1518-06-30 00:02] Guard #631 begins shift
[1518-10-04 00:54] wakes up
[1518-05-18 23:53] Guard #631 begins shift
[1518-10-02 00:56] wakes up
[1518-08-01 00:06] falls asleep
[1518-08-13 23:58] Guard #2179 begins shift
[1518-10-03 00:39] wakes up
[1518-09-13 00:21] falls asleep
[1518-05-14 00:09] falls asleep
[1518-05-23 00:42] falls asleep
[1518-07-17 23:58] Guard #2843 begins shift
[1518-09-06 00:17] wakes up
[1518-08-19 00:39] falls asleep
[1518-10-18 00:32] wakes up
[1518-05-12 00:31] wakes up
[1518-05-26 00:00] Guard #2957 begins shift
[1518-09-02 00:55] wakes up
[1518-09-20 00:41] falls asleep
[1518-09-27 00:40] falls asleep
[1518-10-10 00:53] falls asleep
[1518-03-21 23:53] Guard #163 begins shift
[1518-06-19 00:42] wakes up
[1518-11-10 00:52] wakes up
[1518-07-07 00:29] wakes up
[1518-10-20 00:33] wakes up
[1518-10-30 23:56] Guard #2801 begins shift
[1518-06-09 00:36] wakes up
[1518-02-21 00:23] wakes up
[1518-05-14 00:36] wakes up
[1518-05-03 23:54] Guard #3251 begins shift
[1518-05-12 00:04] Guard #89 begins shift
[1518-05-10 23:56] Guard #587 begins shift
[1518-06-17 00:22] wakes up
[1518-03-16 00:58] wakes up
[1518-05-30 00:56] wakes up
[1518-09-11 00:43] wakes up
[1518-07-13 00:39] falls asleep
[1518-07-22 00:00] Guard #587 begins shift
[1518-03-11 00:02] falls asleep
[1518-10-08 00:40] wakes up
[1518-06-20 00:39] wakes up
[1518-04-16 00:49] falls asleep
[1518-06-24 00:56] wakes up
[1518-03-28 00:36] wakes up
[1518-05-15 00:43] falls asleep
[1518-02-21 00:33] falls asleep
[1518-03-10 00:12] wakes up
[1518-09-20 00:38] wakes up
[1518-07-20 00:27] wakes up
[1518-08-22 00:02] falls asleep
[1518-06-26 00:48] falls asleep
[1518-04-12 00:49] wakes up
[1518-09-06 23:54] Guard #983 begins shift
[1518-07-20 00:35] falls asleep
[1518-05-02 00:56] wakes up
[1518-05-12 00:44] falls asleep
[1518-09-02 23:51] Guard #1021 begins shift
[1518-11-03 00:32] falls asleep
[1518-07-09 00:39] wakes up
[1518-02-18 00:02] Guard #2837 begins shift
[1518-03-17 23:56] Guard #2837 begins shift
[1518-04-26 00:02] Guard #2671 begins shift
[1518-10-14 00:53] wakes up
[1518-07-04 00:01] falls asleep
[1518-03-05 00:24] falls asleep
[1518-09-24 00:02] Guard #3181 begins shift
[1518-04-19 00:06] falls asleep
[1518-02-10 23:47] Guard #631 begins shift
[1518-11-05 00:22] falls asleep
[1518-08-19 00:32] wakes up
[1518-03-27 00:53] wakes up
[1518-04-27 00:04] falls asleep
[1518-04-29 00:40] falls asleep
[1518-07-01 00:37] falls asleep
[1518-07-06 00:55] wakes up
[1518-08-23 00:52] wakes up
[1518-07-30 00:30] falls asleep
[1518-03-19 00:57] wakes up
[1518-05-09 00:12] falls asleep
[1518-03-22 00:18] wakes up
[1518-11-21 00:58] wakes up
[1518-07-02 00:49] wakes up
[1518-04-19 00:01] Guard #2801 begins shift
[1518-10-17 00:45] falls asleep
[1518-07-28 23:59] Guard #311 begins shift
[1518-08-10 00:36] falls asleep
[1518-03-29 23:56] Guard #1069 begins shift
[1518-04-11 00:13] wakes up
[1518-05-02 23:54] Guard #311 begins shift
[1518-09-01 00:42] wakes up
[1518-10-08 00:16] wakes up
[1518-03-29 00:06] falls asleep
[1518-11-11 00:15] falls asleep
[1518-10-15 00:57] wakes up
[1518-07-29 00:43] wakes up
[1518-06-01 00:40] falls asleep
[1518-09-01 00:31] falls asleep
[1518-07-03 00:21] falls asleep
[1518-10-12 23:59] Guard #163 begins shift
[1518-07-02 00:23] falls asleep
[1518-08-31 00:35] wakes up
[1518-08-08 00:19] wakes up
[1518-10-20 00:42] falls asleep
[1518-07-19 23:50] Guard #587 begins shift
[1518-06-15 00:55] wakes up
[1518-08-09 00:03] falls asleep
[1518-10-24 00:50] wakes up
[1518-09-12 00:04] Guard #2063 begins shift
[1518-07-07 00:00] Guard #3251 begins shift
[1518-09-01 00:12] wakes up
[1518-04-04 00:56] falls asleep
[1518-03-14 00:00] Guard #3331 begins shift
[1518-03-05 00:43] wakes up
[1518-10-20 00:51] falls asleep
[1518-08-29 00:40] falls asleep
[1518-07-20 00:03] falls asleep
[1518-10-02 23:56] Guard #311 begins shift
[1518-11-01 00:49] falls asleep
[1518-11-04 00:23] wakes up
[1518-08-11 23:58] Guard #311 begins shift
[1518-03-31 00:00] Guard #311 begins shift
[1518-11-15 00:30] falls asleep
[1518-04-30 00:38] falls asleep
[1518-06-12 00:14] wakes up
[1518-09-03 00:02] falls asleep
[1518-08-18 00:37] wakes up
[1518-03-05 00:26] wakes up
[1518-10-28 00:01] Guard #1069 begins shift
[1518-07-06 00:23] wakes up
[1518-10-27 00:25] wakes up
[1518-06-12 00:01] falls asleep
[1518-09-15 00:11] falls asleep
[1518-02-25 00:42] wakes up
[1518-07-12 00:02] Guard #2879 begins shift
[1518-02-27 00:21] falls asleep
[1518-03-21 00:11] falls asleep
[1518-03-09 00:57] wakes up
[1518-05-03 00:05] falls asleep
[1518-11-14 00:43] wakes up
[1518-03-10 00:53] falls asleep
[1518-05-18 00:26] falls asleep
[1518-09-26 23:57] Guard #631 begins shift
[1518-04-15 00:18] wakes up
[1518-03-26 00:01] Guard #2837 begins shift
[1518-05-03 00:54] wakes up
[1518-06-20 00:29] falls asleep
[1518-08-31 23:53] Guard #3331 begins shift
[1518-04-16 00:31] wakes up
[1518-04-24 00:56] wakes up
[1518-11-14 00:02] Guard #2971 begins shift
[1518-06-14 00:38] falls asleep
[1518-05-22 00:27] wakes up
[1518-10-14 00:14] falls asleep
[1518-04-08 00:05] falls asleep
[1518-10-12 00:08] falls asleep
[1518-10-08 23:58] Guard #3331 begins shift
[1518-08-16 00:04] Guard #3181 begins shift
[1518-04-08 00:06] wakes up
[1518-07-19 00:23] wakes up
[1518-09-08 00:48] falls asleep
[1518-04-13 23:59] Guard #3331 begins shift
[1518-11-16 00:29] wakes up
[1518-02-19 00:24] falls asleep
[1518-06-26 23:56] Guard #3331 begins shift
[1518-04-07 23:50] Guard #3181 begins shift
[1518-05-09 00:04] Guard #2179 begins shift
[1518-08-14 00:56] wakes up
[1518-08-20 00:00] Guard #631 begins shift
[1518-04-14 00:54] wakes up
[1518-07-31 00:23] falls asleep
[1518-07-05 00:03] falls asleep
[1518-07-16 00:00] Guard #1021 begins shift
[1518-06-25 23:56] Guard #2971 begins shift
[1518-11-22 00:00] falls asleep
[1518-08-12 00:39] wakes up
[1518-10-26 00:04] Guard #89 begins shift
[1518-05-10 00:16] falls asleep
[1518-03-20 00:42] wakes up
[1518-03-10 00:47] wakes up
[1518-02-25 00:26] falls asleep
[1518-02-16 00:07] falls asleep
[1518-07-25 00:56] wakes up
[1518-07-14 00:39] wakes up
[1518-06-01 00:48] wakes up
[1518-07-20 00:41] falls asleep
[1518-06-27 00:31] falls asleep
[1518-03-06 00:29] wakes up
[1518-07-19 00:31] falls asleep
[1518-04-26 00:14] wakes up
[1518-09-25 00:39] wakes up
[1518-06-27 00:21] wakes up
[1518-05-08 00:14] falls asleep
[1518-06-28 00:21] falls asleep
[1518-08-30 00:55] falls asleep
[1518-07-20 23:58] Guard #1579 begins shift
[1518-07-27 00:02] falls asleep
[1518-08-12 00:52] wakes up
[1518-07-02 00:31] wakes up
[1518-02-13 00:43] falls asleep
[1518-11-02 00:28] falls asleep
[1518-05-16 00:03] Guard #1021 begins shift
[1518-08-08 23:53] Guard #89 begins shift
[1518-03-21 00:20] wakes up
[1518-02-14 00:36] falls asleep
[1518-05-04 00:23] wakes up
[1518-03-12 00:02] Guard #631 begins shift
[1518-11-17 00:59] wakes up
[1518-03-02 00:54] wakes up
[1518-04-23 00:01] Guard #2843 begins shift
[1518-09-07 00:44] wakes up
[1518-06-21 00:01] falls asleep
[1518-11-15 00:33] wakes up
[1518-05-18 00:40] falls asleep
[1518-06-20 23:54] Guard #983 begins shift
[1518-07-19 00:15] falls asleep
[1518-03-05 00:34] falls asleep
[1518-05-06 00:00] Guard #1069 begins shift
[1518-07-22 00:46] wakes up
[1518-06-12 00:24] falls asleep
[1518-11-22 00:45] wakes up
[1518-05-16 00:41] falls asleep
[1518-03-26 23:56] Guard #2971 begins shift
[1518-11-16 00:13] falls asleep
[1518-07-01 00:56] wakes up
[1518-09-17 00:02] Guard #3331 begins shift
[1518-04-29 00:18] wakes up
[1518-10-16 00:51] wakes up
[1518-09-08 23:58] Guard #311 begins shift
[1518-10-02 00:02] falls asleep
[1518-11-18 00:28] falls asleep
[1518-07-03 00:53] wakes up
[1518-06-22 00:02] falls asleep
[1518-02-28 00:04] Guard #2837 begins shift
[1518-05-25 00:58] wakes up
[1518-07-24 00:43] falls asleep
[1518-03-06 00:20] falls asleep
[1518-06-15 00:02] Guard #3433 begins shift
[1518-04-06 00:51] wakes up
[1518-03-07 00:33] falls asleep
[1518-11-20 23:50] Guard #3181 begins shift
[1518-02-11 00:03] falls asleep
[1518-08-26 00:53] falls asleep
[1518-07-11 00:37] falls asleep
[1518-02-26 00:30] falls asleep
[1518-06-07 00:09] falls asleep
[1518-04-26 00:54] wakes up
[1518-10-15 00:00] Guard #2879 begins shift
[1518-10-10 00:23] wakes up
[1518-09-02 00:18] falls asleep
[1518-10-07 00:34] falls asleep
[1518-06-14 00:50] wakes up
[1518-09-16 00:01] Guard #2971 begins shift
[1518-08-04 00:39] wakes up
[1518-10-20 00:45] wakes up
[1518-09-06 00:56] wakes up
[1518-04-21 00:14] falls asleep
[1518-09-17 00:42] wakes up
[1518-05-20 00:28] wakes up
[1518-03-11 00:59] wakes up
[1518-08-06 00:44] wakes up
[1518-07-05 00:40] wakes up
[1518-11-06 00:52] falls asleep
[1518-03-04 00:01] Guard #3181 begins shift
[1518-05-13 00:03] Guard #89 begins shift
[1518-09-20 00:42] wakes up
[1518-05-27 00:11] falls asleep
[1518-03-10 00:11] falls asleep
[1518-04-07 00:27] falls asleep
[1518-02-15 00:49] wakes up
[1518-06-05 00:03] Guard #1069 begins shift
[1518-05-21 00:21] falls asleep
[1518-06-20 00:10] falls asleep
[1518-06-06 00:59] wakes up
[1518-05-11 00:16] falls asleep
[1518-02-27 00:06] falls asleep
[1518-02-12 23:59] Guard #1069 begins shift
[1518-11-20 00:58] wakes up
[1518-06-13 00:33] wakes up
[1518-09-30 00:00] Guard #2843 begins shift
[1518-08-02 00:41] wakes up
[1518-04-04 00:02] Guard #1579 begins shift
[1518-11-06 00:46] wakes up
[1518-05-06 00:24] falls asleep
[1518-09-14 00:14] falls asleep
[1518-08-19 00:48] falls asleep
[1518-04-07 00:37] wakes up
[1518-06-13 00:21] falls asleep
[1518-05-23 00:54] wakes up
[1518-04-22 00:29] wakes up
[1518-07-03 00:01] Guard #2671 begins shift
[1518-04-29 00:00] falls asleep
[1518-08-11 00:39] falls asleep
[1518-02-19 00:55] wakes up
[1518-02-20 23:53] Guard #1579 begins shift
[1518-10-09 00:59] wakes up
[1518-10-29 23:57] Guard #2957 begins shift
[1518-09-02 00:00] Guard #2837 begins shift
[1518-05-25 00:24] falls asleep
[1518-10-17 00:53] wakes up
[1518-04-24 00:51] falls asleep
[1518-09-29 00:33] falls asleep
[1518-04-11 00:28] falls asleep
[1518-04-14 00:41] falls asleep
[1518-06-01 00:29] falls asleep
[1518-09-18 00:31] falls asleep
[1518-08-04 00:56] falls asleep
[1518-06-08 00:04] Guard #631 begins shift
[1518-08-01 23:57] Guard #2801 begins shift
[1518-10-21 00:35] falls asleep
[1518-04-09 00:40] falls asleep
[1518-09-03 00:52] wakes up
[1518-04-27 00:47] wakes up
[1518-08-24 00:52] falls asleep
[1518-11-17 00:02] Guard #1069 begins shift
[1518-02-22 00:03] Guard #1021 begins shift
[1518-09-29 00:55] wakes up
[1518-06-26 00:09] falls asleep
[1518-06-29 00:46] falls asleep
[1518-11-17 23:59] Guard #1021 begins shift
[1518-05-23 00:01] Guard #1021 begins shift
[1518-08-05 23:57] Guard #3331 begins shift
[1518-03-29 00:45] wakes up
[1518-02-13 23:57] Guard #587 begins shift
[1518-03-10 00:59] wakes up
[1518-09-30 00:22] falls asleep
[1518-04-28 00:20] wakes up
[1518-03-12 23:59] Guard #2879 begins shift
[1518-10-09 00:38] falls asleep
[1518-06-21 00:57] wakes up
[1518-10-19 00:45] wakes up
[1518-08-12 00:50] falls asleep
[1518-07-24 00:05] falls asleep
[1518-10-29 00:48] falls asleep
[1518-08-26 00:50] wakes up
[1518-02-20 00:52] wakes up
[1518-06-16 23:47] Guard #1069 begins shift
[1518-06-06 00:17] falls asleep
[1518-11-03 00:00] Guard #2671 begins shift
[1518-07-24 00:50] wakes up
[1518-05-22 00:09] falls asleep
[1518-05-04 00:00] falls asleep
[1518-06-21 00:32] falls asleep
[1518-06-30 00:21] falls asleep
[1518-05-20 00:06] falls asleep
[1518-07-08 00:31] wakes up
[1518-03-21 00:25] falls asleep
[1518-09-05 23:57] Guard #1069 begins shift
[1518-03-10 23:47] Guard #2837 begins shift
[1518-08-30 00:41] wakes up
[1518-03-06 23:56] Guard #2837 begins shift
[1518-09-23 00:59] wakes up
[1518-11-09 00:34] wakes up
[1518-08-11 00:54] wakes up
[1518-04-14 00:52] falls asleep
[1518-04-30 00:52] wakes up
[1518-11-03 00:40] wakes up
[1518-02-21 00:03] falls asleep
[1518-05-19 00:05] falls asleep
[1518-02-22 00:12] falls asleep
[1518-03-31 00:53] wakes up
[1518-05-18 00:57] wakes up
[1518-04-12 00:33] falls asleep
[1518-03-10 00:23] falls asleep
[1518-03-06 00:00] falls asleep
[1518-09-25 00:17] falls asleep
[1518-07-28 00:41] wakes up
[1518-03-29 00:01] Guard #3251 begins shift
[1518-04-21 23:56] Guard #2971 begins shift
[1518-08-31 00:02] falls asleep
[1518-03-31 00:57] falls asleep
[1518-09-20 00:07] falls asleep
[1518-04-01 00:04] Guard #3433 begins shift
[1518-05-10 00:38] wakes up
[1518-04-03 00:32] wakes up
[1518-08-28 00:40] wakes up
[1518-05-12 00:54] wakes up
[1518-07-22 23:50] Guard #2801 begins shift
[1518-06-22 00:53] wakes up
[1518-07-04 00:48] wakes up
[1518-09-21 00:11] wakes up
[1518-11-09 00:27] falls asleep
[1518-04-08 00:32] falls asleep
[1518-07-17 00:00] Guard #587 begins shift
[1518-08-27 00:41] falls asleep
[1518-10-21 00:00] Guard #311 begins shift
[1518-10-05 00:49] falls asleep
[1518-09-10 00:00] Guard #3433 begins shift
[1518-07-28 00:26] wakes up
[1518-08-04 23:56] Guard #3109 begins shift
[1518-10-06 00:49] falls asleep
[1518-06-11 00:58] wakes up
[1518-09-08 00:02] Guard #163 begins shift
[1518-04-13 00:48] wakes up
[1518-06-18 00:02] Guard #311 begins shift
[1518-08-26 00:33] falls asleep
[1518-10-01 00:01] falls asleep
[1518-07-19 00:01] Guard #2837 begins shift
[1518-02-18 00:47] falls asleep
[1518-02-19 23:59] Guard #1021 begins shift
[1518-08-23 00:09] falls asleep
[1518-07-12 00:06] falls asleep
[1518-07-10 00:31] wakes up
[1518-03-29 00:07] wakes up
[1518-03-15 00:01] Guard #2179 begins shift
[1518-11-21 00:02] falls asleep
[1518-06-11 23:54] Guard #3251 begins shift
[1518-06-27 00:53] wakes up
[1518-03-03 00:04] Guard #311 begins shift
[1518-03-18 00:39] falls asleep
[1518-08-22 00:48] falls asleep
[1518-10-17 00:05] falls asleep
[1518-07-08 00:46] wakes up
[1518-09-23 00:00] Guard #89 begins shift
[1518-02-22 00:47] falls asleep
[1518-11-22 23:59] Guard #2971 begins shift
[1518-06-12 00:50] wakes up
[1518-04-18 00:46] wakes up
[1518-07-21 00:43] falls asleep
[1518-05-08 00:00] Guard #983 begins shift
[1518-04-30 00:56] falls asleep
[1518-09-19 00:42] wakes up
[1518-08-15 00:02] falls asleep
[1518-10-26 00:38] falls asleep
[1518-11-07 00:05] falls asleep
[1518-04-09 00:01] Guard #2179 begins shift
[1518-06-14 00:04] Guard #2971 begins shift
[1518-10-11 23:59] Guard #2971 begins shift
[1518-03-26 00:12] falls asleep
[1518-08-13 00:07] falls asleep
[1518-03-31 00:51] falls asleep
[1518-05-17 00:00] Guard #1069 begins shift
[1518-05-23 00:45] wakes up
[1518-08-30 00:59] wakes up
[1518-11-10 00:00] Guard #3433 begins shift
[1518-09-23 00:55] falls asleep
[1518-04-10 00:53] wakes up
[1518-11-06 23:52] Guard #2843 begins shift
[1518-09-14 00:50] falls asleep
[1518-11-09 00:49] wakes up
[1518-08-01 00:01] Guard #1069 begins shift
[1518-11-01 00:57] wakes up
[1518-10-18 00:16] falls asleep
[1518-02-28 23:59] Guard #2879 begins shift
[1518-11-05 00:11] falls asleep
[1518-10-22 00:22] falls asleep
[1518-03-06 00:28] falls asleep
[1518-07-13 23:46] Guard #311 begins shift
[1518-10-17 00:39] wakes up
[1518-04-25 00:09] falls asleep
[1518-05-07 00:39] falls asleep
[1518-02-19 00:01] Guard #983 begins shift
[1518-08-26 23:57] Guard #2879 begins shift
[1518-10-18 00:54] falls asleep
[1518-09-16 00:48] falls asleep
[1518-03-13 00:06] falls asleep
[1518-05-29 00:58] wakes up
[1518-11-18 00:50] falls asleep
[1518-10-07 00:29] wakes up
[1518-04-10 00:00] Guard #1069 begins shift
[1518-11-23 00:52] wakes up
[1518-11-03 23:57] Guard #2801 begins shift
[1518-08-30 23:50] Guard #3251 begins shift
[1518-09-08 00:58] wakes up
[1518-11-19 00:56] wakes up
[1518-03-27 00:41] wakes up
[1518-10-08 00:53] wakes up
[1518-10-14 00:02] Guard #2971 begins shift
[1518-11-15 00:40] wakes up
[1518-08-03 00:39] wakes up
[1518-10-23 23:59] Guard #89 begins shift
[1518-03-28 00:02] Guard #163 begins shift
[1518-06-03 00:51] falls asleep
[1518-08-19 00:07] falls asleep
[1518-09-10 00:13] falls asleep
[1518-04-22 00:52] falls asleep
[1518-03-01 00:27] falls asleep
[1518-05-16 00:45] wakes up
[1518-04-04 00:43] wakes up
[1518-02-27 00:39] wakes up
[1518-02-24 00:50] wakes up
[1518-10-21 00:38] wakes up
[1518-09-16 00:09] falls asleep
[1518-10-02 00:14] wakes up
[1518-07-07 00:11] falls asleep
[1518-09-25 23:56] Guard #2843 begins shift
[1518-03-17 00:19] falls asleep
[1518-10-23 00:47] wakes up
[1518-06-09 00:00] Guard #89 begins shift
[1518-09-26 00:45] wakes up
[1518-09-21 00:09] falls asleep
[1518-07-06 00:08] falls asleep
[1518-04-18 00:02] Guard #89 begins shift
[1518-02-23 00:02] falls asleep
[1518-06-22 00:30] falls asleep
[1518-06-14 00:11] falls asleep
[1518-08-26 00:49] falls asleep
[1518-04-10 00:11] falls asleep
[1518-10-01 23:51] Guard #3331 begins shift
[1518-11-18 23:56] Guard #3181 begins shift
[1518-07-18 00:29] falls asleep
[1518-05-30 00:15] falls asleep
[1518-08-29 23:46] Guard #163 begins shift
[1518-09-21 00:55] wakes up
[1518-10-09 00:43] wakes up
[1518-06-21 00:28] wakes up
[1518-09-18 00:34] wakes up
[1518-03-22 00:00] falls asleep
[1518-04-16 00:18] falls asleep
[1518-05-03 00:52] falls asleep
[1518-06-11 00:14] falls asleep
[1518-09-23 00:50] wakes up
[1518-03-08 23:58] Guard #3331 begins shift
[1518-05-15 00:04] Guard #163 begins shift
[1518-06-18 00:33] wakes up
[1518-09-17 23:57] Guard #311 begins shift
[1518-07-22 00:29] falls asleep
[1518-04-13 00:43] falls asleep
[1518-08-12 23:57] Guard #89 begins shift
[1518-10-23 00:38] falls asleep
[1518-06-04 00:59] wakes up
[1518-07-08 00:40] wakes up
[1518-03-16 00:42] falls asleep
[1518-08-13 00:47] wakes up
[1518-06-07 00:03] Guard #2879 begins shift
[1518-02-16 00:58] wakes up
[1518-05-25 00:40] wakes up
[1518-05-14 00:02] Guard #2671 begins shift
[1518-08-16 00:16] falls asleep
[1518-08-27 23:59] Guard #631 begins shift
[1518-10-07 00:00] Guard #2879 begins shift
[1518-06-25 00:59] wakes up
[1518-02-27 00:00] Guard #2801 begins shift
[1518-03-17 00:54] falls asleep
[1518-07-10 00:44] falls asleep
[1518-02-15 00:37] falls asleep
[1518-05-29 00:15] falls asleep
[1518-09-16 00:54] wakes up
[1518-07-05 23:59] Guard #2671 begins shift
[1518-04-18 00:23] falls asleep
[1518-08-24 00:58] wakes up
[1518-08-19 00:00] Guard #2837 begins shift
[1518-06-03 00:54] wakes up
[1518-05-17 00:34] falls asleep
[1518-04-09 00:23] falls asleep
[1518-10-10 23:57] Guard #2843 begins shift
[1518-03-24 00:59] wakes up
[1518-02-18 00:41] wakes up
[1518-10-25 00:48] falls asleep
[1518-02-28 00:53] wakes up
[1518-03-03 00:55] wakes up
[1518-04-01 00:36] falls asleep
[1518-02-24 00:39] wakes up
[1518-08-17 00:19] falls asleep
[1518-05-09 23:57] Guard #1579 begins shift
[1518-07-19 00:37] wakes up
[1518-10-18 00:57] wakes up
[1518-04-26 00:53] falls asleep
[1518-09-18 00:46] wakes up
[1518-04-22 00:54] wakes up
[1518-07-26 23:48] Guard #1069 begins shift
[1518-04-28 00:26] wakes up
[1518-06-08 00:45] falls asleep
[1518-10-31 00:47] falls asleep
[1518-05-13 00:53] wakes up
[1518-07-21 00:52] wakes up
[1518-09-09 00:32] falls asleep
[1518-08-02 00:34] falls asleep
[1518-02-27 00:09] wakes up
[1518-05-06 23:59] Guard #983 begins shift
[1518-03-17 00:57] wakes up
[1518-04-28 00:23] falls asleep
[1518-09-17 00:41] falls asleep
[1518-11-04 00:15] falls asleep
[1518-10-25 00:30] wakes up
[1518-08-09 00:57] wakes up
[1518-03-21 00:00] Guard #2671 begins shift
[1518-02-20 00:44] falls asleep
[1518-06-02 23:53] Guard #631 begins shift
[1518-05-31 00:01] Guard #2957 begins shift
[1518-09-24 00:21] falls asleep
[1518-06-21 23:52] Guard #1021 begins shift
[1518-06-16 00:35] falls asleep
[1518-10-07 23:57] Guard #3331 begins shift
[1518-04-22 00:08] falls asleep
[1518-09-21 00:04] Guard #3433 begins shift
[1518-10-04 00:19] falls asleep
[1518-04-02 00:00] Guard #2971 begins shift
[1518-08-13 00:57] falls asleep
[1518-08-06 00:39] falls asleep
[1518-03-05 23:52] Guard #2971 begins shift
[1518-06-04 00:15] falls asleep
[1518-04-03 00:51] falls asleep
[1518-09-18 23:51] Guard #3181 begins shift
[1518-10-15 00:15] falls asleep
[1518-09-11 00:54] wakes up
[1518-03-08 00:20] falls asleep
[1518-11-01 00:54] falls asleep
[1518-02-17 00:47] wakes up
[1518-06-29 00:02] falls asleep
[1518-10-19 00:27] falls asleep
[1518-09-10 23:59] Guard #311 begins shift
[1518-11-08 00:03] Guard #3109 begins shift
[1518-07-23 00:55] wakes up
[1518-09-04 00:51] wakes up
[1518-10-19 00:10] falls asleep
[1518-04-02 23:47] Guard #1069 begins shift
[1518-03-04 00:57] wakes up
[1518-09-13 00:52] wakes up
[1518-10-16 23:51] Guard #631 begins shift
[1518-10-07 00:09] falls asleep
[1518-05-23 00:50] falls asleep
[1518-04-26 23:48] Guard #2879 begins shift
[1518-10-21 00:42] falls asleep
[1518-07-13 00:54] wakes up
[1518-08-07 00:02] Guard #2957 begins shift
[1518-03-17 00:47] wakes up
[1518-07-28 00:01] Guard #2971 begins shift
[1518-08-22 00:59] wakes up
[1518-07-23 00:03] falls asleep
[1518-11-04 23:56] Guard #3331 begins shift
[1518-03-30 00:41] falls asleep
[1518-02-23 00:25] falls asleep
[1518-10-21 00:53] wakes up
[1518-07-10 23:57] Guard #631 begins shift
[1518-07-25 00:00] falls asleep
[1518-04-28 23:48] Guard #983 begins shift
[1518-05-21 00:00] Guard #631 begins shift
[1518-09-12 23:59] Guard #1069 begins shift
[1518-11-19 00:36] falls asleep
[1518-05-02 00:21] falls asleep
[1518-04-13 00:03] Guard #2179 begins shift
[1518-11-05 00:56] wakes up
[1518-08-14 00:06] falls asleep
[1518-09-23 00:40] falls asleep
[1518-11-12 00:17] falls asleep
[1518-04-02 00:53] wakes up
[1518-05-04 00:56] wakes up
[1518-04-13 00:26] falls asleep
[1518-10-21 23:59] Guard #311 begins shift
[1518-04-07 00:00] Guard #1021 begins shift
[1518-10-10 00:55] wakes up
[1518-05-03 00:45] wakes up
[1518-03-24 00:29] falls asleep
[1518-06-27 00:15] falls asleep
[1518-11-12 00:00] Guard #1069 begins shift
[1518-04-04 23:56] Guard #1021 begins shift
[1518-04-05 00:06] falls asleep
[1518-10-31 00:58] wakes up
[1518-04-29 00:47] wakes up
[1518-09-14 00:53] wakes up
[1518-11-20 00:04] Guard #311 begins shift
[1518-07-04 23:46] Guard #1579 begins shift
[1518-06-02 00:08] falls asleep
[1518-03-15 23:59] Guard #163 begins shift
[1518-08-14 00:40] wakes up
[1518-05-26 23:57] Guard #2179 begins shift
[1518-07-06 00:29] falls asleep
[1518-04-21 00:56] wakes up
[1518-02-16 00:48] wakes up
[1518-04-17 00:40] wakes up
[1518-08-21 00:02] Guard #3433 begins shift
[1518-05-18 00:04] Guard #3181 begins shift
[1518-05-24 00:03] Guard #2957 begins shift
[1518-09-09 00:44] wakes up
[1518-02-21 00:50] wakes up
[1518-07-13 00:02] Guard #163 begins shift
[1518-03-12 00:21] wakes up
[1518-09-03 23:58] Guard #983 begins shift
[1518-09-14 00:10] wakes up
[1518-10-31 00:13] falls asleep
[1518-04-15 00:00] Guard #3251 begins shift
[1518-07-14 00:00] falls asleep
[1518-02-22 00:33] wakes up
[1518-09-28 00:58] wakes up
[1518-04-25 00:03] Guard #1069 begins shift
[1518-04-13 00:39] wakes up
[1518-07-31 00:04] Guard #3331 begins shift
[1518-06-30 00:59] wakes up
[1518-06-01 00:53] falls asleep
[1518-10-28 00:49] wakes up
[1518-07-01 23:57] Guard #89 begins shift
[1518-04-29 00:52] falls asleep
[1518-02-17 00:36] falls asleep
[1518-03-23 00:51] wakes up
[1518-09-07 00:00] falls asleep
[1518-11-02 00:52] wakes up
[1518-09-01 00:01] falls asleep
[1518-07-17 00:14] falls asleep
[1518-05-11 00:36] wakes up
[1518-08-03 00:02] falls asleep
[1518-10-03 23:59] Guard #89 begins shift
[1518-03-15 00:41] wakes up
[1518-07-12 00:50] wakes up
[1518-08-21 00:58] wakes up
[1518-07-10 00:49] wakes up
[1518-06-19 00:05] falls asleep
[1518-05-30 00:29] wakes up
[1518-10-15 00:27] wakes up
[1518-02-13 00:55] wakes up
[1518-05-17 00:51] wakes up
[1518-06-09 00:58] wakes up
[1518-08-23 23:59] Guard #2671 begins shift
[1518-05-31 23:59] Guard #311 begins shift
[1518-08-20 00:34] falls asleep
[1518-07-20 00:37] wakes up
[1518-02-23 00:19] wakes up
[1518-04-21 00:32] wakes up
[1518-06-07 00:50] wakes up
[1518-07-09 00:24] falls asleep
[1518-10-28 23:59] Guard #631 begins shift
[1518-03-02 00:02] falls asleep
[1518-03-19 00:56] falls asleep
[1518-02-20 00:17] falls asleep
[1518-02-16 23:56] Guard #3331 begins shift
[1518-06-14 00:23] wakes up
[1518-03-22 00:55] falls asleep
[1518-10-19 23:48] Guard #587 begins shift
[1518-03-09 23:56] Guard #1579 begins shift
[1518-11-12 00:38] wakes up
[1518-07-28 00:36] falls asleep
[1518-09-26 00:25] falls asleep
[1518-07-21 00:56] falls asleep
[1518-07-12 00:46] falls asleep
[1518-05-04 00:48] falls asleep
[1518-09-10 00:59] wakes up
[1518-06-23 00:40] falls asleep
[1518-07-26 00:48] wakes up
[1518-08-02 00:53] falls asleep
[1518-06-17 00:58] wakes up
[1518-05-13 00:29] falls asleep
[1518-03-31 00:44] falls asleep
[1518-03-04 00:38] wakes up
[1518-09-05 00:03] falls asleep
[1518-09-16 00:31] wakes up
[1518-07-19 00:41] falls asleep
[1518-08-25 00:59] wakes up
[1518-06-22 00:27] wakes up
[1518-03-17 00:03] Guard #2843 begins shift
[1518-10-22 23:59] Guard #631 begins shift
[1518-10-24 00:24] falls asleep
[1518-07-17 00:55] wakes up
[1518-11-16 00:00] Guard #1069 begins shift
[1518-03-31 00:46] wakes up
[1518-03-09 00:07] falls asleep
[1518-05-21 00:42] wakes up
[1518-06-16 00:03] Guard #2843 begins shift
[1518-07-30 00:55] wakes up
[1518-05-18 00:36] wakes up
[1518-11-15 00:04] Guard #2879 begins shift
[1518-09-20 00:53] falls asleep
[1518-09-22 00:02] Guard #3109 begins shift
[1518-04-28 00:09] falls asleep
[1518-08-18 00:12] wakes up
[1518-04-25 00:52] wakes up
[1518-08-14 23:49] Guard #2837 begins shift
[1518-11-23 00:16] falls asleep
[1518-10-08 00:24] falls asleep
[1518-10-20 00:00] falls asleep
[1518-06-07 00:44] falls asleep
[1518-06-25 00:18] falls asleep
[1518-10-11 00:35] wakes up
[1518-11-09 00:37] falls asleep
[1518-06-28 23:53] Guard #1021 begins shift
[1518-08-22 00:04] wakes up
[1518-07-08 00:43] falls asleep
[1518-03-12 00:17] falls asleep
[1518-10-15 00:56] falls asleep
[1518-11-10 00:38] falls asleep
[1518-02-12 00:48] wakes up
[1518-10-08 00:14] falls asleep
[1518-11-17 00:29] falls asleep
[1518-08-04 00:37] falls asleep
[1518-10-12 00:34] wakes up
[1518-08-08 00:04] falls asleep
[1518-08-01 00:42] wakes up
[1518-09-11 00:46] falls asleep
[1518-09-25 00:18] wakes up
[1518-02-11 00:19] wakes up
[1518-03-20 00:04] falls asleep
[1518-05-25 00:56] falls asleep
[1518-04-06 00:21] falls asleep
[1518-06-20 00:52] wakes up
[1518-05-28 00:43] wakes up
[1518-03-23 23:58] Guard #2879 begins shift
[1518-08-15 00:50] wakes up
[1518-03-07 23:57] Guard #2879 begins shift
[1518-07-25 23:59] Guard #3181 begins shift
[1518-08-02 23:52] Guard #2879 begins shift
[1518-07-23 23:49] Guard #1021 begins shift
[1518-10-18 00:48] wakes up
[1518-04-23 00:55] wakes up
[1518-04-02 00:21] falls asleep
[1518-06-11 00:02] Guard #3331 begins shift
[1518-06-24 00:34] falls asleep
[1518-04-04 00:53] wakes up
[1518-04-09 00:33] wakes up
[1518-06-29 00:52] wakes up
[1518-05-12 00:20] falls asleep
[1518-05-27 00:59] wakes up
[1518-04-11 00:42] wakes up
[1518-09-01 00:58] wakes up
[1518-10-07 00:37] wakes up
[1518-04-11 23:58] Guard #2179 begins shift
[1518-11-20 00:57] falls asleep
[1518-03-30 00:29] falls asleep
[1518-04-14 00:46] wakes up
[1518-07-16 00:33] falls asleep
[1518-04-30 00:59] wakes up
[1518-03-01 00:44] wakes up
[1518-10-06 00:59] wakes up
[1518-05-02 00:00] Guard #1069 begins shift
[1518-06-08 00:53] wakes up
[1518-07-16 00:59] wakes up
[1518-05-06 00:39] wakes up
[1518-06-29 00:42] wakes up
[1518-02-18 00:51] wakes up
[1518-03-03 00:24] falls asleep
[1518-08-04 00:58] wakes up
[1518-08-12 00:35] falls asleep
[1518-03-27 00:36] falls asleep
[1518-05-04 23:58] Guard #1579 begins shift
[1518-03-25 00:10] falls asleep
[1518-06-19 23:57] Guard #631 begins shift
[1518-02-24 00:44] falls asleep
[1518-10-26 00:57] wakes up
[1518-03-14 00:44] wakes up
[1518-11-06 00:31] falls asleep
[1518-11-22 00:52] falls asleep
[1518-09-11 00:32] falls asleep
[1518-06-20 00:49] falls asleep
[1518-07-03 23:51] Guard #1021 begins shift
[1518-09-18 00:45] falls asleep
[1518-06-24 23:57] Guard #1021 begins shift
[1518-03-30 00:34] wakes up
[1518-03-07 00:45] wakes up
[1518-10-24 23:58] Guard #3331 begins shift
[1518-11-18 00:41] wakes up
[1518-02-20 00:37] wakes up
[1518-08-16 23:59] Guard #2971 begins shift
[1518-03-18 23:58] Guard #2801 begins shift
[1518-07-01 00:42] wakes up
[1518-04-05 00:54] wakes up
[1518-02-12 00:09] falls asleep
[1518-06-26 00:31] wakes up
[1518-05-01 00:00] Guard #3109 begins shift
[1518-08-08 00:59] wakes up
[1518-10-09 00:52] falls asleep
[1518-06-09 00:22] falls asleep
[1518-07-20 00:52] wakes up
[1518-09-30 23:50] Guard #2879 begins shift
[1518-11-11 00:33] wakes up
[1518-04-04 00:46] falls asleep
[1518-08-25 00:22] falls asleep
[1518-04-19 23:58] Guard #2063 begins shift
[1518-07-15 00:02] Guard #3109 begins shift
[1518-05-30 00:54] falls asleep
[1518-05-29 00:42] wakes up
[1518-04-17 00:01] Guard #3433 begins shift
[1518-03-19 00:35] wakes up
[1518-11-01 00:51] wakes up
[1518-02-26 00:55] wakes up
[1518-03-26 00:36] wakes up
[1518-10-18 00:39] falls asleep
[1518-03-04 00:43] falls asleep
[1518-06-15 00:52] falls asleep
[1518-10-16 00:02] Guard #2837 begins shift
[1518-06-01 00:30] wakes up
[1518-10-28 00:42] falls asleep
[1518-03-29 00:36] falls asleep
[1518-04-15 00:14] falls asleep
[1518-04-15 00:48] wakes up
[1518-08-17 00:30] wakes up
[1518-05-28 00:20] falls asleep
[1518-05-20 00:03] Guard #3251 begins shift
[1518-09-06 00:16] falls asleep
[1518-11-12 23:57] Guard #1579 begins shift
[1518-08-10 00:46] wakes up
[1518-08-02 00:56] wakes up
[1518-10-10 00:02] Guard #1021 begins shift
[1518-11-17 00:44] falls asleep
[1518-09-05 00:37] wakes up
[1518-08-13 00:58] wakes up
[1518-02-18 00:12] falls asleep
[1518-06-17 00:01] falls asleep
[1518-04-29 00:56] wakes up
[1518-07-01 00:03] Guard #3331 begins shift
[1518-08-06 00:47] falls asleep
[1518-05-29 00:00] Guard #311 begins shift
[1518-11-01 00:00] Guard #311 begins shift
[1518-03-04 23:58] Guard #1069 begins shift
[1518-06-04 00:01] Guard #3331 begins shift
[1518-07-05 00:13] wakes up
[1518-07-24 23:47] Guard #163 begins shift
shifts