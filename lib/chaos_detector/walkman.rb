require 'digest'
require 'graph_theory/edge'
require 'chaos_detector/chaos_graphs/function_node'
require 'chaos_detector/options'
require 'chaos_detector/stacker/frame'
require 'tcs/utils/util'
require 'tcs/utils/fs_util'
require 'csv'


# TODO: add traversal types to find depth, coupling in various ways (directory/package/namespace):
class ChaosDetector::Walkman
  PLAYBACK_MSG = "Playback error on line number %d of pre-recorded CSV %s:\n  %s\n  %s".freeze
  CSV_HEADER = %w{ACTION DOMAIN_NAME MOD_NAME MOD_TYPE FN_PATH LINE_NUM FN_NAME DEPTH NODES EDGES MATCH_OFFSET}
  COL_COUNT = CSV_HEADER.length
  COL_INDEXES = CSV_HEADER.map.with_index {|col, i| [col.downcase.to_sym, i]}.to_h

  DEFALT_BUFFER_LENGTH = 1000

  def initialize(atlas:, options:)
    @buffer_length = options.walkman_buffer_length || DEFALT_BUFFER_LENGTH
    @atlas = atlas
    @options = options
    flush_csv
    @csv_path = nil
    @log_buffer = []
  end

  def record_start
    flush_csv
    @csv_path = nil
    @log_buffer = []
    autosave_csv
    init_file_with_header(csv_path)
  end

  # Play back CSV configured in Walkman options
  # yields each row as
  #   action A symbol denoting the type of action for the recorded frame
  #   frame A Frame object with its attributes contained in the CSV row
  def playback
    log("Walkman replaying CSV: #{csv_path}")
    row_num = 0
    row_cur = nil
    CSV.foreach(csv_path, headers: true) do |row|
      row_num += 1
      row_cur = row
      action, frame = playback_row(row)
      log("playback_row= [#{action}]: #{frame}")
      yield action, frame
    end
  rescue StandardError => x
    raise ScriptError, log(PLAYBACK_MSG % [row_num, csv_path, row_cur, x.inspect])
  end

  def count
    `wc -l #{csv_path}`.to_i
  end

  # Call when done to flush any buffers as necessary
  def stop
    flush_csv
    log("Stopped with #{count} lines.")
    self
  end

  def csv_path
    @csv_path ||= File.join(@options.log_root_path, @options.frame_csv_path)
  end

  def autosave_csv
    csvp = csv_path
    1.upto(100) do |n|
      p = "#{csvp}.#{n}"
      unless FileTest.exist?(p)
        log("Autosaving #{csvp} to #{p}")
        log(`cp #{csvp} #{p}`)
        break
      end
    end
  end

  def buffered_trigger
    if @log_buffer.length > @buffer_length
      # log("Triggering flush @#{@log_buffer.length} / @buffer_length")
      flush_csv
    end
  end

  def log(msg)
    TCS::Utils::Util.log(msg, subject: "Walkman")
  end

  def flush_csv
    # log("Flushing...")
    if @log_buffer && @log_buffer.any?
      CSV.open(csv_path, "a") do |csv|
        @log_buffer.each do |log_line|
          csv << log_line
        end
      end
      @log_buffer.clear
    end
  end

  def write_frame(frame, action:, frame_offset:nil)
    action = action
    csv_row = [action]
    csv_row.concat(frame_csv_fields(frame))
    csv_row.concat(atlas_csv_fields(frame_offset: frame_offset))

    @log_buffer << csv_row
    buffered_trigger
  end

  private

    def atlas_csv_fields(frame_offset: nil)
      [@atlas.stack_depth, @atlas.graph.nodes.length, @atlas.graph.edges.length, frame_offset]
    end

    def csv_row_val(row, col_header)
      r = COL_INDEXES[col_header]
      if r.nil? || r < 0 || r > COL_COUNT
        raise ArgumentError, "#{col_header} not found in CSV_HEADER: #{CSV_HEADER}"
      end

      row[r]
    end

    def frame_csv_fields(f)
      [f.domain_name, f.mod_name, f.mod_type, f.fn_path, f.line_num, f.fn_name]
    end

    def init_file_with_header(filepath)
      TCS::Utils::FSUtil::ensure_paths_to_file(filepath)
      File.open(filepath, "w") {|f| f.puts CSV_HEADER.join(",")}
    end

    # Play back a single given row
    # returns the action and frame as described in #playback
    def playback_row(row)
      action = csv_row_val(row, :action)
      frame = ChaosDetector::Stacker::Frame.new(
        mod_type: csv_row_val(row, :mod_type),
        mod_name: csv_row_val(row, :mod_name),
        fn_path: csv_row_val(row, :fn_path),
        domain_name: csv_row_val(row, :domain_name),
        fn_name: csv_row_val(row, :fn_name),
        line_num: csv_row_val(row, :line_num)
      )
      [action, frame]
    end
end