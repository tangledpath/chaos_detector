require 'chaos_detector/utils/core_util'
require 'chaos_detector/utils/str_util'
require 'chaos_detector/utils/log_util'

module ChaosDetector
  module RefinedUtils
    refine Kernel do
      def log_msg(msg, *args)
        ChaosDetector::Utils::LogUtil::log(msg, *args)
      end

      def decorate(text, *args)
        ChaosDetector::Utils::StrUtil::decorate(text, *args)
      end

      def decorate_pair(src, dest, *args)
        ChaosDetector::Utils::StrUtil::decorate_pair(src, dest, *args)
      end

      def decorate_tuple(tuple, *args)
        ChaosDetector::Utils::StrUtil::decorate_tuple(tuple, *args)
      end

      def with(obj)
        ChaosDetector::Utils::CoreUtil::with(obj) {yield obj}
      end

      def naught?(obj)
        ChaosDetector::Utils::CoreUtil::naught?(obj)
      end

      def aught?(obj)
        ChaosDetector::Utils::CoreUtil::aught?(obj)
      end
    end
  end
end
