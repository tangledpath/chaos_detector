require 'chaos_detector/utils/str_util'
require 'chaos_detector/chaos_utils'
require_relative 'comp_info'
module ChaosDetector
  module Stacker
    class ModInfo < ChaosDetector::Stacker::CompInfo
      alias mod_name name
      alias mod_type info
      alias mod_path path

      def initialize(mod_name:, mod_type: nil, mod_path: nil)
        super(name: mod_name, path: mod_path, info: mod_type)
      end

      def ==(other)
        super(other)
      end


      def component_type
        :module
      end

      def to_s
        format('(%s) %s - %s', mod_type, ChaosDetector::Utils::StrUtil.humanize_module(mod_name, sep_token: '::'), ChaosDetector::Utils::StrUtil.humanize_module(mod_path, sep_token: '/'))
      end
    end
  end
end
