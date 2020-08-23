require 'matrix'
require_relative 'lerp_util'
module ChaosDetector
  module Utils
    module TensorUtil
      class << self
        # Return new matrix that is normalized from 0.0(min) to 1.0(max)
        def normalize_matrix(matrix)
          mag = matrix.row_size
          raise ArgumentError if matrix.column_size != mag
                    
          lo, hi = matrix.minmax
          
          Matrix.build(mag) do |row, col|
            ChaosDetector::Utils::LerpUtil.delerp(matrix[row, col], min: lo, max: hi)            
          end
        end
      end
    end
  end
end
