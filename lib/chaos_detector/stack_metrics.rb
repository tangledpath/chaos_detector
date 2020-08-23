class ChaosDetector::StackMetrics
  def initialize
    @push_count = 0
    @pop_count = 0
    @close_count = 0
    # @match_unideal_count = 0
    @match_nonzero_count = 0
  end

  def record_open_action
    @push_count += 1
  end

  def record_close_action(frame_n)
    if frame_n.nil?
      @close_count += 1
    else
      @pop_count += 1
      # @match_unideal_count += 1
      @match_nonzero_count += 1 if frame_n > 0
    end
  end

  def to_s
    m << decorate(ROOT_NODE_NAME, clamp: :parens) if @is_root
    "Total: %s [+push -pop (-close)] +%d -%d(%d) >> stack-pos-off: %d" % [
      decorate(@push_count + @pop_count + @close_count, clamp: :bracket),
      @push_count,
      @pop_count,
      @close_count,
      # @match_unideal_count,
      @match_nonzero_count
    ]
  end
end
