require_relative 'core_util'
require_relative 'str_util'

module ChaosDetector
  module Utils
    module LogUtil

      class << self

        # Simple logging, more later
        def log(msg, subject: nil)
          message = nay?(subject) ? msg : d(msg, prefix:d(subject, clamp: :bracket))
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

        def nay?(obj)
          ChaosDetector::Utils::CoreUtil::naught?(obj)
        end

        def d(text, *args)
          ChaosDetector::Utils::StrUtil::decorate(text, *args)
        end

      end
    end
  end
end
