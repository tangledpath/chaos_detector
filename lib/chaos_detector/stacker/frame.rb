require 'chaos_detector/chaos_utils'
require 'chaos_detector/stacker/mod_info'
require 'chaos_detector/stacker/fn_info'

# A single stack (tracepoint) frame
module ChaosDetector
  module Stacker
    class Frame
      attr_reader :event # 'call', 'return'
      attr_reader :mod_info
      attr_reader :fn_info
      attr_reader :caller_fn_info

      def initialize(event:, mod_info:, fn_info:, caller_fn_info:)
        raise ArgumentError, "event is required" if ChaosUtils.naught?(event)
        # raise ArgumentError, "mod_info is required" if ChaosUtils.naught?(mod_info)
        raise ArgumentError, "fn_info is required" if ChaosUtils.naught?(fn_info)

        @mod_info = mod_info
        @fn_info = fn_info
        @caller_fn_info = caller_fn_info
        @event = event
      end

      def to_s
        "{#{@mod_info}} -> {#{@fn_info}}"
      end
    end
  end
end