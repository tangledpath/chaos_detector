require 'ruby-graphviz'
require 'chaos_detector/utils/str_util'
require 'chaos_detector/chaos_utils'

module ChaosDetector
  module Graphing
    class Directed
      attr_reader :root_graph
      attr_reader :node_hash
      attr_reader :cluster_node_hash
      attr_reader :render_folder
      attr_reader :rendered_path
      attr_reader :edges

      EDGE_MIN = 0.5
      EDGE_BASELINE = 7.5

      CLR_BLACK = 'black'.freeze
      CLR_DARKRED = 'red4'.freeze
      CLR_DARKGREEN = 'darkgreen'.freeze
      CLR_BRIGHTGREEN = 'yellowgreen'.freeze
      CLR_CYAN = 'cyan'.freeze
      CLR_GREY = 'snow3'.freeze
      CLR_ORANGE = 'orange'.freeze
      CLR_NICEGREY = 'snow4'.freeze
      CLR_PALEGREEN = 'palegreen'.freeze
      CLR_PINK = 'deeppink1'.freeze
      CLR_PURPLE = '#662D91'.freeze
      CLR_SLATE = '#778899'.freeze
      CLR_WHITE = 'white'.freeze

      GRAPH_OPTS = {
        type: :digraph,
        bgcolor: CLR_SLATE,
        center: 'true',
        clusterrank: 'local',
        color: CLR_WHITE,
        compound: 'true',
        # # concentrate: 'true',
        # engine: 'dot',
        fontcolor: CLR_WHITE,
        fontname: 'Georgia',
        fontsize: '48',
        labelloc: 't',
        pencolor: CLR_WHITE,
        outputorder: 'nodesfirst',
        # ordering: 'out',
        # outputorder: 'nodesfirst',
        nodesep: '0.25',
        newrank: 'false',
        rankdir: 'LR',
        ranksep: '1.0',
        ratio: 'expand',
        size: '15, 30',
        # size: '10,8',
        splines: 'spline',
        # strict: 'true'
      }.freeze

      SUBDOMAIN_ATTRS = {
        bgcolor: CLR_NICEGREY,
        # fillcolor: CLR_ORANGE,
        fontsize: '16',
        rank: 'same',
        fontname: 'Verdana',
        labelloc: 't',
        # pencolor: CLR_GREY,
        penwidth: '2'
      }.freeze

      NODE_ATTR = {
        shape: 'egg',
        fontname: 'Verdana',
        fontsize: '12',
        # fillcolor: CLR_WHITE,
        fontcolor: CLR_WHITE,
        color: CLR_WHITE
      }.freeze

      EDGE_ATTR = {
        color:CLR_BLACK,
        fontname:'Verdana',
        fontcolor:CLR_WHITE,
        fontsize:'8',
        style:'solid',
        # penwidth:'1.5',
        constraint:'true',
        dir:'forward'
      }

      # TODO: integrate options as needed:
      def initialize(render_folder: nil)
        @root_graph = nil
        @node_hash = {}
        @cluster_node_hash = {}
        @edges = Set.new
        @render_folder = render_folder || 'render'
      end

      def create_directed_graph(label)
        @label = label
        @node_hash.clear
        @cluster_node_hash.clear
        @root_graph = GraphViz.digraph(:G, label: @label, **GRAPH_OPTS)
      end

      def assert_graph_state
        raise '@root_graph is not set yet.  Call create_directed_graph.' unless @root_graph
      end

      # Add node to given parent_node, assuming parent_node is a subgraph
      def add_node_to_parent(node, parent_node:, as_cluster: false)
        assert_graph_state
        raise 'node is required' unless node

        parent_graph = if parent_node
                         find_graph_node(parent_node).tap do |_cluster, pnode|
                           raise "Couldn't find parent node: #{parent_node}" unless pnode
                         end
                       else
                         @root_graph
                       end

        add_node_to_graph(node, graph: parent_graph, as_cluster: as_cluster)
      end

      def add_node_to_graph(node, graph: nil, as_cluster: false)
        assert_graph_state
        raise 'node is required' unless node

        parent_graph = graph || @root_graph
        key = node.to_k

        if as_cluster
          # tab good shape
          subgraph_name = "cluster_#{key}"
          attrs = {label: node.label}.merge(SUBDOMAIN_ATTRS)
          # attrs = {}.merge(SUBDOMAIN_ ATTRS)
          @cluster_node_hash[key] = parent_graph.add_graph(subgraph_name, attrs)
          @cluster_node_hash[key].add_nodes(node_key(node, cluster: :stub), style: 'invis')

          # @cluster_node_hash[key].attrs(attrs)
          # puts ("attrs: #{key}: #{attrs}  / #{@cluster_node_hash.length}")
        else
          attrs = {label: node.label}.merge(NODE_ATTR)
          @node_hash[key] = parent_graph.add_nodes(key, attrs)
        end
      end

      def append_nodes(nodes, as_cluster: false)
        assert_graph_state
        raise 'node is required' unless nodes

        nodes.each do |node|
          parent_node = block_given? ? yield(node) : nil
          add_node_to_parent(node, parent_node: parent_node, as_cluster: as_cluster)
        end
      end

      def node_key(node, cluster: false)
        if cluster==:stub
          "cluster_stub_#{node.to_k}"
        elsif !!cluster
          "cluster_#{node.to_k}"
        else
          node.to_k
        end
      end

      def add_edges(edges, calc_weight:false)
        assert_graph_state

        # @node_hash.each do |k, v|
        #   log("NODE_HASH: Has value for #{ChaosUtils.decorate(k)} => #{ChaosUtils.decorate(v)}")
        # end

        max_reduce  = edges.map(&:reduce_cnt).max

        edges.each do |e|
          src_clust, src = find_graph_node(e.src_node)
          dep_clust, dep = find_graph_node(e.dep_node)

          norm_reduce_cnt = e.reduce_cnt / max_reduce
          weight = calc_weight ? edge_weight(norm_reduce_cnt) : 1.0
          @edges << [src, dep]

          # puts "SRC NODE IS #{src.inspect}"
          # Add dependent relation edges for edge_type:
          arrow_type = arrow_type_for(e)

          # puts(['WTF', src.name, node_key(e.src_node, cluster: true)].inspect)

          @root_graph.add_edges(
            node_key(e.src_node, cluster: src_clust ? :stub : false),
            node_key(e.dep_node, cluster: dep_clust ? :stub : false),
            ltail: src_clust ? node_key(e.src_node, cluster: true) : '',
            lhead: dep_clust ? node_key(e.dep_node, cluster: true) : '',
            # ltail: src_clust ? src.name : nil,
            # lhead: dep_clust ? dep.name : nil,
            arrowhead: arrow_type,
            arrowsize: 1.5,
            penwidth: weight,
            **EDGE_ATTR
          ) # , {label: e.reduce_cnt, penwidth: weight})
        end
      end

      def render_graph
        assert_graph_state

        filename = "#{@label}.png"
        @rendered_path = File.join(@render_folder, filename).to_s

        log("Rendering graph to to #{@rendered_path}")
        ChaosDetector::Utils::FSUtil.ensure_paths_to_file(@rendered_path)
        @root_graph.output(png: @rendered_path)
        self
      end

    private

      def arrow_type_for(edge)
        case edge.edge_type
          when :superclass
            'empty'
          when :association
            'diamond'
          when :class_association
            'ediamond'
          else
            'open'
        end
      end

      def find_graph_node(node)
        assert_graph_state
        # log("NODE_HASH: LOOKING UP #{ChaosUtils.decorate(node)}")
        cnode = @cluster_node_hash[node.to_k]
        if cnode
          [true, cnode]
        else
          [false, @node_hash[node.to_k]]
        end
      end

      def edge_weight(n, edge_min: EDGE_MIN, edge_baseline: EDGE_BASELINE)
        edge_min + n * edge_baseline
      end

      def log(msg)
        ChaosUtils.log_msg(msg, subject: 'Grapher')
      end
    end
  end
end
