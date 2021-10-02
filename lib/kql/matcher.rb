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
  end
end
