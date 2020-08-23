require 'digest'
require 'chaos_detector/edge'
require 'chaos_detector/node'
require 'chaos_detector/options'
require 'chaos_detector/stack_frame'
require 'chaos_detector/utils'
require 'csv'


# TODO: add traversal types to find depth, coupling in various ways (directory/package/namespace):
class ChaosDetector::Walkman
  CSV_HEADER = %w{ACTION DOMAIN_NAME MOD_NAME MOD_TYPE MOD_PATH LINE_NUM FN_NAME DEPTH OFFSET NODES EDGES MATCH_OFFSET SIMILARITY}
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
    File.open(csv_path, "w") {|f| f.puts CSV_HEADER.join(",")}
  end

  def each
    log("Walkman replaying CSV: #{csv_path}")
    CSV.foreach(csv_path, headers: true) do |row|
      stack_frame = ChaosDetector::StackFrame.new(
        mod_type: csv_row_val(row, :mod_type),
        mod_name: csv_row_val(row, :mod_name),
        mod_path: csv_row_val(row, :mod_path),
        domain_name: csv_row_val(row, :domain_name),
        fn_name: csv_row_val(row, :fn_name),
        line_num: csv_row_val(row, :line_num)
      )
      yield csv_row_val(row, :action), stack_frame
    end
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
      log("Triggering flush @#{@log_buffer.length} / @buffer_length")
      flush_csv
    end
  end

  def log(msg)
    ChaosDetector::Utils.log(msg, subject: "Walkman")
  end

  def flush_csv
    log("Flushing...")
    if @log_buffer && @log_buffer.any?
      CSV.open(csv_path, "a") do |csv|
        @log_buffer.each do |log_line|
          csv << log_line
        end
      end
      @log_buffer.clear
    end
  end

  def write_frame(frame, action:, match: nil)
    action = action
    csv_row = [action]
    csv_row.concat(frame_csv_fields(frame))
    csv_row.concat(atlas_csv_fields)
    csv_row.concat(match) if match

    @log_buffer << csv_row
    buffered_trigger
  end

  private
    def csv_row_val(row, col_header)
      r = COL_INDEXES[col_header]
      if r.nil? || r < 0 || r > COL_COUNT
        raise ArgumentError, "#{col_header} not found in CSV_HEADER: #{CSV_HEADER}"
      end

      row[r]
    end

    def frame_csv_fields(f)
      [f.domain_name, f.mod_name, f.mod_type, f.mod_path, f.line_num, f.fn_name]
    end

    def atlas_csv_fields
      [@atlas.frame_stack.length, @atlas.offset, @atlas.nodes.length, @atlas.edges.length]
    end

end