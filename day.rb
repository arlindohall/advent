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
    if this_year.full?
      next_year.add_day
    else
      this_year.add_day
    end
  end

  def this_year
    return Year.first if years.empty?
    return largest_full.next_year if largest_full
    return smallest_empty

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
  end

  def is_year?(name)
    Year::FIRST_YEAR.upto(99).include?(name.to_s.to_i)
  end
end

class Year
  # Coming back to do 2015, change this
  FIRST_YEAR = 16

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
    this_day.next_day
  end

  def full?
    days.count == 25
  end

  def this_day
    days.max_by(&:number)
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
