# ChaosDetector::Utils.naught?("")
# ChaosDetector::Utils.naught?(0)
# ChaosDetector::Utils.naught?([])
# ChaosDetector::Utils.naught?("foobar")
# ChaosDetector::Utils.naught?(0)
# ChaosDetector::Utils.naught?([])
# module ChaosDetector

def Kernel.with(obj)
  ChaosDetector::Utils::with(obj) {yield obj}
end

def Kernel.naught?(obj)
  ChaosDetector::Utils::naught?(obj)
end

def Kernel.ought?(obj)
  !ChaosDetector::Utils::naught?(obj)
end

def decorate(text, *args)
  ChaosDetector::Utils::decorate(text, *args)
end


# = ChaosDetector::Utils::with
module ChaosDetector::Utils
  STR_INDENT = '  '.freeze
  STR_BLANK = ''.freeze

  class << self

    def enum(*values)
      Module.new do |mod|
        values.each_with_index do |v,i|
          mod.const_set(v.to_s.upcase, v.to_s.downcase.to_sym)
          # mod.const_set(v.to_s.upcase, 2**i)
        end

        def mod.values
          self.constants
        end
      end
    end

    def naught?(obj)
      if obj.nil?
        true
      elsif obj.is_a?(FalseClass)
        true
      elsif obj.is_a?(TrueClass)
        false
      elsif obj.is_a?(String)
        obj.strip.empty?
      elsif obj.is_a?(Enumerable)
        obj.empty?
      elsif obj.is_a?(Numeric)
        obj == 0
      end
    end

    def with(obj)
      raise ArgumentError("assert requires block") unless block_given?
      yield obj if obj
    end

    def assert(expected_result=true, msg=nil, &block)
      raise ArgumentError("assert requires block") unless block_given?

      unless block.call==expected_result
        # raise "Assertion failed.  #{msg}\n\t#{caller_locations(1,5)}"
        raise "Assertion failed.  #{msg}\n\t#{block.source_location}"
      end
    end

    def decorate_pair(source, dest, indent_length: 0, clamp: :brace)
      decorate("#{decorate(source)} -> #{decorate(dest)}", clamp:clamp, indent_length:indent_length)
    end

    def decorate(text, clamp: :brace, prefix: nil, suffix: nil, sep: nil, indent_length: 0)
      return STR_BLANK if naught?text

      clamp_pre, clamp_post = clamp_chars(clamp: clamp)
      indent("#{prefix}#{sep}#{clamp_pre}#{text}#{clamp_post}#{sep}#{suffix}", indent_length)
    end

    alias_method :d, :decorate

    def clamp_chars(clamp: :brace)
      case(clamp)
        when :angle, :arrow
          ['<', '>']
        when :brace
          ['{', '}']
        when :bracket
          ['[', ']']
        when :italic, :emphasize
          ['_', '_']
        when :strong, :bold, :stars
          ['**', '**']
        when :quotes, :double_quotes
          ['"', '"']
        when :ticks, :single_quotes
          ["'", "'"]
        when :none
          [STR_BLANK, STR_BLANK]
        else # :parens, :parentheses
          ['(', ')']
      end
    end

    def indent(text, indent_length=1)
      return STR_BLANK if naught?text
      return text unless indent_length

      "#{STR_INDENT * indent_length}#{text}"
    end

    # Simple logging, more later
    def log(msg, subject: nil)
      message = naught?(subject) ? msg : d(msg, prefix:d(subject, clamp: :bracket))
      if block_given?
        p(decorate(message, prefix: 'Starting: '))
        result = yield
        p(d(message, prefix: 'Complete: ', suffix: d(result)))
      else
        p(message)
      end
    end

    # Built-in self-testing:
    # ChaosDetector::Utils.test
    def test
      log("Testing ChaosDetector::Utils") do
        assert(true, 'Naught detects blank string'){ChaosDetector::Utils.naught?("")}
        assert(true, 'Naught detects blank string with space'){ChaosDetector::Utils.naught?(" ")}
        assert(true, 'Naught detects int 0'){ChaosDetector::Utils.naught?(0)}
        assert(true, 'Naught detects float 0.0'){ChaosDetector::Utils.naught?(0.0)}
        assert(true, 'Naught detects empty array'){ChaosDetector::Utils.naught?([])}
        assert(true, 'Naught detects empty hash'){ChaosDetector::Utils.naught?({})}
        assert(false, 'Naught real string'){ChaosDetector::Utils.naught?("foobar")}
        assert(false, 'Naught non-zero int'){ChaosDetector::Utils.naught?(1)}
        assert(false, 'Naught non-zero float'){ChaosDetector::Utils.naught?(33.33)}
        assert(false, 'Naught non-empty array'){ChaosDetector::Utils.naught?(['stuff'])}
        assert(false, 'Naught non-empty hash'){ChaosDetector::Utils.naught?({foo: 'bar'})}
      end
    end
  end

  module ChaosAttr
    def chaos_attr(attribute_name, default_val=nil, &block)
      # raise 'Default value or block required' unless !default_val.nil? || block
      sym = attribute_name&.to_sym
      raise ArgumentError, "attribute_name is required and convertible to symbol." if sym.nil?

      define_method(sym) do
        instance_variable_get("@#{sym}") || (block.nil? ? default_val : block.call)
      end

      define_method("#{sym}=") { |val|instance_variable_set("@#{sym}", val) }
    end
  end

end
