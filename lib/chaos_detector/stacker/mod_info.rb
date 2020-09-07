require 'chaos_detector/utils/str_util'
require 'chaos_detector/chaos_utils'
require_relative 'comp_info'
module ChaosDetector
  module Stacker
    class ModInfo < ChaosDetector::Stacker::CompInfo
      alias_method :mod_name, :name
      alias_method :mod_type, :info
      alias_method :mod_path, :path

      def initialize(mod_name:, mod_type: nil, mod_path: nil)
        super(name:mod_name, path: mod_path, info: mod_type)
      end

      def to_s
        "(%s) %s - %s" % [
          mod_type.to_s[0].upcase,
          ChaosDetector::Utils::StrUtil.humanize_module(mod_name, sep_token: '::'),
          ChaosDetector::Utils::StrUtil.humanize_module(mod_path, sep_token: '/')
        ]
      end
    end
  end
end