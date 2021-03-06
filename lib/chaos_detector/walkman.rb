require 'csv'
require 'digest'

require 'chaos_detector/utils/fs_util'
require 'chaos_detector/chaos_utils'

require_relative 'options'
require_relative 'stacker/frame'

# TODO: add traversal types to find depth, coupling in various ways (directory/package/namespace):
module ChaosDetector
  class Walkman
    PLAYBACK_MSG = "Playback error on line number %d of pre-recorded CSV %s:\n  %s\n  %s".freeze
    CSV_HEADER = %w[ROWNUM EVENT MOD_NAME MOD_TYPE FN_PATH FN_LINE FN_NAME CALLER_TYPE CALLER_PATH CALLER_INFO CALLER_NAME].freeze
    COL_COUNT = CSV_HEADER.length
    COL_INDEXES = CSV_HEADER.map.with_index { |col, i| [col.downcase.to_sym, i]}.to_h

    DEFALT_BUFFER_LENGTH = 1000

    def initialize(options:)
      @buffer_length = options.walkman_buffer_length || DEFALT_BUFFER_LENGTH
      @options = options
      flush_csv
      @csv_path = nil
      @log_buffer = []
      @rownum = 0
    end

    def record_start
      flush_csv
      @csv_path = nil
      @log_buffer = []
      @rownum = 0
      autosave_csv
      init_file_with_header(csv_path)
    end

    # Return frame at given index or nil if nothing:
    def frame_at(row_index:)
      frames_within(row_range: row_index..row_index).first
    end

    # Return any frames within specified row range; empty array if not found:
    def frames_within(row_range: nil)
      to_enum(:playback, row_range: row_range).map { |_r, frame| frame }
    end

    # Play back CSV from path configured in Walkman options
    # @param row_range optionally specify range of rows.  Leave nil for all.
    # yields each row as
    #   frame A Frame object with its attributes contained in the CSV row
    def playback(row_range: nil)
      started_at = Time.now

      if row_range
        log('Walkman replaying CSV with (row_range) %d/%d lines: %s' % [
          [count, row_range.max].min,
          count,
          csv_path
        ])
      else
        log("Walkman replaying CSV with #{count} lines: #{csv_path}")
      end

      @rownum = 0
      row_cur = nil
      CSV.foreach(csv_path, headers: true) do |row|
        row_cur = row
        yield @rownum, playback_row(row) if row_range.nil? || row_range.include?(@rownum)
        @rownum += 1
        break if row_range && @rownum > row_range.max
      end
    rescue StandardError => e
      log("%s:\n%s" % [e.to_s, e.backtrace.join("\n")])
      raise ScriptError, log(format(PLAYBACK_MSG, @rownum, csv_path, row_cur, e.inspect))
    ensure
      log('Replayed %d items in %.2f seconds' % [@rownum, Time.now - started_at])
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
      @csv_path ||= @options.path_with_root(key: :frame_csv_path)
    end

    def autosave_csv
      csvp = csv_path
      if FileTest.exist?(csvp)
        1.upto(100) do |n|
          p = "#{csvp}.#{n}"
          next if FileTest.exist?(p)

          log("Autosaving #{csvp} to #{p}")
          cp_result = `cp #{csvp} #{p}`
          log(cp_result)
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

    def log(msg, **opts)
      ChaosUtils.log_msg(msg, subject: 'Walkman', **opts)
    end

    def flush_csv
      # log("Flushing...")
      if @log_buffer&.any?
        CSV.open(csv_path, 'a') do |csv|
          @log_buffer.each do |log_line|
            csv << log_line
          end
        end
        @log_buffer.clear
      end
    end

    def write_frame(frame, frame_offset: nil)
      csv_row = [@rownum]
      csv_row.concat(frame_csv_fields(frame))

      @log_buffer << csv_row
      @rownum += 1
      buffered_trigger
    end

  private

    def csv_row_val(row, col_header)
      r = COL_INDEXES[col_header]
      raise ArgumentError, "#{col_header} not found in CSV_HEADER: #{CSV_HEADER}" if r.nil? || r < 0 || r > COL_COUNT

      row[r]
    end

    def frame_csv_fields(f)
      [
        f.event,
        f.mod_info&.mod_name,
        f.mod_info&.mod_type,
        f.fn_info.fn_path,
        f.fn_info.fn_line,
        f.fn_info.fn_name,
        f.caller_info&.component_type,
        f.caller_info&.path,
        f.caller_info&.info,
        f.caller_info&.name
      ]
    end

    def init_file_with_header(filepath)
      ChaosDetector::Utils::FSUtil.ensure_paths_to_file(filepath)
      File.open(filepath, 'w') { |f| f.puts CSV_HEADER.join(',')}
    end

    # Play back a single given row
    # returns the event and frame as described in #playback
    def playback_row(row)
      event = csv_row_val(row, :event)
      fn_path = csv_row_val(row, :fn_path)
      fn_line = csv_row_val(row, :fn_line)&.to_i

      mod_info = ChaosDetector::Stacker::ModInfo.new(
        mod_name: csv_row_val(row, :mod_name),
        mod_path: fn_path,
        mod_type: csv_row_val(row, :mod_type)
      )

      fn_info = ChaosDetector::Stacker::FnInfo.new(
        fn_name: csv_row_val(row, :fn_name),
        fn_line: fn_line,
        fn_path: fn_path
      )

      caller_info = ChaosUtils.with(csv_row_val(row, :caller_type)) do |caller_type|
        if caller_type.to_sym == :function
          ChaosDetector::Stacker::FnInfo.new(
            fn_name: csv_row_val(row, :caller_name),
            fn_line: csv_row_val(row, :caller_info)&.to_i,
            fn_path: csv_row_val(row, :caller_path)
          )
        else
          ChaosDetector::Stacker::ModInfo.new(
            mod_name: csv_row_val(row, :caller_name),
            mod_path: csv_row_val(row, :caller_path),
            mod_type: csv_row_val(row, :caller_info)
          )
        end
      end

      ChaosDetector::Stacker::Frame.new(
        event: event.to_sym,
        mod_info: mod_info,
        fn_info: fn_info,
        caller_info: caller_info
      )
    end
  end
end
