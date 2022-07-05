#!/usr/bin/env ruby

require 'pathname'

class Root
  def initialize
    @path = Pathname.new(__FILE__).parent
  end

  def make_day
    add_day.create_file
  end

  def add_day
    this_year.add_day
  end

  def this_year
    return Year.first if years.empty?
    return first_gap if true_gap?
    return smallest_empty if smallest_empty
    return largest_full.next_year if all_full?

    raise "Impossible situation: found some years," \
      "but none are either empty or full: years=#{years.map(&:path).map(&:to_s).sort_by(&:to_i)}"
  end

  def smallest_empty
    years.sort_by(&:number).filter do |year|
      !year.full?
    end.first
  end

  def largest_full
    years.sort_by(&:number).filter do |year|
      year.full?
    end.last
  end

  def first_gap
    untouched_years.first
  end

  def untouched_years
    possible_years - years
  end

  def possible_years
    years.first.number.upto(years.last.number).map do |number|
      Year.new(@path.join(number.to_s))
    end
  end

  def next_year
    if years.empty?
      Year.first
    else
      this_year.next_year
    end
  end

  def years
    @path.children.filter do |child|
      is_year?(child.basename)
    end.map{|c| Year.new(c)}
       .sort_by(&:number)
  end

  def number
    @path.basename.to_s.to_i
  end

  def all_full?
    untouched_years.empty?
  end

  def true_gap?
    return false if first_gap.nil?
    return true if smallest_empty.nil?

    # A true gap is a gap between the first year and the smallest empty year
    # If the smallest empty year is lower than the gap, though, then we start
    # there
    first_gap.number < smallest_empty.number
  end

  def is_year?(name)
    Year::FIRST_YEAR.upto(99).include?(name.to_s.to_i)
  end
end

class Year
  FIRST_YEAR = 15

  attr_reader :path

  def initialize(path)
    @path = path
  end

  def number
    @path.basename.to_s.to_i
  end

  def add_day
    if !@path.exist?
      return Day.new(@path.join('1'))
    end

    next_day
  end

  def next_year
    Year.new(@path.parent.join((number+1).to_s))
  end

  def next_day
    first_unfinished_day
  end

  def first_unfinished_day
    unfinished_days.sort_by(&:number).first
  end

  def unfinished_days
    possible_days.filter do |day|
      !days.include?(day)
    end
  end

  def possible_days
    1.upto(25).map do |day|
      Day.new(@path.join(day.to_s))
    end
  end

  def full?
    days.count == 25
  end

  def days
    return [] if !@path.exist?
    @path.children.map{|c| Day.new(c)}
  end

  class << self
    def first
      @@first ||= Year.new(Pathname.new(::FIRST_YEAR.to_s))
    end
  end
end

class Day
  attr_reader :path
  def initialize(path)
    @path = path
  end

  def number
    @path.basename.to_s.to_i
  end

  def next_day
    Day.new(@path.parent.join((number+1).to_s))
  end

  def create_file
    @path.mkpath
    @path.join('solution.rb').write('')
  end
end

Root.new.make_day
