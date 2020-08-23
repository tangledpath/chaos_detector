# ChaosDetector::Utils.naught?("")
# ChaosDetector::Utils.naught?(0)
# ChaosDetector::Utils.naught?([])
# ChaosDetector::Utils.naught?("foobar")
# ChaosDetector::Utils.naught?(0)
# ChaosDetector::Utils.naught?([])
module ChaosDetector::Utils
  STR_INDENT = '  '.freeze
  STR_BLANK = ''.freeze

  class << self
    def naught?(obj)
      if obj.nil?
        true
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

    def decorate(text, clamp_style: :brace, prefix: nil, suffix: nil, sep: nil, indent_length: 0)
      return STR_BLANK if naught?text

      clamp_pre, clamp_post = clamp_chars(clamp_style: clamp_style)
      indent("#{prefix}#{sep}#{clamp_pre}#{text}#{clamp_post}#{sep}#{suffix}", indent_length)
    end
    alias_method :d, :decorate

    def clamp_chars(clamp_style: :brace)
      case(clamp_style)
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
    def log(msg)
      if block_given?
        p(decorate(msg, prefix: 'Starting: '))
        result = yield
        p(d(msg, prefix: 'Complete: ', suffix: d(result)))
      else
        p(msg)
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
end
