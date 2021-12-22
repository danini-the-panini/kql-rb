module KQL
  class Matcher
    singleton :Any, Matcher do
      def match?(node)
        true
      end
    end

    singleton :AnyTag, Matcher do
      def match?(node)
        !node.type.nil?
      end
    end

    class Tag < Matcher
      attr_reader :tag
      alias value tag

      def initialize(tag)
        @tag = tag
      end

      def match?(node)
        node.type == tag
      end

      def ==(other)
        return false unless other.is_a?(Tag)

        other.tag == tag
      end

      def coerce(a)
        case a
        when ::KDL::Node, ::KDL::Value then a.type
        else a
        end
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

      def coerce(a)
        case a
        when ::KDL::Value then a.value
        else a
        end
      end
    end

    class Comparison < Matcher
      attr_reader :accessor, :operator, :value

      def initialize(accessor, operator, value)
        @accessor = accessor
        @operator = operator
        @value = value
      end

      def match?(node)
        return false unless accessor.match?(node)

        operator.execute(value.coerce(accessor.execute(node)), value.value)
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
