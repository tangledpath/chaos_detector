require 'forwardable'

require 'chaos_detector/utils'
require 'chaos_detector/chaos_graphs/module_node'

class ChaosDetector::StackFrame
  extend Forwardable
  attr_reader :domain_name
  attr_reader :mod_info
  attr_reader :fn_path
  attr_reader :fn_name
  attr_reader :callee
  attr_reader :line_num
  def_instance_delegators :@mod_info, :mod_name, :mod_type

  def initialize(mod_info: nil, mod_name: nil, mod_type: nil, fn_path: nil, domain_name:nil, fn_name:nil, line_num: nil, callee: nil)

    if [mod_name, mod_info&.mod_name].all?("ChaosDetector::Utils.naught?")
      raise ArgumentError, "Requires module name via mod_name or mod_info."
    end

    @mod_type = mod_type || mod_info&.mod_type
    @mod_name = mod_name || mod_info&.mod_name

    @fn_path = fn_path
    @domain_name = domain_name
    @fn_name = fn_name
    @line_num = line_num
    @callee = callee

    if mod_info
      @mod_info = mod_info
    elsif Kernel.aught?mod_name
      @mod_info = ChaosDetector::ChaosGraphs::ModuleNode.new(mod_name:mod_name, mod_type: mod_type)
    end
  end

  def ==(other)
    self.domain_name == other.domain_name &&
    self.fn_name == other.fn_name &&
    self.fn_path == other.fn_path
  end

  def to_s
    hkey = "["
    hkey << "(#{@domain_name}) " unless @domain_name.nil? || @domain_name.empty?
    hkey << "<#{@mod_type.to_s[0].upcase}> " unless @mod_type.nil? || @mod_type =="" #.empty?
    hkey << @mod_name unless @mod_name.nil? || @mod_name.empty?
    hkey << "::#{@fn_name}" unless @fn_name.nil? || @fn_name.empty?
    hkey << "/#{@callee}" unless @callee.nil? || @callee.empty?
    hkey << " '#{@fn_path}'" unless @fn_path.nil? || @fn_path.empty?
    hkey << "]"
    hkey << "(L##{@line_num})" unless @line_num.nil?
  end
end