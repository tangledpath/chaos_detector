require 'chaos_detector/utils'

class ChaosDetector::ModInfo
  extend ChaosDetector::Utils::ChaosAttr
  ModuleType = ChaosDetector::Utils.enum(:module, :class, :unknown)

  attr_reader :mod_type#, ModuleType::UNKNOWN
  attr_reader :mod_name
  attr_reader :mod_path

  def initialize(mod_name, mod_path:, mod_type: nil)
    @mod_name = mod_name
    @mod_type = mod_type
    @mod_path = mod_path
  end

  def to_s
    [@mod_name, @mod_type, @mod_path].join(', ')
  end
end

class ChaosDetector::StackFrame
  SimilarityRating = ChaosDetector::Utils.enum(:base, :partial, :full, :exact)
  #   nil on no match
  #   :exact when all fields match
  #   :full when all fields except line_num match
  #   :partial domain and mod_path match AND a module OR function match
  #   :base when domain and mod_path match
    VERY_SIMILAR = [SimilarityRating::EXACT, SimilarityRating::FULL].freeze

  attr_reader :domain_name
  attr_reader :mod_name
  attr_reader :mod_type
  attr_reader :mod_path
  attr_reader :fn_name
  attr_reader :line_num
  attr_accessor :note

  def initialize(mod_info: nil, mod_type: nil, mod_name: nil, mod_path: nil, domain_name:nil, fn_name:nil, line_num: nil, note: nil)

    if [mod_name, mod_info&.mod_name].all?("ChaosDetector::Utils.naught?")

    # unless ChaosDetector::Utils.any?(mod_name, mod_info&.mod_name)
      puts "------------------------------"
      puts "(#{mod_name.class}) *** mod_name: #{mod_name.inspect}"
      puts "(#{mod_info.class}) *** mod_info: #{mod_info.inspect}"

      raise ArgumentError, "Requires module name via mod_name or mod_info."
    end

  #  if [mod_name, mod_info&.mod_name].all?ChaosDetector::Utils.naught?
  # puts "(#{mod_name.class}) *** mod_name: #{mod_name.inspect}"
  # puts "(#{mod_info.class}) *** mod_info: #{mod_info.inspect}"

    @mod_type = mod_type || mod_info&.mod_type
    @mod_name = mod_name || mod_info&.mod_name

    @mod_path = mod_path || mod_info&.mod_path
    @domain_name = domain_name
    @fn_name = fn_name
    @line_num = line_num
    @note = note
  end

  def to_csv_row(supplement:nil)
    fields = [@domain_name, @mod_name, @mod_type, @mod_path, @line_num, @fn_name]
    # , @note
    fields.concat(supplement) unless supplement.nil?
    ChaosDetector::Utils.to_csv_row(fields)
  end

  def self.from_csv_row(csv_row_text)
    domain_name, mod_name, mod_type, mod_path, fn_name, line_num, note = ChaosDetector::Utils.from_csv_row(csv_row_text)
    StackFrame.new(domain_name: domain_name, mod_type:mod_type, mod_name: mod_name, mod_path: mod_path, fn_name: fn_name, line_num:line_num, note: note)
  end

  # Returns nil if no match and SimilarityRating otherwise
  def match?(other)
    if !other.nil? && @domain_name == other.domain_name && @mod_path == other.mod_path
      # We found our minimum level of matching; see what else matches:
      m = @mod_name == other.mod_name
      f = @fn_name == other.fn_name
      l = @line_num == other.line_num
      if m && f
        l ? SimilarityRating::EXACT : SimilarityRating::FULL
      elsif m
        SimilarityRating::PARTIAL
      else
        SimilarityRating::BASE
      end
    else
      nil
    end
  end

  # Line number is not considered when comparing:
  def ==(other)
    VERY_SIMILAR.include?(match?(other))
  end

  def to_s
    hkey = "["
    hkey << "(#{@domain_name}) " unless @domain_name.nil? || @domain_name.empty?
    hkey << "<#{@mod_type.to_s[0].upcase}> " unless @mod_type.nil? || @mod_type =="" #.empty?
    hkey << @mod_name unless @mod_name.nil? || @mod_name.empty?
    hkey << "::#{@fn_name}" unless @fn_name.nil? || @fn_name.empty?
    hkey << " '#{@mod_path}'" unless @mod_path.nil? || @mod_path.empty?
    hkey << "]"
    hkey << "(L##{@line_num})" unless @line_num.nil?

  end

  def describe
    hkey = to_s
    hkey << " - #{@note}" unless @note.nil?
  end
end