require_relative 'core_util'
module TCS
  module Utils
    module StrUtil
      STR_INDENT = '  '.freeze
      STR_BLANK = ''.freeze

      class << self

        def decorate_pair(source, dest, indent_length: 0, clamp: :angle, join_str: ' -> ')
          decorate("#{decorate(source)}#{decorate(dest, prefix: join_str)}", clamp:clamp, indent_length:indent_length)
        end

        def decorate(text, clamp: :nil, prefix: nil, suffix: nil, sep: nil, indent_length: 0)
          return STR_BLANK if nay?text

          clamp_pre, clamp_post = clamp_chars(clamp: clamp)
          indent("#{prefix}#{sep}#{clamp_pre}#{text}#{clamp_post}#{sep}#{suffix}", indent_length)
        end

        alias_method :d, :decorate

        def clamp_chars(clamp: nil)
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
          TCS::Utils::CoreUtil::naught?(obj)
        end

      end
    end
  end
end
