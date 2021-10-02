module KQL
  class Accessor
    class Prop < Accessor
      attr_reader :name

      def initialize(name)
        @name = name
      end

      def ==(other)
        return false unless other.is_a?(Prop)

        other.name == name
      end
    end

    class Val < Accessor
      attr_reader :index

      def initialize(index)
        @index = index
      end

      def ==(other)
        return false unless other.is_a?(Val)

        other.index == index
      end
    end

    class Values < Accessor
    end

    class Props < Accessor
    end

    class Name < Accessor
    end

    class Tag < Accessor
    end
  end
end
