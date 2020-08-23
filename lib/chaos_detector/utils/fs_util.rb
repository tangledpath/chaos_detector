require 'fileutils'
require_relative 'core_util'

module ChaosDetector
  module Utils
    module FSUtil
      class << self
        # Ensure directory and all its parents exist, like (mkdir -p):
        def ensure_dirpath(dirpath)
          raise ArgumentError, "#ensure_paths_to_file requires dirpath" if nay?dirpath
          FileUtils.mkdir_p(dirpath)
        end

        # Ensure file's directory and all its parents exist, like (mkdir -p):
        def ensure_paths_to_file(filepath)
          raise ArgumentError, "#ensure_paths_to_file requires filepath" if nay?filepath

          dirpath = File.split(filepath).first
          raise "dirpath couldn't be obtained from #{filepath}" if nay?dirpath

          ensure_dirpath(dirpath)
        end

        def nay?(obj)
          ChaosDetector::Utils::CoreUtil::naught?(obj)
        end

      end
    end
  end
end