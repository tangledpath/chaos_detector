require 'chaos_detector/chaos_graphs/chaos_graphs'

# Consider putting action/event in this class and naming it accordingly
class ChaosDetector::ChaosGraphs::ModInfo
  attr_reader :mod_name
  attr_reader :mod_type

  def initialize(mod_name:, mod_type:nil)
    raise ArgumentError, "mod_name is required" unless Kernel.aught?(mod_name)
    @mod_name = mod_name
    @mod_type = mod_type
  end

  def ==(other)
    self.mod_name == other.mod_name && self.mod_type == other.mod_type
  end

  def to_s
    "%s %s" % [@mod_name, Kernel.decorate(@mod_type, clamp:bracket)]
  end
end
