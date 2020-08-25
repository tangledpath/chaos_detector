require 'chaos_detector/stacker/mod_info'
require 'chaos_detector/graph_theory/node'
require 'chaos_detector/utils/str_util'
require 'chaos_detector/chaos_utils'

module ChaosDetector
  module ChaosGraphs
    # Consider putting action/event in this class and naming it accordingly
    class ModuleNode < ChaosDetector::GraphTheory::Node
      attr_reader :mod_type # :unknown, :module, :class
      attr_reader :mod_path # :unknown, :module, :class
      attr_reader :domain_name
      attr_reader :fn_node_count
      alias_method :mod_name, :name

      def initialize(mod_name: nil, mod_path:nil, is_root: false, node_origin: nil, domain_name: nil, mod_type:nil, fn_node_count: nil)
        super(name:mod_name, root: is_root, node_origin: node_origin)
        @mod_path = mod_path
        @mod_type = mod_type
        @fn_node_count = fn_node_count
      end

      def hash
        [mod_name, mod_type, mod_path].hash
      end

      def eql?(other); self == other; end
      def ==(other)
        self.mod_name == other.mod_name &&
          self.mod_type == other.mod_type &&
          self.mod_path == other.mod_path
      end

      def label
        # Shorten long module paths:
        m = ChaosUtils::decorate(super, clamp: :parens, suffix:' ')
        m << ChaosUtils::decorate(@mod_type, clamp: :parens)
        m << short_path
      end

      def short_path
        ChaosDetector::Utils::StrUtil.humanize_module(@mod_path, sep_token: '/')
      end

      def to_info
        ChaosDetector::Stacker::ModInfo.new(mod_name:mod_name, mod_path: mod_path, mod_type: mod_type)
      end

      def to_k
        [mod_name, @mod_type, @mod_path].join('_')
      end

      def to_s
        [super, @mod_type, short_path].join(', ')
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