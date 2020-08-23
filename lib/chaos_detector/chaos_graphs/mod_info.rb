require 'chaos_detector/chaos_graphs/chaos_graphs'

# Consider putting action/event in this class and naming it accordingly
class ChaosDetector::ChaosGraphs::ModInfo
  attr_reader :mod_name
  attr_reader :mod_path
  attr_reader :mod_type

  def initialize(mod_name:, mod_path:, mod_type:nil)
    raise ArgumentError, "mod_name is required" unless Kernel.aught?(mod_name)
    @mod_name = mod_name
    @mod_path = mod_path
    @mod_type = mod_type
  end

  def == (other)
    self.mod_name == other.mod_name && self.mod_path == other.mod_path && self.mod_type == other.mod_type
  end

  def to_s
    p = @mod_path.split("/").last(2).join("/")
    "%s %s - %s" % [@mod_name, Kernel.decorate(@mod_type, clamp:bracket), p]
  end
end
