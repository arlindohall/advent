
Step = Struct.new(:name, :dependents, :parents)
Job = Struct.new(:step, :time)

class Step
  def time(extra_time = 0)
    name.to_s.downcase.ord - 'a'.ord + 1 + extra_time
  end
end

class Instructions
  def initialize(steps)
    @steps = steps
  end

  def self.of(text)
    steps = Hash.new { |h, k| h[k] = Step.new(k, [], []) }

    text.split("\n").each { |line|
      name, dependent = /Step (\w) must be finished before step (\w) can begin./
          .match(line)
          .captures
          .map(&:to_sym)

      steps[name].dependents << dependent
      steps[dependent].parents << name
    }

    new(steps)
  end

  def write_file
    File.write("graph.dot", graph)
    %x(dot -Tpng graph.dot > graph.png)
  end

  def clean_file
    %x(rm graph.dot graph.png)
  end

  def graph
    <<-graph
      digraph {
        #{@steps.values.flat_map{ |step|
          step.dependents.map{ |dependent|
            "#{step.name} -> #{dependent};\n"
          }
        }.join}
      }
    graph
  end

  def solve
    [order.join, process_time]
  end

  def order
    @next_steps, @order = first.sort, []
    while @next_steps.any?
      add_step
    end
    @order
  end

  def first
    @steps.filter{ |_name, step| step.parents.empty? }
      .map{ |name, _step| name }
  end

  def add_step
    step = next_step
    @order << step.name if !@order.include?(step.name)
    step.dependents
      .reject{ |dependent| @order.include?(dependent) }
      .each{ |dependent| @next_steps << dependent }
  end

  def next_step
    @steps[@next_steps.delete(available_steps.first)] if available_steps.any?
  end

  def available_steps
    @next_steps.sort
      .uniq
      .filter { |step|
        @steps[step].parents.all?{ |parent| @order.include?(parent) }
      }
  end

  ##################################################
  ####################### PART 2 ###################
  ##################################################

  def process_time(workers = 5, extra_time = 60)
    @workers, @extra_time = workers, extra_time
    @next_steps, @jobs, @order, @time = first.sort, [], [], 0
    loop do
      decrement_timers
      remove_finished
      process_available_steps
      return @time if @next_steps.empty? && @jobs.empty?
      @time += 1
    end
  end

  def decrement_timers
    @jobs.each{ |job| job.time -= 1 }
  end

  def remove_finished
    @jobs.dup.each{ |job|
      remove_job(job) if job.time == 0
    }
  end

  def remove_job(job)
    @jobs.delete(job)
    @order << job.step.name
    job.step
      .dependents
      .each{ |child| @next_steps << child }
  end

  def process_available_steps
    available_workers.times {
      step = next_step
      job = Job.new(step, step.time(@extra_time)) if step
      @jobs << job if job
    }
  end

  def available_workers
    @workers - @jobs.count
  end
end

@example = <<-inst
Step C must be finished before step A can begin.
Step C must be finished before step F can begin.
Step A must be finished before step B can begin.
Step A must be finished before step D can begin.
Step B must be finished before step E can begin.
Step D must be finished before step E can begin.
Step F must be finished before step E can begin.
inst

@input = <<-inst
Step X must be finished before step Q can begin.
Step Y must be finished before step P can begin.
Step U must be finished before step F can begin.
Step V must be finished before step S can begin.
Step G must be finished before step R can begin.
Step T must be finished before step P can begin.
Step O must be finished before step D can begin.
Step R must be finished before step I can begin.
Step M must be finished before step F can begin.
Step L must be finished before step C can begin.
Step K must be finished before step H can begin.
Step D must be finished before step H can begin.
Step I must be finished before step W can begin.
Step S must be finished before step C can begin.
Step J must be finished before step Z can begin.
Step B must be finished before step A can begin.
Step A must be finished before step W can begin.
Step W must be finished before step F can begin.
Step P must be finished before step E can begin.
Step C must be finished before step Q can begin.
Step E must be finished before step Z can begin.
Step Q must be finished before step F can begin.
Step Z must be finished before step F can begin.
Step N must be finished before step H can begin.
Step H must be finished before step F can begin.
Step N must be finished before step F can begin.
Step K must be finished before step D can begin.
Step P must be finished before step F can begin.
Step Q must be finished before step Z can begin.
Step G must be finished before step W can begin.
Step E must be finished before step N can begin.
Step R must be finished before step Z can begin.
Step V must be finished before step R can begin.
Step Q must be finished before step N can begin.
Step U must be finished before step L can begin.
Step P must be finished before step N can begin.
Step S must be finished before step Q can begin.
Step G must be finished before step S can begin.
Step U must be finished before step E can begin.
Step M must be finished before step I can begin.
Step A must be finished before step N can begin.
Step W must be finished before step H can begin.
Step J must be finished before step A can begin.
Step M must be finished before step S can begin.
Step T must be finished before step I can begin.
Step E must be finished before step Q can begin.
Step C must be finished before step Z can begin.
Step B must be finished before step H can begin.
Step J must be finished before step F can begin.
Step G must be finished before step E can begin.
Step Q must be finished before step H can begin.
Step T must be finished before step B can begin.
Step V must be finished before step B can begin.
Step R must be finished before step F can begin.
Step V must be finished before step H can begin.
Step K must be finished before step N can begin.
Step A must be finished before step H can begin.
Step S must be finished before step E can begin.
Step I must be finished before step N can begin.
Step V must be finished before step I can begin.
Step M must be finished before step E can begin.
Step U must be finished before step G can begin.
Step J must be finished before step N can begin.
Step T must be finished before step K can begin.
Step D must be finished before step N can begin.
Step L must be finished before step S can begin.
Step P must be finished before step Z can begin.
Step X must be finished before step S can begin.
Step B must be finished before step W can begin.
Step R must be finished before step M can begin.
Step W must be finished before step Q can begin.
Step A must be finished before step Z can begin.
Step A must be finished before step F can begin.
Step G must be finished before step T can begin.
Step S must be finished before step A can begin.
Step J must be finished before step E can begin.
Step Y must be finished before step N can begin.
Step D must be finished before step J can begin.
Step D must be finished before step S can begin.
Step M must be finished before step W can begin.
Step U must be finished before step T can begin.
Step E must be finished before step H can begin.
Step S must be finished before step W can begin.
Step T must be finished before step C can begin.
Step A must be finished before step P can begin.
Step U must be finished before step V can begin.
Step U must be finished before step J can begin.
Step L must be finished before step B can begin.
Step L must be finished before step N can begin.
Step J must be finished before step C can begin.
Step L must be finished before step Q can begin.
Step K must be finished before step B can begin.
Step G must be finished before step H can begin.
Step W must be finished before step Z can begin.
Step C must be finished before step E can begin.
Step B must be finished before step Q can begin.
Step O must be finished before step Z can begin.
Step L must be finished before step J can begin.
Step R must be finished before step N can begin.
Step J must be finished before step P can begin.
Step Y must be finished before step F can begin.
inst