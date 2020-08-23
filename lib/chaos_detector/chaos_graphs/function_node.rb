require_relative 'mod_info'
require 'forwardable'
require 'graph_theory/edge'
require 'graph_theory/node'

require 'tcs/refined_utils'
using TCS::RefinedUtils

module ChaosDetector
  module ChaosGraphs
    class FunctionNode < GraphTheory::Node
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
        elsif Kernel.aught?mod_name
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

        self.domain_name == other.domain_name &&
          self.fn_name == other.fn_name &&
          self.fn_path == other.fn_path
          # && (!match_line_num || self.line_num == other.line_num)
      end

      def domain_name
        @domain_name || (@is_root ? ROOT_NODE_NAME.downcase : nil)
        # !@is_root ? @domain_name : @domain_name || ROOT_NODE_NAME.downcase
      end

      def to_s(scope=nil)
        self.class.human_key(fn_path: @fn_path, fn_name: fn_name, domain_name: domain_name)
      end

      def label
        m = @fn_path.split("/").last(2).join("/")
        m << decorate(fn_name, clamp: :parens)
        m
        # "#{m}\n#{@domain_name}"
      end

      def self.human_key(fn_path:nil, fn_name:nil, domain_name:nil, root: nil)
        hkey = "["
        hkey << "(#{domain_name}) " unless domain_name.nil? || domain_name.empty?
        hkey << decorate(fn_name)  #unless fn_name.nil? || fn_name.empty?
        hkey << " '#{fn_path}'" unless fn_path.nil? || fn_path.empty?
        m << decorate(ROOT_NODE_NAME, clamp: :parens) if root
        hkey << "]"
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