require 'matrix'
require 'chaos_detector/chaos_utils'
require_relative 'node_metrics'

module ChaosDetector
  module GraphTheory
    class Appraiser
      attr_reader :cyclomatic_complexity
      attr_reader :adjacency_matrix

      def initialize(graph)
        @graph = graph
        @adjacency_matrix = nil
        @cyclomatic_complexity = nil
        @nodes_appraised = {}
      end

      def appraise(update_nodes:true)
        log('Appraising nodes.')
        @nodes_appraised = appraise_nodes!(update_nodes: update_nodes)
        
        # TODO: Store adjacency (to each other node) as a node metric?
        @adjacency_matrix = build_adjacency_matrix(@graph.nodes)

        # log('Measuring cyclomatic complexity.')
        # measure_cyclomatic_complexity

        log("Performed appraisal: %s" % to_s)
      end

      def metrics_for(node:)
        raise ArgumentError, 'Node is required' if node.nil?
        raise ArgumentError, ('Node [%s] has no metrics' % node) if !@nodes_appraised&.include?(node)
        log('has no metrics', object: node) if !@nodes_appraised&.include?(node)
        @nodes_appraised[node]
      end

      def to_s
        format('N: %d, E: %d', @graph.nodes.length, @graph.edges.length)
      end

      def report
        buffy = [to_s]

        # buffy << "Circular References #{@circular_paths.length} / #{@circular_paths.uniq.length}"
        # buffy.concat(@circular_paths.map do |p|
        #   '  ' + p.map(&:title).join(' -> ')
        # end)

        # Gather nodes:
        buffy << 'Nodes:'
        buffy.concat(@nodes_appraised.map { |n, m| "  (#{n.title})[#{n.subtitle}]: #{m}" })

        buffy.join("\n")
      end

      # Returns Hash<Node, NodeMetrics>
      #   update_nodes: Updates all nodes' :graph_props to appraisal metrics hash:
      def appraise_nodes!(update_nodes: true)
        node_metrics = @graph.nodes.map do |node|
          metrics = appraise_node(node)
          [node, metrics]
        end.to_h

        if update_nodes
          node_metrics.each do |node, metrics|
            node.graph_props.merge!(metrics.to_h)
          end
        end

        node_metrics
      end

      def build_adjacency_matrix(nodes)
        matrix_dim = nodes.size
        # nodes = @graph.nodes
        Matrix.build(matrix_dim) do |row, col|
          node_src = nodes[row]
          node_dep = nodes[col]
          # puts "Adjacency found for #{node_src}, #{node_dep}: #{edge&.reduction}  / #{edge&.reduction&.reduction_sum.to_i}"          
          # puts "Adjacency found for #{row}:#{col} -> #{node_src}, #{node_dep}: #{adjacency?(node_src, node_dep)}"          
          adjacency?(node_src, node_dep)
        end
      end

    private

      # For each node, measure fan-in(Ca) and fan-out(Ce)
      def appraise_node(node)
        circular_routes, terminal_routes = appraise_node_routes(node)
        ChaosDetector::GraphTheory::NodeMetrics.new(
          node,
          afference: @graph.edges.count { |e| e.dep_node == node },
          efference: @graph.edges.count { |e| e.src_node == node },
          circular_routes: circular_routes,
          terminal_routes: terminal_routes
        )
      end

      def log(msg, **opts)
        ChaosUtils.log_msg(msg, subject: 'Appraiser', **opts)
      end

      def fan_out_edges(node)
        @graph.edges.find_all { |e| e.src_node == node }
      end

      def fan_out_nodes(node)
        @graph.edges.find_all { |e| e.src_node == node }.map(&:dep_node)
      end

      def fan_in_nodes(node)
        @graph.edges.find_all { |e| e.dep_node == node }.map(&:src_node)
      end

      def appraise_node_routes(_node)
        # Traverse starting at each node to see if
        # and how many ways we come back to ourselves
        terminal_routes = []
        circular_routes = []

        [terminal_routes, circular_routes]
      end

      def adjacency?(node_src, node_dest)
        edge = @graph.edges.find{|e| e.src_node == node_src && e.dep_node == node_dest }
        edge&.reduction&.reduction_sum.to_i
      end

      #  Coupling: Each node couplet (Example for 100 nodes, we'd have 100 * 99 potential couplets)
      #  Capture how many other nodes depend upon both nodes in couplet [directly, indirectly]
      #  Capture how many other nodes from other domains depend upon both [directly, indirectly]
      # TODO??  
      def node_matrix
        node_matrix = Matrix.build(@graph.nodes.length) do |row, col|
        end
        node_matrix
      end

      def measure_cyclomatic_complexity
        @circular_paths = []
        @full_paths = []
        traverse_nodes([@graph.root_node])
        @path_count_uniq = @circular_paths.uniq.count + @full_paths.uniq.count
        @cyclomatic_complexity = @graph.edges.count - @graph.nodes.count + (2 * @path_count_uniq)
      end

      # @return positive integer indicating distance in number of vertices
      # from node_src to node_dep.  If multiple routes, calculate shortest:
      def node_distance(node_src, node_dep); end

      def normalize(ary, property, norm_property)
        vector = Vector.elements(ary.map { |obj| obj.send(property)})
        vector = vector.normalize
        ary.each_with_index do |obj, i|
          obj.send("#{norm_property}=", vector[i])
        end
        ary
      end
    end
  end
end
