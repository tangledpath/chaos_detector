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

      BR = '<BR/>'
      LF = "\r"
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

      GRAPH_ATTR = {
        type: :digraph,
        bgcolor: CLR_SLATE,
        center: 'false',
        clusterrank: 'local',
        color: CLR_WHITE,
        compound: 'true',
        # concentrate: 'true',
        # engine: 'dot',
        fontcolor: CLR_WHITE,
        fontname: 'Georgia',
        fontsize: '48',
        labelloc: 't',
        labeljust: 'l',
        mindist: '3.5',
        # nojustify: 'true',
        pad: '1.0',
        # pack: 'true',
        # packmode: 'graph',
        pencolor: CLR_WHITE,
        # outputorder: 'edgesfirst',
        # ordering: 'out',
        outputorder: 'nodesfirst',
        nodesep: '0.75',
        sep: '1.0',
        newrank: 'false',
        rankdir: 'LR',
        ranksep: '1.0',
        # ranksep: 'equally',
        # ratio: 'auto',
        # size: '50',
        # page: '50',
        # size: '10,8',
        # splines: 'spline',
        # strict: 'true'
      }.freeze

      SUBDOMAIN_ATTRS = {
        pencolor: CLR_ORANGE,
        bgcolor: CLR_NICEGREY,
        fillcolor: CLR_NICEGREY,
        fontsize: '24',
        rank: 'same',
        fontname: 'Verdana',
        labelloc: 't',
        margin: '32,32',
        # pencolor: CLR_GREY,
        penwidth: '2',
        style: 'rounded'
      }.freeze

      NODE_ATTR = {
        color: CLR_WHITE,
        fontname: 'Verdana',
        fontsize: '12',
        # fixedsize: 'shape',
        # height: '2.0',
        # width: '2.0',
        # fillcolor: CLR_WHITE,
        fontcolor: CLR_WHITE,
        margin: '0.25, 0.125',
        shape: 'egg',
      }.freeze

      EDGE_ATTR = {
        color:CLR_WHITE,
        constraint: 'true',
        dir:'forward',
        fontname:'Verdana',
        fontcolor:CLR_ORANGE,
        fontsize:'12',
        minlen: '3.0',
        style:'solid',
        # penwidth:'1.5',
      }.freeze

      STUB_NODE_ATTRS = {
        fixedsize: 'true',
        size: '0.5, 0.5',
        style: 'invis',
      }

      # Status messages:
      PRE_STATUS_MSG = %(
        Will update %<count>d record types from [%<from_type>s] to [%<to_type>s]'
      ).freeze

      TBL_HTML = <<~HTML
        <TABLE BORDER='0' CELLBORDER='1' CELLSPACING='0' CELLPADDING='4'>
          %s
        </TABLE>
      HTML

      TBL_ROW_HTML = %(<TR BGCOLOR="%<color>s">%<cells>s</TR>)
      TBL_CELL_HTML = %(<TD>%s</TD>)
      BOLD_HTML = %(<BOLD>%s</BOLD>)

      # TODO: integrate options as needed:
      def initialize(render_folder: nil)
        @root_graph = nil
        @node_hash = {}
        @cluster_node_hash = {}
        @edges = Set.new
        @render_folder = render_folder || 'render'
      end

      def create_directed_graph(title, graph_attrs: nil)
        @title = title

        @node_hash.clear
        @cluster_node_hash.clear
        @cluster_node_hash.clear

        lbl = title_html(@title, subtitle: graph_attrs&.dig(:subtitle))

        attrs = {
          label: "<#{lbl}>",
          **GRAPH_ATTR,
        }
        attrs.merge(graph_attrs) if graph_attrs&.any?
        attrs.delete(:subtitle)

        @root_graph = GraphViz.digraph(:G, attrs)
      end

      def node_label(node, metrics_table: true)
        if metrics_table
          tbl_hash = {title: node.title,  subtitle: node.subtitle,  **node.graph_props}
          html = html_tbl_from(hash: tbl_hash) do |k, v|
            if k==:title
              [in_font(k, font_size: 24), in_font(v, font_size: 16)]#[BOLD_HTML % k, BOLD_HTML % v]
            else
              [k, v]
            end
          end
        else
          html = title_html(node.title, subtitle: node.subtitle)
        end
        html.strip!
        # puts '_' * 50
        # puts "html: #{html}"
        '<%s>' % html
      end

      # HTML Label with subtitle:
      def title_html(title, subtitle:nil, font_size:24, subtitle_fontsize:nil)
        lbl_buf = [in_font(title, font_size: font_size)]

        sub_fontsize = subtitle_fontsize || 3 * font_size / 4
        if ChaosUtils.aught?(subtitle)
          lbl_buf << in_font(subtitle, font_size: sub_fontsize)
        end

        # Fake out some padding:
        lbl_buf << in_font(' ', font_size: sub_fontsize)

        lbl_buf.join(BR)
      end

      def in_font(str, font_size:12)
        "<FONT POINT-SIZE='#{font_size}'>#{str}</FONT>"
      end

      def html_tbl_from(hash:)
        trs = hash.map.with_index do |h, n|
          k, v = h
          key_content, val_content = yield(k, v) if block_given?
          key_td = TBL_CELL_HTML % (key_content || k)
          val_td = TBL_CELL_HTML % (val_content || v)
          td_html = [key_td, val_td].join
          html = format(TBL_ROW_HTML, {
            color: n.even? ? 'blue' : 'white',
            cells: td_html.strip
          })
          html.strip
        end

        TBL_HTML % trs.join().strip
      end

      def assert_graph_state
        raise '@root_graph is not set yet.  Call create_directed_graph.' unless @root_graph
      end

      # Add node to given parent_node, assuming parent_node is a subgraph
      def add_node_to_parent(node, parent_node:, as_cluster: false, metrics_table:false)
        assert_graph_state
        raise 'node is required' unless node

        parent_graph = if parent_node
          _clust, p_graph = find_graph_node(parent_node)
          raise "Couldn't find parent node: #{parent_node}" unless p_graph
          p_graph
        else
          @root_graph
        end

        add_node_to_graph(node, graph: parent_graph, as_cluster: as_cluster, metrics_table: metrics_table)
      end

      def add_node_to_graph(node, graph: nil, as_cluster: false, metrics_table:false)
        assert_graph_state
        raise 'node is required' unless node

        parent_graph = graph || @root_graph
        key = node.to_k

        attrs = { label: node_label(node, metrics_table: metrics_table) }

        if as_cluster
          # tab good shape
          subgraph_name = "cluster_#{key}"
          attrs.merge!(SUBDOMAIN_ATTRS)
          # attrs = {}.merge(SUBDOMAIN_ ATTRS)
          @cluster_node_hash[key] = parent_graph.add_graph(subgraph_name, attrs)

          @cluster_node_hash[key].add_nodes(node_key(node, cluster: :stub), STUB_NODE_ATTRS)

          # @cluster_node_hash[key].attrs(attrs)
          # puts ("attrs: #{key}: #{attrs}  / #{@cluster_node_hash.length}")
        else
          attrs = attrs.merge!(NODE_ATTR)
          @node_hash[key] = parent_graph.add_nodes(key, attrs)
        end
      end

      def append_nodes(nodes, as_cluster: false, metrics_table: false)
        assert_graph_state
        return unless nodes
        # raise 'node is required' unless nodes

        nodes.each do |node|
          parent_node = block_given? ? yield(node) : nil
          # puts "gotit #{parent_node}" if parent_node
          add_node_to_parent(node, parent_node: parent_node, as_cluster: as_cluster, metrics_table: metrics_table)
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

      def add_edges(edges, calc_weight:true)
        assert_graph_state

        # @node_hash.each do |k, v|
        #   log("NODE_HASH: Has value for #{ChaosUtils.decorate(k)} => #{ChaosUtils.decorate(v)}")
        # end

        max_reduce  = edges.map(&:weight).max

        edges.each do |e|
          src_clust, src = find_graph_node(e.src_node)
          dep_clust, dep = find_graph_node(e.dep_node)

          # TODO: normalize for genericicity
          norm_weight = e.weight / max_reduce
          weight = calc_weight ? edge_weight(norm_weight) : 1.0
          @edges << [src, dep]

          # puts "SRC NODE IS #{src.inspect}"
          # Add dependent relation edges for edge_type:
          arrow_type = arrow_type_for(e)

          # puts(['WTF', src.name, node_key(e.src_node, cluster: true)].inspect)

          attrs = EDGE_ATTR.merge(
            ltail: src_clust ? node_key(e.src_node, cluster: true) : '',
            lhead: dep_clust ? node_key(e.dep_node, cluster: true) : '',
            arrowhead: arrow_type,
            arrowsize: 1.0,
            penwidth: weight,
          )

          if calc_weight
            attrs[:headlabel] = "%d" % [e.weight]
            # attrs[:labeldistance] = ".00012" # points
          end

          if e.src_node.domain_name == e.dep_node.domain_name
            attrs.merge!(
              style: 'dotted',
              color: CLR_ORANGE,
              constraint: 'true',
              # headport: 'w',
              # tailport: 'e',
            )
            # puts "ATTRS: #{attrs}"
          end

          @root_graph.add_edges(
            node_key(e.src_node, cluster: src_clust ? :stub : false),
            node_key(e.dep_node, cluster: dep_clust ? :stub : false),
            attrs
          ) # , {label: e.reduce_sum, penwidth: weight})
        end
      end

      def render_graph
        assert_graph_state

        filename = "#{@title}.png"
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
