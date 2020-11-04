require 'chaos_detector/utils/core_util'
require 'chaos_detector/utils/fs_util'
require 'chaos_detector/utils/str_util'
require 'chaos_detector/utils/lerp_util'
require 'chaos_detector/utils/log_util'

module ChaosUtils
  class << self
    def delerp(val, min:, max:)
      ChaosDetector::Utils::LerpUtil.delerp(val, min: min, max: max)
    end

    def lerp(pct, min:, max:)
      ChaosDetector::Utils::LerpUtil.lerp(val, min: min, max: max)
    end

    def log_msg(msg, **args)
      ChaosDetector::Utils::LogUtil.log(msg, **args)
    end

    def decorate(text, **args)
      ChaosDetector::Utils::StrUtil.decorate(text, **args)
    end

    def decorate_pair(src, dest, **args)
      ChaosDetector::Utils::StrUtil.decorate_pair(src, dest, **args)
    end

    def decorate_tuple(tuple, **args)
      ChaosDetector::Utils::StrUtil.decorate_tuple(tuple, **args)
    end

    def assert(expected_result=true, msg=nil, &block)
      ChaosDetector::Utils::CoreUtil.assert(expected_result, msg, &block)
    end

    def aught?(obj)
      ChaosDetector::Utils::CoreUtil.aught?(obj)
    end

    def naught?(obj)
      ChaosDetector::Utils::CoreUtil.naught?(obj)
    end

    def rel_path(dir_path, from_path:)
      ChaosDetector::Utils::FSUtil.rel_path(dir_path, from_path: from_path)
    end

    def squish(str)
      ChaosDetector::Utils::StrUtil.squish(str)
    end

    def with(obj)
      ChaosDetector::Utils::CoreUtil.with(obj) {yield obj}
    end
  end
end
