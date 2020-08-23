require 'matrix'

module ChaosDetector::GraphTheory
  class NodeMetrics
    # https://en.wikipedia.org/wiki/Software_package_metrics
    # https://en.wikipedia.org/wiki/Efferent_coupling

    # This metric is often used to calculate instability of a component in software architecture as

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
    attr_accessor :afferent_couplings
    attr_accessor :efferent_couplings

    # https://en.wikipedia.org/wiki/Cyclomatic_complexity
    # M = E − N + 2P,

    def initialize(afferent_couplings: 0, efferent_couplings: 0)
      @afferent_couplings = afferent_couplings
      @efferent_couplings = efferent_couplings
    end

    # https://en.wikipedia.org/wiki/Software_package_metrics
    # I = Ce / (Ce + Ca).
    # I = efferent_couplings / (total couplings)
    # Value from 0.0 to 1.0
    # I = 0.0 is maximally stable while
    # I = 1.0 is maximally unstable.
    def instability
      cT = total_couplings
      cT == 0 ? 0.0 : @efferent_couplings / cT
    end

    def total_couplings
      @afferent_couplings + @efferent_couplings
    end

    def to_s
      "Ce: #{@efferent_couplings}, Ca: #{@afferent_couplings}, I: #{instability}"
    end

  end
end