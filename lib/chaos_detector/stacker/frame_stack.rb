require 'chaos_detector/stacker/stacker'
require 'chaos_detector/utils'

# Maintains stack of trace frames
class ChaosDetector::Stacker::FrameStack
  def initialize()
    @stack = []
  end

  def log(msg)
    ChaosDetector::Utils.log(msg, subject: "FrameStack")
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