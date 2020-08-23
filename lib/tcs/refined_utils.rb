require 'tcs/utils/core_util'
require 'tcs/utils/str_util'
require 'tcs/utils/log_util'

module TCS
  module RefinedUtils
    refine Kernel do
      def log_msg(msg, *args)
        TCS::Utils::LogUtil::log(msg, *args)
      end

      def decorate(text, *args)
        TCS::Utils::StrUtil::decorate(text, *args)
      end

      def decorate_tuple(src, dest, *args)
        TCS::Utils::StrUtil::decorate_tuple(src, dest, *args)
      end


      def with(obj)
        TCS::Utils::CoreUtil::with(obj) {yield obj}
      end

      def naught?(obj)
        TCS::Utils::CoreUtil::naught?(obj)
      end

      def aught?(obj)
        TCS::Utils::CoreUtil::aught?(obj)
      end
    end
  end
end
