class ChaosDetector::StackFrame
  attr_reader :domain_name
  attr_reader :mod_name
  attr_reader :mod_type
  attr_reader :path
  attr_reader :fn_name
  attr_reader :line_num

  def initialize(mod_type:, mod_name:, path:, domain_name:nil, fn_name:nil, line_num: nil)
    @mod_type = mod_type
    @mod_name = mod_name
    @path = path
    @domain_name = domain_name
    @fn_name = fn_name
    @line_num = line_num
  end


  def match?(other)
    if !other.nil? && @domain_name == other.domain_name && @path == other.path
      # We found our minimum level of matching; see what else matches:
      m = @mod_name == other.mod_name
      f = @fn_name == other.fn_name
      l = @line_num == other.line_num
      if m && f
        l ? :exact : :full
      elsif m || f
        :partial
      else
        :base
      end
    else
      nil
    end
  end

  # Line number is not considered when comparing:
  def ==(other)
    [:exact, :full].include?(match?(other))
  end

  def to_s
    hkey = "["
    hkey << "(#{@domain_name}) " unless @domain_name.nil? || @domain_name.empty?
    hkey << "#{@mod_type} " unless @mod_type.nil? || @mod_type.empty?
    hkey << @mod_name unless @mod_name.nil? || @mod_name.empty?
    hkey << "::#{@fn_name}" unless @fn_name.nil? || @fn_name.empty?
    hkey << " '#{@path}'" unless @path.nil? || @path.empty?
    hkey << "]"
    hkey << "(L##{@line_num})" unless @line_num.nil?

  end
end
