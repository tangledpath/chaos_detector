require 'tcs/refined_utils'
using TCS::RefinedUtils

# Encapsulate and aggregates graphs for dependency tracking
#   * Function directed graph
#   * Module directed graph - derived from function graph
#   * Domain directed graph - derived from function graph
module ChaosDetector
  module ChaosGraphs
    class ChaosGraph
      attr_reader :function_graph

      def initialize(function_graph)
        @function_graph = function_graph
        @domain_nodes = nil
        @module_modes = nil

        @domain_edges = nil
        @module_edges = nil
        @module_domain_edges = nil
        @domain_module_edges = nil
        @function_domain_edges = nil
        @domain_function_edges = nil
        # @module_graph = nil
        # @domain_graph = nil
      end

      def build_all
        build_domain_nodes
        build_module_nodes
        build_inferred_edges
        @domain_graph = build_domain_graph(@domain_edges)
        @module_graph = build_domain_graph(@module_edges)
      end

      ## Derive domain-level graph from function-based graph
      def build_domain_graph(edges)
        @domain_graph ||= Graph.new(root_node: root_node_domain, nodes: @domain_nodes, edges: edges)
      end

      ## Derive module-level graph from function-based graph
      def build_module_graph(edges: @module_edges)
        @domain_graph ||= Graph.new(root_node: root_node_module, nodes: @domain_nodes, edges: edges)
      end

      private
        def root_node_function
          raise "@graph.nodes isn't set!" unless @graph&.nodes
          root_node = @graph.nodes.find(&:is_root)
          root_node || ChaosDetector::ChaosGraphs::FunctionNode.root_node
        end

        def root_node_domain
          raise "@domain_nodes isn't set; call #build" unless @domain_nodes
          root_node = @domain_nodes.find(&:is_root)
          root_node || ChaosDetector::ChaosGraphs::DomainNode.root_node
        end

        def root_node_module
          raise "@module_nodes isn't set; call #build" unless @module_nodes
          root_node = @module_nodes.find(&:is_root)
          root_node || ChaosDetector::ChaosGraphs::ModuleNode.root_node
        end

        def build_domain_nodes
          @domain_nodes = @function_graph.nodes.group_by(&:domain_name).map do |dom_nm, fn_nodes|
            ChaosDetector::ChaosGraphs::DomainNode.new(dom_name: dom_nm, fn_node_count: fn_nodes.length)
          end
        end

        def build_module_nodes
          @module_nodes = @function_graph.nodes.group_by(&:mod_info_prime).map do |dom_nm, fn_nodes|
            ChaosDetector::ChaosGraphs::ModuleNode.new(dom_name: dom_nm, fn_node_count: fn_nodes.length)
          end
        end

        def build_inferred_edges
          edges = @function_graph.edges
          @domain_edges = group_edges_by(edges, :domain_name, :domain_name)
          @module_edges = group_edges_by(edges, :mod_info_prime, :mod_info_prime)
          @module_domain_edges = group_edges_by(edges, :mod_info_prime, :domain_name)
          @domain_module_edges = group_edges_by(edges, :domain_name, :mod_info_prime)
          @function_domain_edges = group_edges_by(edges, nil, :domain_name)
          @domain_function_edges = group_edges_by(edges, :domain_name, nil)
        end


        def self.group_edges_by(edges, src, dep)
          group_edges(edges) do |src_node, dep_node|
            [(src ? src_node.send(src) : src_node), (dep ? dep_node.send(dep) : dep_node)]
          end
        end

        def self.group_edges(edges)
          raise ArgumentError, "edges argument required" unless edges
          raise ArgumentError, "Block required" unless block_given?

          groupedges = edges.group_by { |e| yield(e.src_node, e.dep_node) }
          groupedges.map do |src_dep_pair, g_edges|
            raise "Pair should have two exactly items." unless src_dep_pair.length==2
            src_node, dep_node = src_dep_pair
            GraphTheory::Edge.new(src_node, dep_node, reduce_cnt: g_edges.length)
          end
        end

        def log(msg)
          log_msg(msg, subject: "ChaosGraph")
        end
    end
  end
end