require 'chaos_detector/utils/str_util'
require 'chaos_detector/chaos_utils'

module ChaosDetector
  module Stacker
    class ModInfo
      attr_reader :mod_name
      attr_reader :mod_path
      attr_reader :mod_type

      def initialize(mod_name:, mod_path:, mod_type:nil)
        raise ArgumentError, "mod_name is required" unless ChaosUtils.aught?(mod_name)
        @mod_name = mod_name
        @mod_path = mod_path
        @mod_type = mod_type
      end

      def ==(other)
        self.mod_name == other.mod_name &&
          self.mod_path == other.mod_path &&
          self.mod_type == other.mod_type
      end

      def to_s
        "(%s) %s - %s" % [
          @mod_type.to_s[0].upcase,
          ChaosDetector::Utils::StrUtil.humanize_module(@mod_name, sep_token: '::'),
          ChaosDetector::Utils::StrUtil.humanize_module(@mod_path, sep_token: '/')
        ]
      end
    end
  end
end