module KQL
  class Matcher
    class Any < Matcher
    end

    class AnyTag < Matcher
    end

    class Tag < Matcher
      attr_reader :tag

      def initialize(tag)
        @tag = tag
      end

      def ==(other)
        return false unless other.is_a?(Tag)

        other.tag == tag
      end
    end

    class Value < Matcher
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def ==(other)
        return false unless other.is_a?(Value)

        other.value == value
      end
    end

    class Comparison < Matcher
      attr_reader :accessor, :operator, :value

      def initialize(accessor, operator, value)
        @accessor = accessor
        @operator = operator
        @value = value
      end

      def ==(other)
        return false unless other.is_a?(Comparison)

        other.accessor == accessor &&
          other.operator == operator &&
          other.value == value
      end
    end
  end
end
