require_relative 'frame'

require 'tcs/refined_utils'
using TCS::RefinedUtils


# Maintains all nodes and infers edges as stack calls are pushed and popped via Frames.
module ChaosDetector
  module Stacker
    class FrameStack
      def initialize()
        @stack = []
      end

      def log(msg)
        log_msg(msg, subject: "FrameStack")
      end

      def depth
        @stack.length
      end

      def peek
        @stack.first
      end

      def pop(frame)
        raise ArgumentError, "Current Frame is required" if frame.nil?
        @stack.index(frame).tap do |n_frame|
          if n_frame && n_frame > 0
            log("Popping out of order: #{@stack[n_frame]}")
          end
          @stack.slice!(0..n_frame) unless n_frame.nil?
        end
      end

      def push(frame)
        @stack.unshift(frame)
      end

      def to_s
        "Frames: %d" % stack_depth
      end
    end
  end
end