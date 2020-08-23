require 'ruby-graphviz'

require_relative 'options'
require_relative 'stacker/frame'
require 'graph_theory/appraiser'
require 'tcs/refined_utils'
require 'tcs/utils/str_util'

using TCS::RefinedUtils

module ChaosDetector
  module Graphing
    class Grapher
      extend TCS::Utils::CoreUtil::ChaosAttr

      EDGE_MIN = 0.5
      EDGE_BASELINE = 7.5

      CLR_BLACK='black'
      CLR_DARKRED = 'red4'
      CLR_DARKGREEN = 'darkgreen'
      CLR_BRIGHTGREEN = 'yellowgreen'
      CLR_CYAN = 'cyan'
      CLR_GREY = 'snow3'
      CLR_ORANGE = 'orange'
      CLR_NICEGREY = 'snow4'
      CLR_PALEGREEN = 'palegreen'
      CLR_PINK = 'deeppink1'
      CLR_PURPLE = '#662D91'
      CLR_SLATE = "#778899"
      CLR_WHITE='white'

      GRAPH_OPTS = {
        type: :digraph,
        bgcolor: CLR_SLATE,
        center: 'true',
        color: CLR_WHITE,
        compound: 'true',
        # # concentrate: 'true',
        # engine: 'dot',
        fontcolor: CLR_WHITE,
        fontname: 'Georgia',
        fontsize: '48',
        labelloc: 't',
        pencolor: CLR_WHITE,
        # ordering: 'out',
        # outputorder: 'nodesfirst',
        nodesep: '0.25',
        # newrank: 'true',
        # rankdir: 'LR',
        ranksep: '1.0',
        # size: '10,8',
        # splines: 'spline',
        strict: 'true'
      }

      SUBDOMAIN_ATTRS = {
        bgcolor: CLR_NICEGREY,
        fontsize: '16',
        rank: 'same',
        fontname: 'Verdana',
        labelloc: 't',
        pencolor: CLR_GREY,
        penwidth: '2'
      }

      NODE_ATTR={
        shape: 'egg',
        fontname: 'Verdana',
        fontsize: '12',
        # fillcolor: CLR_WHITE,
        fontcolor: CLR_WHITE,
        color: CLR_WHITE
      }



      # TODO: integrate options as needed:
      def initialize(options=nil)
        @options = options
        @root_graph = nil
        @node_hash = {}
        @subgraph_hash = {}
        # @graph_metrics = GraphTheory::Appraiser.new(@atlas.graph)
      end

      def create_directed_graph(label)
        @label = label
        @root_graph = GraphViz.digraph(:G, label: @label, **GRAPH_OPTS)
      end

      def assert_graph_state
        raise "@root_graph is not set yet.  Call create_directed_graph." unless @root_graph
      end

      def add_node_as_subgraph(node, graph:nil)
        assert_graph_state
        raise "node is required" unless node
        parent_graph = graph || @root_graph

        parent_graph.add_graph("cluster_#{node.label}", label: node.label, **SUBDOMAIN_ATTRS)
      end

      def add_node_to_graph(node, graph)
        assert_graph_state
        raise "graph is required" unless graph
        raise "node is required" unless node

        graph.add_nodes(node.label, **NODE_ATTR)
      end

      def add_graph_nodes(nodes, graph:nil, as_subgraph:false)
        assert_graph_state
        raise "node is required" unless nodes

        parent_graph = graph || @root_graph

        nodes.each do |node|
          if as_subgraph
            @subgraph_hash[node.to_k] = add_subgraph_node(node, parent_graph, )
          else
            @node_hash[node.to_k] = add_node_to_graph(node, parent_graph)
          end
        end
      end

      def add_nodes_to_parent(nodes, parent_node: nil)
        assert_graph_state

        subgraph = parent_node ? @subgraph_hash[parent_node.to_k] : @root_graph
        add_graph_nodes(subgraph, nodes)
      end

      def find_graph_node(node)
        assert_graph_state
        log("NODE_HASH: LOOKING UP #{decorate(node)}")
        @node_hash[node.to_k] || @subgraph_hash[node.to_k]
      end

      def add_edges(edges)
        assert_graph_state

        @node_hash.each do |k, v|
          log("NODE_HASH: Has value for #{decorate(k)} => #{decorate(v)}")
        end

        max_reduce = edges.map(&:reduce_cnt).max

        edges.each do |e|
          log("DDDDDOMAIN EDGE: #{e}")
          src = find_graph_node(e.src_node)
          dep = find_graph_node(e.dep_node)
          log("DOMAIN EDGE: #{src} -> #{dep}")
          norm_reduce_cnt = e.reduce_cnt / max_reduce
          weight = edge_weight(norm_reduce_cnt)
          @root_graph.add_edges(src, dep)  #, {label: e.reduce_cnt, penwidth: weight})
        end
      end

      def edge_weight(n, edge_min: EDGE_MIN, edge_baseline: EDGE_BASELINE)
        edge_min + n * edge_baseline
      end

      def log(msg)
        log_msg(msg, subject: "Grapher")
      end

      def render_graph
        assert_graph_state
        @root_graph.output( :png => "#{@label}.png" )
      end
    end
  end
end