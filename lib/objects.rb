$_debug = true

class Object
  def exclude?(value)
    !include?(value)
  end

  def non_objects_caller
    caller.reject { |line| line.include?("advent/lib/objects") }.first
  end

  def plop(prefix: "", show_header: true)
    return self unless $_debug
    puts non_objects_caller if show_header
    puts non_objects_caller.gsub(/./, "-") if show_header
    print prefix
    puts self
    self
  end

  def plopp(prefix: "", show_header: true)
    return self unless $_debug
    puts non_objects_caller if show_header
    puts non_objects_caller.gsub(/./, "-") if show_header
    print prefix
    p self
    self
  end

  def _debug(level = "_debug", *args, **kwargs)
    return unless $_debug

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

    define_method(name) do |*arg, **kwarg|
      @__memo ||= {}
      @__memo[name] ||= {}
      @__memo[name][[arg, kwarg]] ||= method.bind(self).call(*arg, **kwarg)
    end
  end

  def memoize_class(name)
    method = instance_method(name)

    define_method(name) do |*arg, **kwarg|
      @@__memo ||= {}
      @@__memo[name] ||= {}
      @@__memo[name][arg, kwarg] ||= method.bind(self).call(*arg, **kwarg)
    end
  end

  def shape(*variable_names, **defaults)
    variable_definitions =
      variable_names
        .map do |name|
          "@#{name} = params[:#{name}]" +
            (defaults[name] ? "|| #{defaults[name]}" : "")
        end
        .join(" ; ")
    body = <<~body
        attr_reader #{variable_names.map(&:inspect).join(", ")}
        def initialize(**params)
          #{variable_definitions}
        end

        def self.[](**args)
          new(**args)
        end

        def [](key)
          raise NotImplementedError unless respond_to?(key)
          send(key)
        end

        def to_s
          "\#{self.class.name}(" +
            #{variable_names.map { |name| "\"#{name}=\#{#{name}}" }.join(", \"+ \n")}\" +
          ")"
        end

        def is_shape? = true
      body
    self.class_eval(body)
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

  def square
    self * self
  end

  def sign
    self <=> 0
  end
end

Identity = ->(x) { x }

class NilClass
  def option_map(&block)
    nil
  end
end

class Object
  def option_map(&block)
    block.call(self)
  end
end
