require_relative 'core_util'
module ChaosDetector
  module Utils
    module StrUtil
      STR_INDENT = '  '.freeze
      STR_BLANK = ''.freeze
      STR_NS_SEP = '::'.freeze
      SPACE = ' '.freeze
      SCORE = '_'.freeze

      class << self

        def decorate_pair(source, dest, indent_length: 0, clamp: :angle, join_str: ' ')
          decorate("#{decorate(source)}#{decorate(dest, prefix: join_str)}", clamp: clamp, indent_length: indent_length)
        end

        def decorate_tuple(tuple, indent_length: 0, clamp: :angle, join_str: ' ')
          body = tuple.map { |t| decorate(t, indent_length: indent_length)}.join(join_str)
          decorate(body, clamp: clamp, indent_length: indent_length)
        end

        def decorate(text, clamp: :nil, prefix: nil, suffix: nil, sep: nil, indent_length: 0)
          return '' if nay? text

          clamp_pre, clamp_post = clamp_chars(clamp: clamp)
          indent("#{prefix}#{sep}#{clamp_pre}#{text}#{clamp_post}#{sep}#{suffix}", indent_length)
        end

        def humanize_module(mod_name, max_segments: 2, sep_token: STR_NS_SEP)
          return '' if nay? mod_name
          raise ArgumentError, 'Must have at least 1 segment.' if max_segments < 1

          mod_name.split(sep_token).last(max_segments).join(sep_token)
        end

        def snakeize(obj)
          obj.to_s.gsub(/[^a-zA-Z\d\s:]/, SCORE)
        end

        def blank?(obj)
          obj.nil? || obj.to_s.empty?
        end

        def squish(str)
          str.to_s.strip.split.map(&:strip).join(SPACE)
        end

        def titleize(obj)
          obj.to_s.split(SCORE).map(&:capitalize).join(SPACE)
        end

        alias d decorate

        def clamp_chars(clamp: :none)
          case clamp
          when :angle, :arrow
            ['<', '>']
          when :brace
            ['{', '}']
          when :bracket
            ['[', ']']
          when :italic, :emphasize
            %w[_ _]
          when :strong, :bold, :stars
            ['**', '**']
          when :quotes, :double_quotes
            ['"', '"']
          when :ticks, :single_quotes
            ["'", "'"]
          when :none
            [STR_BLANK, STR_BLANK]
          else # :parens, :parentheses
            ['(', ')']
          end
        end

        def indent(text, indent_length=1)
          return '' if nay? text
          return text unless indent_length

          "#{STR_INDENT * indent_length}#{text}"
        end

        def nay?(obj)
          ChaosDetector::Utils::CoreUtil.naught?(obj)
        end
      end
    end
  end
end
