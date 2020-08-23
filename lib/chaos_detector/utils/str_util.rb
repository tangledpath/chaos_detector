require_relative 'core_util'
module ChaosDetector
  module Utils
    module StrUtil
      STR_INDENT = '  '.freeze
      STR_BLANK = ''.freeze
      STR_NS_SEP = '::'.freeze

      class << self

        def decorate_pair(source, dest, indent_length: 0, clamp: :angle, join_str: ' -> ')
          decorate("#{decorate(source)}#{decorate(dest, prefix: join_str)}", clamp:clamp, indent_length:indent_length)
        end

        def decorate_tuple(tuple, indent_length: 0, clamp: :angle, join_str: ' -> ')
          body = tuple.map{|t| decorate(t, indent_length: indent_length)}.join(join_str)
          decorate(body, clamp:clamp, indent_length:indent_length)
        end

        def decorate(text, clamp: :nil, prefix: nil, suffix: nil, sep: nil, indent_length: 0)
          return STR_BLANK if nay?text

          clamp_pre, clamp_post = clamp_chars(clamp: clamp)
          indent("#{prefix}#{sep}#{clamp_pre}#{text}#{clamp_post}#{sep}#{suffix}", indent_length)
        end

        def humanize_module(mod_name, max_segments:2, sep_token: STR_NS_SEP)
          return STR_BLANK if nay?mod_name
          raise ArgumentError, "Must have at least 1 segment." if max_segments < 1

          mod_name.split(sep_token).last(max_segments).join(sep_token)
        end

        alias_method :d, :decorate

        def clamp_chars(clamp: :none)
          case(clamp)
            when :angle, :arrow
              ['<', '>']
            when :brace
              ['{', '}']
            when :bracket
              ['[', ']']
            when :italic, :emphasize
              ['_', '_']
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
          return STR_BLANK if nay?text
          return text unless indent_length

          "#{STR_INDENT * indent_length}#{text}"
        end

        def nay?(obj)
          ChaosDetector::Utils::CoreUtil::naught?(obj)
        end

      end
    end
  end
end
