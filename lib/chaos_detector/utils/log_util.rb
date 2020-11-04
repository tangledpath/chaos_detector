require_relative 'core_util'
require_relative 'str_util'

module ChaosDetector
  module Utils
    module LogUtil
      class << self
        # Simple logging, more later
        def log(msg, object: nil, subject: nil)
          # raise ArgumentError, "no message to log" if nay?(msg)
          return if nay?(msg)

          subj = d(subject, clamp: :brace)
          obj = d(object, clamp: :bracket, prefix: ': ')
          message = d(msg, prefix: subj, suffix: obj)

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

        alias pp print_line

        def nay?(obj)
          ChaosDetector::Utils::CoreUtil.naught?(obj)
        end

        def d(text, *args)
          ChaosDetector::Utils::StrUtil.decorate(text, *args)
        end
      end
    end
  end
end
