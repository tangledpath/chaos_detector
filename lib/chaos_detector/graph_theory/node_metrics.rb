require 'matrix'

module ChaosDetector::GraphTheory
  class NodeMetrics
    # https://en.wikipedia.org/wiki/Efferent_coupling
    # This metric is often used to calculate instability of a component in software architecture as
    # I = Fan-out / (Fan-in + Fan-out). This metric has a range [0,1]. I = 0 is maximally stable while
    # I = 1 is maximally unstable.

    # Fan-in of M: number of modules calling functions in M
    # Fan-out of M: number of modules called by M
    # * fan-in afferent_coupling(Ca)
    # * fan-out efferent_coupling(Ce)

    # * Cohesion: calls
    #   inside the
    #   module
    # * Coupling: calls
    #   between the
    #   modules
    attr_accessor :src_count
    attr_accessor :dep_count

    # https://en.wikipedia.org/wiki/Cyclomatic_complexity
    # M = E − N + 2P,

    def initialize
      @src_count = 0
      @dep_count = 0
    end

    class << self
      def
      def node_graph_metrics(nodes)
        coupling_matrix = Matrix.build(@nodes.length) do |row, col|

        end
        coupling_matrix
      end
    end

    def to_s
      "Dependent(from) Count: %d, Dependee(to) Count: %d, "
    end


  end
end