require 'chaos_detector/chaos_graphs/chaos_graphs'

# Consider putting action/event in this class and naming it accordingly
class ChaosDetector::ChaosGraphs::ModuleNode < GraphTheory::Node
  attr_reader :mod_type # :unknown, :module, :class
  attr_reader :domain_name
  alias_method :mod_name, :name

  def initialize(mod_name:, domain_name: nil, mod_type:nil)
    super(name:mod_name)
    @mod_type = mod_type
    @domain_name = domain_name
  end

  def ==(other)
    self.mod_name == other.mod_name && self.mod_type == other.mod_type
  end

  def domain_name
    # Maybe get from fn_node
  end

  def label
    # Shorten long module paths:
    m = mod_name.split("::").last(2).join("::")
    m << decorate(@mod_type, clamp: :parens)
  end

  def to_s
    [mod_name, @mod_type].join(', ')
  end
end
