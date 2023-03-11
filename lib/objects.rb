$debug = true

class Object
  def exclude?(value)
    !include?(value)
  end

  def non_objects_caller
    caller.reject { |line| line.include?("advent/lib/objects") }.first
  end

  def plop(prefix: "", show_header: true)
    return self unless $debug
    puts non_objects_caller if show_header
    puts non_objects_caller.gsub(/./, "-") if show_header
    print prefix
    puts self
    self
  end

  def plopp(prefix: "", show_header: true)
    return self unless $debug
    puts non_objects_caller if show_header
    puts non_objects_caller.gsub(/./, "-") if show_header
    print prefix
    p self
    self
  end

  def debug(level = "DEBUG", *args, **kwargs)
    return unless $debug

    puts non_objects_caller
    puts non_objects_caller.gsub(/./, "-")

    print "  #{level}"
    print " -> " unless args.empty? && kwargs.empty?
    print args.map(&:inspect).join(", ") unless args.empty?
    print kwargs unless kwargs.empty?
    puts
  end

  def only!
    return filter { |v| yield(v) }.only! if block_given?
    assert_size!.first
  end

  def assert_size!(expected = 1)
    assert!(size == expected, "Expected size #{expected} but got #{size}")
  end

  def assert!(condition, message = "")
    tap { raise message unless condition }
  end

  def assert_equals!(thing1, thing2, message = "")
    tap { raise <<~assertion unless thing1 == thing2 }
        #{message}:

        expected

        #{thing1}

        to equal

        #{thing2}

        assertion
  end
end

class Class
  def memoize(name)
    method = instance_method(name)

    define_method(name) do |*arg|
      @__memo ||= {}
      @__memo[name] ||= {}
      @__memo[name][arg] ||= method.bind(self).call(*arg)
    end
  end

  def memoize_class(name)
    method = instance_method(name)

    define_method(name) do |*arg|
      @@__memo ||= {}
      @@__memo[name] ||= {}
      @@__memo[name][arg] ||= method.bind(self).call(*arg)
    end
  end
end

class String
  def darken_squares
    gsub("#", "█").gsub(".", " ")
  end
end

class Numeric
  def to(other)
    self < other ? upto(other) : downto(other)
  end
end
