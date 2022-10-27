#!/usr/bin/env ruby

require 'pathname'

class Root
  def initialize
    @path = Pathname.new(__FILE__).parent
  end

  def repl
    this_year.this_day.repl
  end

  def this_year
    return Year.first if years.empty?
    return smallest_empty if smallest_empty
    return largest_full if all_full?

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
    possible_years.filter do |year|
      !exists?(year)
    end
  end

  def exists?(year)
    years.any? do |y|
      y.number == year.number
    end
  end

  def possible_years
    years.first.number.upto(years.last.number).map do |number|
      Year.new(@path.join(number.to_s))
    end
  end

  def years
    @path.children.filter do |child|
      is_year?(child.basename)
    end.map{|c| Year.new(c)}
       .sort_by(&:number)
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

  def this_day
    if !@path.exist?
      return Day.new(@path.join('1'))
    end

    latest_day
  end

  def latest_day
    days.sort_by(&:number).last
  end

  def full?
    days.count == 25
  end

  def days
    return [] if !@path.exist?
    @path.children.map{|c| Day.new(c)}
  end

  def exists?(day)
    days.any? do |d|
      d.number == day.number
    end
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

  def repl
    return run_once unless ARGV.empty?

    puts "Starting REPL for #{@path}"
    loop do
      return unless system(repl_command)
    end
  end

  def repl_command
    "irb -r \"#{@path.join("solution.rb").to_s}\""
  end

  def run_once
    system("ruby -e 'require \"#{@path.join("solution.rb").to_s}\" ; #{ARGV.join(" ")}'")
  end
end

Root.new.repl
