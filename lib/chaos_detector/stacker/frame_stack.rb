require_relative 'frame'

require 'chaos_detector/chaos_utils'
# Maintains all nodes and infers edges as stack calls are pushed and popped via Frames.
module ChaosDetector
  module Stacker
    class FrameStack
      def initialize()
        @stack = []
      end

      def log(msg)
        ChaosUtils::log_msg(msg, subject: "FrameStack")
      end

      def depth
        @stack.length
      end

      def peek
        @stack.first
      end

      def pop(frame)
        raise ArgumentError, "Current Frame is required" if frame.nil?

        n_frame = @stack.index(frame)
        if frame.fn_name == 'awaiting_quotes?'
          log("Looking for #{frame.fn_name}: #{n_frame.inspect}")
        end

        if n_frame.nil?
          log("Could not find #{frame} in stack")
          log(self.inspect)
        end

          # if !n_frame.nil? && n_frame > 0
          #   # log("Popping out of order@#{@stack.length} ##{n_frame}: #{@stack[n_frame]}")
          # end
          # log("Perfect match @#{@stack.length}") if !n_frame.nil? && n_frame==0
        @stack.slice!(0..n_frame) unless n_frame.nil?

        #TOOO: yield actual sliced frame:
        n_frame
      end

      def push(frame)
        @stack.unshift(frame)
      end

      def to_s
        "Frames: %d" % depth
      end

      def inspect
        msg = "#{to_s}\n"
        msg << ChaosUtils::decorate_tuple(@stack.map{|f| f.to_s}, join_str: " -> \n", indent_length: 2, clamp: :none)
        msg
      end

    end
  end
end