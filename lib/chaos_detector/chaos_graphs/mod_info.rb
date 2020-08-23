require 'tcs/utils/str_util'
require 'tcs/refined_utils'
using TCS::RefinedUtils

module ChaosDetector
  module ChaosGraphs
    class ModInfo
        attr_reader :mod_name
        attr_reader :mod_path
        attr_reader :mod_type

        def initialize(mod_name:, mod_path:, mod_type:nil)
          raise ArgumentError, "mod_name is required" unless aught?(mod_name)
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
          p = TCS::Utils::StrUtil.humanize_module(@mod_path, sep_token: '/')
          "%s %s - %s" % [@mod_name, Kernel.decorate(@mod_type, clamp:bracket), p]
        end
    end
  end
end