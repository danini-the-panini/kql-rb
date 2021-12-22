module KQL
  class Accessor
    class Val < Accessor
      attr_reader :index

      def initialize(index)
        @index = index
      end

      def execute(node)
        node.arguments[index]
      end

      def match?(node)
        node.arguments.size > index
      end

      def ==(other)
        return false unless other.is_a?(Val)

        other.index == index
      end
    end

    class Prop < Accessor
      attr_reader :name

      def initialize(name)
        @name = name
      end

      def execute(node)
        node.properties[name]
      end

      def match?(node)
        node.properties.key?(name)
      end

      def ==(other)
        return false unless other.is_a?(Prop)

        other.name == name
      end
    end

    singleton :Values, Accessor do
      def execute(node)
        node.arguments
      end

      def match?(node)
        true
      end
    end

    singleton :Props, Accessor do
      def execute(node)
        node.properties
      end

      def match?(node)
        true
      end
    end

    singleton :Name, Accessor do
      def execute(node)
        node.name
      end

      def match?(node)
        true
      end
    end

    singleton :Tag, Accessor do
      def execute(node)
        node.type
      end

      def match?(node)
        !node.type.nil?
      end
    end

    class Tuple < Accessor
      attr_reader :accessors

      def initialize(accessors)
        @accessors = accessors
      end

      def execute(node)
        accessors.map { |a| a.execute(node) }
      end
    end
  end
end
