require_relative 'node_metrics'
require 'chaos_detector/chaos_utils'

module ChaosDetector
  module GraphTheory
    class Appraiser
      attr_reader :cyclomatic_complexity
      attr_reader :node_metrics

      def initialize(graph)
        @graph = graph
        @cyclomatic_complexity = nil
        @node_metrics = {}
      end

      def appraise
        log("Appraising nodes.")
        appraise_nodes

        log("Measuring cyclomatic complexity.")
        measure_cyclomatic_complexity

        log("Performed appraisal: #{report}")
      end

      def to_s
        msg = "N: %d, E: %d" % [@graph.nodes.length, @graph.edges.length]
        if @cyclomatic_complexity.nil?
          msg << "(Please run #appraise to gather metrics.)"
        else
          msg << " M: %d(cyclomatic_complexity), path_count = %d/%d(uniq), circular_paths = %d" % [
            @cyclomatic_complexity,
            @full_paths.length,
            @path_count_uniq,
            @circular_paths.length,
          ]
        end
      end

      def report
        buffy = [to_s]

        buffy << "Circular References #{@circular_paths.length} / #{@circular_paths.uniq.length}"
        buffy.concat(@circular_paths.map do |p|
          "  " + p.map(&:label).join(' -> ')
        end)

        # Gather nodes:
        buffy << "Nodes:"
        buffy.concat(@node_metrics.map{|n, m| "  (#{n.domain_name})#{n.label}: #{m}" })

        buffy.join("\n")
      end

      private
        def log(msg)
          ChaosUtils::log_msg(msg, subject: "GraphTheory")
        end

        def measure_cyclomatic_complexity
          @circular_paths = []
          @full_paths = []
          traverse_nodes([@graph.root_node])
          @path_count_uniq = @circular_paths.uniq.count + @full_paths.uniq.count
          @cyclomatic_complexity = @graph.edges.count - @graph.nodes.count + (2 * @path_count_uniq)
        end

        # TODO: Use edgestack instead of nodestack for easier debugging?:
        def traverse_nodes(nodestack=[get_root_node])
          node = nodestack.last
          if nodestack.index(node) < nodestack.length-1
            # if (@circular_paths.length % 100).zero?
            #   p("@CCCCCCCCcircular_paths.length: #{@circular_paths.length} (#{@circular_paths.uniq.length}) / Nodestack [#{nodestack.length}]: #{nodestack.map(&:mod_name).join(' -> ')}")

            # end
            # LAST NODE IS IN STACK...CIRCULAR
            # log("Node stack is circular: #{nodestack}")
            @circular_paths << nodestack

            if (@circular_paths.length % 100).zero?
              log("Circular deps@#{@circular_paths.length}")
            end
            if @circular_paths.length > 20000
              log("Circular deps@#{@circular_paths.length} exceeded threshold; exiting!")
              puts(report)
            end
          else
            out_edges = fan_out_edges(node)
            if out_edges.none?
              @full_paths << nodestack
              # nodestack
            else
              out_edges.each do |edge|
                traverse_nodes(nodestack + [edge.dep_node])
                # if nodestack.include?(edge.dep_node)
                #   @circular_paths << nodestack + [edge.dep_node]

                #   # p("@circular_paths.length: #{@circular_paths.length} (#{@circular_paths.uniq.length})")
                #   # p("Nodestack [#{nodestack.length}]: #{nodestack.map(&:mod_name).join(' -> ') }")
                #   # p(edge)
                #   # puts
                #   # puts

                #   # if @circular_paths.length > 1000
                #   #   puts("CIRCULAR_ROUTES")
                #   #   @circular_paths.each do |p|
                #   #     puts(p.map{|n|"#{n.domain_name}:#{n.mod_name}"}.join(' -> '))
                #   #   end
                #   #   exit(true)
                #   # end
                # else
                #   traverse_nodes(nodestack + [edge.dep_node])
                # end
              end
            end

            # out_nodes = fan_out_nodes(node)
            # if out_nodes.none?
            #   @full_paths << nodestack
            #   # nodestack
            # else
            #   out_nodes.each { |out_node| traverse_nodes(nodestack + [out_node]) }
            # end
          end
        end

        def fan_out_edges(node)
          @graph.edges.find_all{|e| e.src_node==node }
        end

        def fan_out_nodes(node)
          @graph.edges.find_all{|e| e.src_node==node }.map(&:dep_node)
        end

        def fan_in_nodes(node)
          @graph.edges.find_all{|e| e.dep_node==node }.map(&:src_node)
        end

        def appraise_nodes
          @node_metrics = @graph.nodes.map do |node|
            [node, appraise_node(node)]
          end.to_h
        end

        # For each node, measure fan-in(Ca) and fan-out(Ce)
        def appraise_node(node)
          circular_routes, terminal_routes = appraise_node_routes(node)
          ChaosDetector::GraphTheory::NodeMetrics.new(
            afferent_couplings: @graph.edges.count{|e| e.dep_node==node },
            efferent_couplings: @graph.edges.count{|e| e.src_node==node },
            circular_routes: circular_routes,
            terminal_routes: terminal_routes,
          )
        end

        def appraise_node_routes(node)
          # Traverse starting at each node to see if
          # and how many ways we come back to ourselves
          terminal_routes = []
          circular_routes = []

          return [terminal_routes, circular_routes]
        end

        def adjacency_matrix
          adj_matrix = Matrix.build(@graph.nodes.length) do |row, col|

          end
          adj_matrix
        end

        #  Coupling: Each node couplet (Example for 100 nodes, we'd have 100 * 99 potential couplets)
        #  Capture how many other nodes depend upon both nodes in couplet [directly, indirectly]
        #  Capture how many other nodes from other domains depend upon both [directly, indirectly]
        def node_matrix
          node_matrix = Matrix.build(@graph.nodes.length) do |row, col|

          end
          node_matrix
        end

        # @return positive integer indicating distance in number of vertices
        # from node_src to node_dep.  If multiple routes, calculate shortest:
        def node_distance(node_src, node_dep)

        end

        def normalize(ary, property, norm_property)
          vector = Vector.elements(ary.map{|obj| obj.send(property)})
          vector = vector.normalize
          ary.each_with_index do |obj, i|
            obj.send("#{norm_property}=", vector[i])
          end
          ary
        end


    end
  end
end