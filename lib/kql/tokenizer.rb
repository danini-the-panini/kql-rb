module KQL
  class Tokenizer
    class Error < StandardError
      def initialize(message, line, column)
        super("#{message} (#{line}:#{column})")
      end
    end

    class Token
      attr_reader :type, :value, :line, :column

      def initialize(type, value, line, column)
        @type = type
        @value = value
        @line = line
        @column = column
      end

      def ==(other  )
        return false unless other.is_a?(Token)
        return false unless type == other.type && value == other.value

        if line && other.line
          return false unless line == other.line
        end
        if column && other.column
          return false unless column == other.column
        end

        true
      end

      def to_s
        "#{value.inspect} (#{line || '?'}:#{column || '?'})"
      end
      alias inspect to_s
    end

    attr_reader :index

    SYMBOLS = {
      '(' => :LPAREN,
      ')' => :RPAREN,
      '[' => :LBRACKET,
      ']' => :RBRACKET,
      ',' => :COMMA
    }

    WHITESPACE = ["\u0009", "\u0020", "\u00A0", "\u1680",
                 "\u2000", "\u2001", "\u2002", "\u2003",
                 "\u2004", "\u2005", "\u2006", "\u2007",
                 "\u2008", "\u2009", "\u200A", "\u202F",
                 "\u205F", "\u3000", ' ']

    NEWLINES = ["\u000A", "\u0085", "\u000C", "\u2028", "\u2029"]

    NON_IDENTIFIER_CHARS = Regexp.escape "#{SYMBOLS.keys.join('')}()/\\<>[]\","
    IDENTIFIER_CHARS = /[^#{NON_IDENTIFIER_CHARS}\x0-\x20]/
    INITIAL_IDENTIFIER_CHARS = /[^#{NON_IDENTIFIER_CHARS}0-9\x0-\x20]/

    def initialize(str, start = 0)
      @str = str
      @rawstring_hashes = nil
      @context = nil
      @index = start
      @buffer = ''
      @previous_context = nil
      @line = 1
      @column = 1
    end

    def next_token
      @context = nil
      @previous_context = nil
      @line_at_start = @line
      @column_at_start = @column
      loop do
        c = @str[@index]
        n = @str[@index + 1]
        case @context
        when nil
          case c
          when '"'
            self.context = :string
            @buffer = ''
            traverse(1)
          when 'r'
            if @str[@index + 1] == '"'
              self.context = :rawstring
              traverse(2)
              @rawstring_hashes = 0
              @buffer = ''
              next
            elsif @str[@index + 1] == '#'
              i = @index + 1
              @rawstring_hashes = 0
              while @str[i] == '#'
                @rawstring_hashes += 1
                i += 1
              end
              if @str[i] == '"'
                self.context = :rawstring
                @index = i + 1
                @buffer = ''
                next
              end
            end
            self.context = :ident
            @buffer = c
            traverse(1)
          when /[0-9\-]/
            self.context = :number
            traverse(1)
            @buffer = c
          when '='
            if n == '>'
              return token(:MAP, '=>').tap { traverse(2) }
            else
              return token(:EQUALS, c).tap { traverse(1) }
            end
          when '>'
            if n == '='
              return token(:GTE, '>=').tap { traverse(2) }
            else
              return token(:GT, c).tap { traverse(1) }
            end
          when '<'
            if n == '='
              return token(:LTE, '<=').tap { traverse(2) }
            else
              return token(:LT, c).tap { traverse(1) }
            end
          when '|'
            if n == '|'
              return token(:OR, '||').tap { traverse(2) }
            else
              self.context = :ident
              @buffer = c
              traverse(1)
            end
          when '^'
            if n == '='
              return token(:STARTS_WITH, '^=').tap { traverse(2) }
            else
              self.context = :ident
              @buffer = c
              traverse(1)
            end
          when '$'
            if n == '='
              return token(:ENDS_WITH, '$=').tap { traverse(2) }
            else
              self.context = :ident
              @buffer = c
              traverse(1)
            end
          when '*'
            if n == '='
              return token(:INCLUDES, '*=').tap { traverse(2) }
            else
              self.context = :ident
              @buffer = c
              traverse(1)
            end
          when '+'
            case n
            when /[0-9]/
              self.context = :number
              traverse(1)
              @buffer = c
            when IDENTIFIER_CHARS
              self.context = :ident
              @buffer = c
              traverse(1)
            else
              return token(:PLUS, '+').tap { traverse(1) }
            end
          when '~'
            case n
            when IDENTIFIER_CHARS
              self.context = :ident
              @buffer = c
              traverse(1)
            else
              return token(:TILDE, '~').tap { traverse(1) }
            end
          when '!'
            case n
            when '='
              return token(:NOT_EQUALS, '!=').tap { traverse(2) }
            else
              self.context = :ident
              @buffer = c
              traverse(1)
            end
          when *SYMBOLS.keys
            return token(SYMBOLS[c], c).tap { traverse(1) }
          when *WHITESPACE
            traverse(1)
          when *NEWLINES
            traverse(1)
            new_line
          when INITIAL_IDENTIFIER_CHARS
            self.context = :ident
            @buffer = c
            traverse(1)
          when nil
            return [false, nil]
          else
            raise_error "Unexpected `#{c}'"
          end
        when :ident
          case c
          when IDENTIFIER_CHARS
            traverse(1)
            @buffer += c
          else
            case @buffer
            when 'true'  then return token(:TRUE, true)
            when 'false' then return token(:FALSE, false)
            when 'null'  then return token(:NULL, nil)
            when 'top', 'name', 'tag', 'props', 'values'
              if c == '(' && n == ')'
                return token(@buffer.upcase.to_sym, "#{@buffer}()").tap { traverse(2) }
              end
            when 'val'
              return token(:VAL, @buffer) if c == '('
            when 'prop'
              return token(:PROP, @buffer) if c == '('
            end
            return token(:IDENT, @buffer)
          end
        when :string
          case c
          when '\\'
            @buffer += c
            @buffer += @str[@index + 1]
            traverse(2)
          when '"'
            return token(:STRING, convert_escapes(@buffer)).tap { traverse(1) }
          when nil
            raise_error 'Unterminated string literal'
          else
            @buffer += c
            traverse(1)
          end
        when :rawstring
          raise_error "Unterminated rawstring literal" if c.nil?

          if c == '"'
            h = 0
            while @str[@index + 1 + h] == '#' && h < @rawstring_hashes
              h += 1
            end
            if h == @rawstring_hashes
              return token(:RAWSTRING, @buffer).tap { traverse(1 + h) }
            end
          end

          @buffer += c
          traverse(1)
        when :number
          case c
          when /[0-9.\-+_eE]/
            traverse(1)
            @buffer += c
          else
            return parse_number(@buffer)
          end
        end
      end
    end

    private

    def token(type, value)
      [type, Token.new(type, value, @line_at_start, @column_at_start)]
    end

    def traverse(count = 1)
      @column += count
      @index += count
    end

    def raise_error(message)
      raise Error.new(message, @line, @column)
    end

    def new_line
      @column = 1
      @line += 1
    end

    def context=(new_context)
      @previous_context = @context
      @context = new_context
    end

    def parse_number(string)
      return parse_float(string) if string =~ /[.E]/i

      token(:INTEGER, Integer(munch_underscores(string), 10))
    end

    def parse_float(string)
      string = munch_underscores(string)

      value = Float(string)
      if value.infinite? || (value.zero? && exponent.to_i < 0)
        token(:FLOAT, BigDecimal(string))
      else
        token(:FLOAT, value)
      end
    end

    def munch_underscores(string)
      string.chomp('_').squeeze('_')
    end

    def convert_escapes(string)
      string.gsub(/\\[^u]/) do |m|
        case m
        when '\n' then "\n"
        when '\r' then "\r"
        when '\t' then "\t"
        when '\\\\' then '\\'
        when '\"' then '"'
        when '\b' then "\b"
        when '\f' then "\f"
        when '\/' then '/'
        else raise_error "Unexpected escape #{m.inspect}"
        end
      end.gsub(/\\u\{[0-9a-fA-F]{0,6}\}/) do |m|
        i = Integer(m[3..-2], 16)
        if i < 0 || i > 0x10FFFF
          raise_error "Invalid code point #{u}"
        end
        i.chr(Encoding::UTF_8)
      end
    end
  end
end
