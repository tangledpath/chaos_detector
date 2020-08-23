require 'chaos_detector/nodes/nodes'

# Consider putting action/event in this class and naming it accordingly
class ChaosDetector::Nodes::ModuleNode
  extend ChaosDetector::Utils::ChaosAttr
  ModuleType = ChaosDetector::Utils.enum(:module, :class, :unknown)

  attr_reader :mod_type#, ModuleType::UNKNOWN
  attr_reader :mod_name

  def initialize(mod_name:, mod_type:nil)
    @mod_name = mod_name
    @mod_type = mod_type
  end

  def ==(other)
    self.mod_name == other.mod_name && self.mod_type == other.mod_type
  end

  def domain_name
    # Maybe get from fn_node
  end

  def label
    # Shorten long module paths:
    m = @mod_name.split("::").last(2).join("::")
    m << decorate(@mod_type, clamp: :parens)
    # "#{m}\n#{@domain_name}"
  end

  def to_s
    [@mod_name, @mod_type].join(', ')
  end
end
