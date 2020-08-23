# naught?("")
# naught?(0)
# naught?([])
# naught?("foobar")
# naught?(0)
# naught?([])
# module ChaosDetector

# = ChaosDetector::Utils::CoreUtil::with
module ChaosDetector
  module Utils
    module CoreUtil
      class AssertError < StandardError; end

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
            obj.none? { |o| aught?(o) }
          elsif obj.is_a?(Numeric)
            obj == 0
          end
        end

        def aught?(obj)
          !naught?(obj)
        end

        def with(obj)
          raise ArgumentError("with requires block") unless block_given?
          yield obj if obj
        end

        def assert(expected_result=true, msg=nil, &block)
          if block.nil? && !expected_result
            raise AssertError, "Assertion failed. #{msg}"
          elsif !block.nil? && block.call!=expected_result
            raise AssertError, "Assertion failed. #{msg}\n\t#{block.source_location}"
          end
        end

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
        # ChaosDetector::Utils::CoreUtil.test
        def test
          puts("Testing ChaosDetector::Utils::CoreUtil")
          assert(true, 'Naught detects blank string'){naught?("")}
          assert(true, 'Naught detects blank string with space'){naught?(" ")}
          assert(true, 'Naught detects int 0'){naught?(0)}
          assert(true, 'Naught detects float 0.0'){naught?(0.0)}
          assert(true, 'Naught detects empty array'){naught?([])}
          assert(true, 'Naught detects empty hash'){naught?({})}
          assert(false, 'Naught real string'){naught?("foobar")}
          assert(false, 'Naught non-zero int'){naught?(1)}
          assert(false, 'Naught non-zero float'){naught?(33.33)}
          assert(false, 'Naught non-empty array'){naught?(['stuff'])}
          assert(false, 'Naught non-empty hash'){naught?({foo: 'bar'})}
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
