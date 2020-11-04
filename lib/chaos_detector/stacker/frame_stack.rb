require_relative 'frame'

require 'chaos_detector/chaos_utils'
# Maintains all nodes and infers edges as stack calls are pushed and popped via Frames.
module ChaosDetector
  module Stacker
    class FrameStack
      def initialize
        @methods = []
        @modules = []
      end

      def log(msg, **opts)
        ChaosUtils.log_msg(msg, subject: 'FrameStack', **opts)
      end

      def depth
        @stack.length
      end

      def peek
        @stack.first
      end

      def pop(frame)
        raise ArgumentError, 'Current Frame is required' if frame.nil?

        popped_frame, n_frame = @stack.each_with_index.find do |f, n|
          if f == frame
            true
          elsif n.zero? && frame.fn_name == f.fn_name
            # log("Matching #{f} \nto:\n #{frame} as most recent entry in stack.")
            true
          else
            false
          end
        end

        # if n_frame.nil?
        #   log("Could not find #{frame} in stack")
        #   log(self.inspect)
        # end

        @stack.slice!(0..n_frame) unless n_frame.nil?
        [popped_frame, n_frame]
      end

      def push(frame)
        @stack.unshift(frame)
      end

      def to_s
        'Frames: %d' % depth
      end

      def inspect
        msg = "#{self}\n"
        msg << ChaosUtils.decorate_tuple(@stack.map { |f| f.to_s}, join_str: " -> \n", indent_length: 2, clamp: :none)
        msg
      end
    end
  end
end
