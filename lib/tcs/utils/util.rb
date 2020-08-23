# TCS::Utils::Util.naught?("")
# TCS::Utils::Util.naught?(0)
# TCS::Utils::Util.naught?([])
# TCS::Utils::Util.naught?("foobar")
# TCS::Utils::Util.naught?(0)
# TCS::Utils::Util.naught?([])
# module ChaosDetector

# = TCS::Utils::Util::with
module TCS
  module Utils
    module Util
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

        # MOVE TO STRING UTIL:
        def decorate_pair(source, dest, indent_length: 0, clamp: :angle, join_str: ' -> ')
          decorate("#{decorate(source)}#{decorate(dest, prefix: join_str)}", clamp:clamp, indent_length:indent_length)
        end

        def decorate(text, clamp: :nil, prefix: nil, suffix: nil, sep: nil, indent_length: 0)
          return STR_BLANK if naught?text

          clamp_pre, clamp_post = clamp_chars(clamp: clamp)
          indent("#{prefix}#{sep}#{clamp_pre}#{text}#{clamp_post}#{sep}#{suffix}", indent_length)
        end

        alias_method :d, :decorate

        def clamp_chars(clamp: nil)
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
            print_line(d(message, prefix: 'Starting: '))
            result = yield
            print_line(d(message, prefix: 'Complete: ', suffix: d(result)))
          else
            print_line(message)
          end
          message
        end

        def print_line(msg, *opts)
          # print("#{msg}\n", opts)
          # nil
          Kernel.puts(msg, opts)
        end

        alias_method :pp, :print_line


        # @return subset of given properties not contained withing given object
        def properties_complement(props, obj:)
          return props if obj.nil?
          raise ArgumentError, "props is required." unless props

          puts "(#{obj.class} )props: #{props}"


          props - case obj
            when Hash
              puts "KKKKK"
              puts "obj.keys: #{obj.keys}"
              obj.keys

            else
              puts "PPPPP #{obj.class}"
              puts "obj.public_methods: #{obj.public_methods}"
              obj.public_methods

          end
        end

        # Built-in self-testing:
        # TCS::Utils::Util.test
        def test
          log("Testing TCS::Utils::Util", subject: "TCS::Utils::Util") do
            assert(true, 'Naught detects blank string'){TCS::Utils::Util.naught?("")}
            assert(true, 'Naught detects blank string with space'){TCS::Utils::Util.naught?(" ")}
            assert(true, 'Naught detects int 0'){TCS::Utils::Util.naught?(0)}
            assert(true, 'Naught detects float 0.0'){TCS::Utils::Util.naught?(0.0)}
            assert(true, 'Naught detects empty array'){TCS::Utils::Util.naught?([])}
            assert(true, 'Naught detects empty hash'){TCS::Utils::Util.naught?({})}
            assert(false, 'Naught real string'){TCS::Utils::Util.naught?("foobar")}
            assert(false, 'Naught non-zero int'){TCS::Utils::Util.naught?(1)}
            assert(false, 'Naught non-zero float'){TCS::Utils::Util.naught?(33.33)}
            assert(false, 'Naught non-empty array'){TCS::Utils::Util.naught?(['stuff'])}
            assert(false, 'Naught non-empty hash'){TCS::Utils::Util.naught?({foo: 'bar'})}
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
  end
end

def Kernel.with(obj)
  TCS::Utils::Util::with(obj) {yield obj}
end

def Kernel.naught?(obj)
  TCS::Utils::Util::naught?(obj)
end

def Kernel.aught?(obj)
  !TCS::Utils::Util::naught?(obj)
end

def decorate(text, *args)
  TCS::Utils::Util::decorate(text, *args)
end
