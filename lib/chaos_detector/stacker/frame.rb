require 'tcs/refined_utils'
using TCS::RefinedUtils

# A single stack (tracepoint) frame
module ChaosDetector
  module Stacker
    class Frame
      attr_reader :domain_name
      attr_reader :mod_name
      attr_reader :mod_type
      attr_reader :fn_path
      attr_reader :fn_name
      attr_reader :callee
      attr_reader :line_num

      def initialize(mod_name: nil, mod_type: nil, fn_path: nil, domain_name:nil, fn_name:nil, line_num: nil, callee: nil)
        if naught?(mod_name)
          msg = ("Frame init requires mod_name %s :: %s - %s" % [
            decorate(domain_name),
            decorate(fn_name),
            decorate(fn_path)
          ])
          raise ArgumentError, msg
        end

        @mod_type = mod_type
        @mod_name = mod_name

        @fn_path = fn_path
        @domain_name = domain_name
        @fn_name = fn_name
        @line_num = line_num
        @callee = callee
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
  end
end