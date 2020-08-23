require_relative 'fn_info'
require_relative 'mod_info'
require 'forwardable'
require 'chaos_detector/graph_theory/edge'
require 'chaos_detector/graph_theory/node'

require 'chaos_detector/chaos_utils'

module ChaosDetector
  module ChaosGraphs
    class FunctionNode < ChaosDetector::GraphTheory::Node
      extend Forwardable
      alias_method :fn_name, :name
      attr_accessor :domain_name
      attr_accessor :fn_path
      attr_accessor :fn_line

      # Modules to which this Function Node is associated:
      attr_reader :mod_infos
      def_delegator :@mod_infos, :first, :mod_info_prime

      def initialize(
        fn_name: nil,
        fn_path: nil,
        fn_line: nil,
        domain_name:nil,
        is_root: false,
        mod_info: nil,
        mod_name:nil,
        mod_type:nil
      )
        super(name: fn_name, root: is_root)

        @domain_name = domain_name
        @fn_path = fn_path
        @fn_line = fn_line
        @mod_infos = []

        # Add module info, if supplied:
        if mod_info
          add_module(mod_info)
        elsif ChaosUtils.aught?mod_name
          add_module_attrs(mod_name:mod_name, mod_path: fn_path, mod_type: mod_type)
        end
      end

      def add_module(mod_info)
        @mod_infos << mod_info if mod_info
      end

      def add_module_attrs(mod_name:, mod_path:, mod_type:)
        add_module(ChaosDetector::ChaosGraphs::ModInfo.new(mod_name:mod_name, mod_path: mod_path, mod_type: mod_type))
      end

      def ==(other)
        raise "Domains differ, but fn_info is the same.  Weird." if \
          self.fn_name == other.fn_name \
          && self.fn_path == other.fn_path \
          && self.domain_name != other.domain_name

        self.fn_path == other.fn_path &&
          (self.fn_name == other.fn_name || self.fn_line == other.fn_line)

          # && (!match_line_num || self.fn_line == other.fn_line)
      end

      def domain_name
        @domain_name || (@is_root ? ROOT_NODE_NAME.downcase : nil)
        # !@is_root ? @domain_name : @domain_name || ROOT_NODE_NAME.downcase
      end

      def to_s
        "%s: (%s) - %s" % [super, domain_name, short_path]
      end

      def to_info
        FnInfo.new(fn_name: fn_name, fn_path: fn_path, domain_name: domain_name)
      end

      def label
        m = ChaosUtils::decorate(super, clamp: :parens, suffix:' ')
        m << short_path
        m
      end

      def short_path
        ChaosDetector::Utils::StrUtil.humanize_module(@fn_path, sep_token: '/')
      end

      class << self
        attr_reader :root_node
        def root_node(force_new: false)
          @root_node = self.new(is_root: true) if force_new || @root_node.nil?
          @root_node
        end
      end
    end
  end
end