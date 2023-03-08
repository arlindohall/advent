module RootDirectory
  protected

  def root_directory
    Pathname.new(__FILE__).parent.parent
  end
end

class Problem
  include RootDirectory

  def initialize(year, day)
    @year = year
    @day = day
  end

  FIRST_DAY = Problem.new(15, 1)

  def self.current
    problem = FIRST_DAY
    problem = problem.next until problem.current?

    problem
  end

  def self.next
    current.next
  end

  def create_file
    pathname.mkpath
    solution_file.write("")
    code
    download_input
  end

  def code
    system("open #{solution_file}")
  end

  def download_input
    pathname.mkpath
    input_file.write(input)
  end

  def paste_example
    pathname.mkpath
    latest_example.write($stdin.read)
  end

  def latest_example
    return example_file unless example_file.exist?

    n = 1
    n += 1 while example_file(n).exist?

    example_file(n)
  end

  def current?
    exists? && !self.next.exists?
  end

  def solution_file
    pathname.join("solution.rb")
  end

  def input_file
    pathname.join("input.txt")
  end

  def example_file(n = nil)
    pathname.join("example#{n}.txt")
  end

  def next
    return next_year if day == 25

    next_day
  end

  def to_s
    pathname.to_s
  end

  protected

  def exists?
    File.exist?(pathname)
  end

  private

  attr_reader :year, :day

  def pathname
    Pathname.new(root_directory).join(year.to_s).join(day.to_s)
  end

  def next_day
    Problem.new(year, day + 1)
  end

  def next_year
    Problem.new(year + 1, 1)
  end

  def input
    `curl https://adventofcode.com/20#{year}/day/#{day}/input \
      --http1.1 \
      -H 'cookie: #{cookie}'`
  end

  def cookie
    pathname.parent.parent.join(".cookie").read
  end
end

class Repl
  include RootDirectory

  def initialize(problem)
    @problem = problem
  end

  def self.run(commands)
    new(Problem.current).run(commands)
  end

  def run(commands)
    unless commands.empty?
      run_once(commands)
      exit $?.exitstatus
    end

    puts "Starting REPL for #{problem.to_s}"
    loop { return unless system(repl) }
  end

  private

  attr_reader :problem

  def run_once(commands)
    system(%Q(ruby -e '#{run_once_requires} ; #{commands.join(" ")}'))
  end

  def repl
    %Q(irb -r "#{input_helper}" -r"#{arrays_helper}" -r"#{objects_helper}" -r "#{problem.solution_file}" -r "pry")
  end

  def run_once_requires
    [
      input_helper,
      arrays_helper,
      objects_helper,
      "pry",
      "pathname",
      problem.solution_file
    ].map { |file| %Q(require "#{file}") }.join(" ; ")
  end

  def input_helper
    lib("input.rb")
  end

  def arrays_helper
    lib("arrays.rb")
  end

  def objects_helper
    lib("objects.rb")
  end

  def lib(name)
    root_directory.join("lib").join(name)
  end
end
