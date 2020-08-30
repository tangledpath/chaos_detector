require 'chaos_detector/stacker/fn_info'
require 'chaos_detector/stacker/mod_info'
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
      attr_accessor :fn_line_end

      # Modules to which this Function Node is associated:
      attr_reader :mod_infos
      def_delegator :@mod_infos, :first, :mod_info_prime

      def initialize(
        fn_name: nil,
        fn_path: nil,
        fn_line: nil,
        domain_name:nil,
        is_root: false,
        mod_info: nil
      )
        super(name: fn_name, root: is_root)

        @domain_name = domain_name
        @fn_path = fn_path
        @fn_line = fn_line
        @mod_infos = []

        # Add module info, if supplied:
        add_module(mod_info)
      end

      def add_module(mod_info)
        @mod_infos << mod_info if mod_info
      end

      def add_module_attrs(mod_name:, mod_path:, mod_type:)
        add_module(ChaosDetector::Stacker::ModInfo.new(mod_name:mod_name, mod_path: mod_path, mod_type: mod_type))
      end

      def hash
        [fn_name, fn_path].hash
      end

      def eql?(other); self == other; end
      def ==(other)
        ChaosDetector::Stacker::FnInfo.match?(self, other)
      end

      def domain_name
        @domain_name || (@is_root ? ROOT_NODE_NAME : nil)
        # !@is_root ? @domain_name : @domain_name || ROOT_NODE_NAME.downcase
      end

      def to_s
        "%s: (%s) - %s" % [super, domain_name, short_path]
      end

      def to_info
        FnInfo.new(fn_name: fn_name, fn_line: fn_line, fn_path: fn_path)
      end

      def label
        m = ChaosUtils.decorate(super, clamp: :parens, suffix:' ')
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

        def match?(obj1, obj2)
          raise "Domains differ, but fn_info is the same.  Weird." if \
            obj1.fn_name == obj2.fn_name \
            && obj1.fn_path == obj2.fn_path \
            && obj1.domain_name != other.domain_name

          fn_path == other.fn_path &&
            (fn_name == other.fn_name || line_match?(other.fn_line, fn_line))

        end

        def line_match?(l1, l2)
          return false if l1.nil? || l2.nil?

          (l2 - l1).between?(0, 1)
        end

      end
    end
  end
end