require 'chaos_detector/utils'
module ChaosDetector
class StackFrame
  SimilarityRating = ChaosDetector::Utils.enum(:base, :partial, :full, :exact)
#   nil on no match
  #   :exact when all fields match
  #   :full when all fields except line_num match
  #   :partial domain and path match AND a module OR function match
  #   :base when domain and path match
  VERY_SIMILAR = [SimilarityRating::Exact, SimilarityRating::Full].freeze

  attr_reader :domain_name
  attr_reader :mod_name
  attr_reader :mod_type
  attr_reader :path
  attr_reader :fn_name
  attr_reader :line_num
  attr_accessor :note

  def initialize(mod_type:, mod_name:, path:, domain_name:nil, fn_name:nil, line_num: nil, note: nil)
    @mod_type = mod_type
    @mod_name = mod_name
    @path = path
    @domain_name = domain_name
    @fn_name = fn_name
    @line_num = line_num
    @note = note
  end

  def to_csv_row(supplement:nil)
    fields = [@domain_name, @mod_name, @mod_type, @path, @fn_name, @line_num]
    # , @note
    fields.concat(supplement) unless supplement.nil?
    ChaosDetector::Utils.to_csv_row(fields)
  end

  def self.from_csv_row(csv_row_text)
    domain_name, mod_name, mod_type, path, fn_name, line_num, note = ChaosDetector::Utils.from_csv_row(csv_row_text)
    StackFrame.new(domain_name: domain_name, mod_type:mod_type, mod_name: mod_name, path: path, fn_name: fn_name, line_num:line_num, note: note)
  end

  # Returns nil if no match and SimilarityRating otherwise
  def match?(other)
    if !other.nil? && @domain_name == other.domain_name && @path == other.path
      # We found our minimum level of matching; see what else matches:
      m = @mod_name == other.mod_name
      f = @fn_name == other.fn_name
      l = @line_num == other.line_num
      if m && f
        l ? SimilarityRating::Exact : SimilarityRating::Full
      elsif m
        SimilarityRating::Partial
      else
        SimilarityRating::Base
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
    hkey << "#{@mod_type} " unless @mod_type.nil? || @mod_type.empty?
    hkey << @mod_name unless @mod_name.nil? || @mod_name.empty?
    hkey << "::#{@fn_name}" unless @fn_name.nil? || @fn_name.empty?
    hkey << " '#{@path}'" unless @path.nil? || @path.empty?
    hkey << "]"
    hkey << "(L##{@line_num})" unless @line_num.nil?

  end

  def describe
    hkey = to_s
    hkey << " - #{@note}" unless @note.nil?
  end
end
end